import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifemate/features/spending_limits/data/spending_limit_alert_service.dart';
import 'package:lifemate/features/spending_limits/data/spending_limit_repository.dart';
import 'package:lifemate/features/spending_limits/domain/limit_alert_policy.dart';
import 'package:lifemate/features/spending_limits/domain/spending_limit.dart';
import 'package:lifemate/features/transactions/data/transaction_repository.dart';
import 'package:lifemate/features/transactions/domain/transaction_providers.dart';

import '../../helpers/builders.dart';

/// Records alerts instead of showing device notifications.
class RecordingSink implements LimitAlertSink {
  final delivered = <LimitAlert>[];
  @override
  Future<void> deliver(LimitAlert alert) async => delivered.add(alert);
}

/// End-to-end tests of add / edit / delete → limit recalculation → alerts,
/// using an in-memory Firestore.
void main() {
  const uid = 'user-1';
  late FakeFirebaseFirestore db;
  late SpendingLimitRepository limits;
  late TransactionRepository transactions;
  late RecordingSink sink;
  late TransactionService service;

  setUp(() {
    db = FakeFirebaseFirestore();
    limits = SpendingLimitRepository(firestore: db);
    transactions = TransactionRepository(firestore: db);
    sink = RecordingSink();
    service = TransactionService(
      repository: transactions,
      alerts: SpendingLimitAlertService(
        limits: limits,
        transactions: transactions,
        sink: sink,
      ),
      currentUid: () => uid,
    );
  });

  Future<String> onlyTransactionId() async {
    final snap =
        await db.collection('users').doc(uid).collection('transactions').get();
    return snap.docs.single.id;
  }

  test('adding expenses: \$4 → no alert, +\$2 → one exceeded alert', () async {
    await limits.save(uid, dailyLimit(500), isNew: true);

    expect(await service.add(expense(400, DateTime.now())), isEmpty);

    final alerts = await service.add(expense(200, DateTime.now()));
    expect(alerts.single.level, LimitLevel.exceeded);
    expect(alerts.single.body, contains(r'$1.00'));
    expect(sink.delivered, hasLength(1));
  });

  test('no duplicate alert for the same condition', () async {
    await limits.save(uid, dailyLimit(500), isNew: true);
    await service.add(expense(600, DateTime.now()));
    await service.add(expense(100, DateTime.now())); // still exceeded
    expect(sink.delivered, hasLength(1));
  });

  test('editing an expense lower, then higher again, re-alerts', () async {
    await limits.save(uid, dailyLimit(500), isNew: true);
    await service.add(expense(600, DateTime.now()));
    final id = await onlyTransactionId();

    final tx = (await transactions.fetchExpenses(
            uid, LimitPeriod.daily.rangeAt(DateTime.now())))
        .single;
    expect(await service.update(tx.copyWith(amountMinor: 300)), isEmpty);
    expect(tx.id, id);

    final again = await service.update(tx.copyWith(amountMinor: 700));
    expect(again.single.level, LimitLevel.exceeded);
    expect(sink.delivered, hasLength(2));
  });

  test('deleting an expense recalculates and lowers stored level', () async {
    await limits.save(uid, dailyLimit(500), isNew: true);
    await service.add(expense(600, DateTime.now()));
    final id = await onlyTransactionId();

    expect(await service.delete(id), isEmpty);
    final key = LimitPeriod.daily.periodKeyAt(DateTime.now());
    expect(
      await limits.fetchLastNotifiedLevel(uid, LimitPeriod.daily, key),
      LimitLevel.ok,
    );
  });

  test('warning, then reached, then exceeded each alert once', () async {
    await limits.save(uid, dailyLimit(500, warnAt: 80), isNew: true);
    await service.add(expense(400, DateTime.now())); // 80% → warning
    await service.add(expense(100, DateTime.now())); // 100% → reached
    await service.add(expense(1, DateTime.now())); // > 100% → exceeded
    expect(sink.delivered.map((a) => a.level), [
      LimitLevel.warning,
      LimitLevel.reached,
      LimitLevel.exceeded,
    ]);
  });

  test('daily and monthly limits trigger independently', () async {
    await limits.save(uid, dailyLimit(500), isNew: true);
    await limits.save(uid, monthlyLimit(5000), isNew: true);

    final alerts = await service.add(expense(600, DateTime.now()));
    expect(alerts.map((a) => a.period), [LimitPeriod.daily]);
  });

  test('income never triggers a limit', () async {
    await limits.save(uid, dailyLimit(500), isNew: true);
    expect(await service.add(income(100000, DateTime.now())), isEmpty);
  });

  test('alerts disabled: expense still saved, no notification', () async {
    await limits.save(uid, dailyLimit(500, alerts: false), isNew: true);
    final alerts = await service.add(expense(900, DateTime.now()));
    expect(alerts, isEmpty);
    expect(sink.delivered, isEmpty);
    // Recording over the limit is never blocked.
    expect(await onlyTransactionId(), isNotEmpty);
  });

  test('expenses in another currency do not count toward a USD limit',
      () async {
    await limits.save(uid, dailyLimit(500), isNew: true);
    expect(
      await service.add(expense(50000, DateTime.now(), currency: 'KHR')),
      isEmpty,
    );
  });

  test('alert state resets for a new day (new period key)', () async {
    await limits.save(uid, dailyLimit(500), isNew: true);
    final alertService = SpendingLimitAlertService(
        limits: limits, transactions: transactions, sink: sink);

    final day1 = DateTime(2026, 10, 22, 12);
    await transactions.add(uid, expense(600, day1));
    expect(await alertService.checkLimits(uid, now: day1), hasLength(1));

    final day2 = DateTime(2026, 10, 23, 12);
    await transactions.add(uid, expense(600, day2));
    expect(await alertService.checkLimits(uid, now: day2), hasLength(1));
  });
}
