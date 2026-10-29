import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import 'notification_service.dart';
import '../utils/money.dart';
import 'auth_repository.dart';
import 'transaction_repository.dart';
import 'limit_alert_policy.dart';
import '../models/spending_limit.dart';
import 'spending_limit_calculator.dart';
import 'spending_limit_repository.dart';

/// Anything that can deliver a limit alert to the device. The real app
/// uses [NotificationService]; tests use a fake that records calls.
abstract interface class LimitAlertSink {
  Future<void> deliver(LimitAlert alert);
}

class DeviceLimitAlertSink implements LimitAlertSink {
  DeviceLimitAlertSink(this._notifications, {required this.enabled});
  final NotificationService _notifications;

  /// Reads the user's "Spending limits" notification setting. When off, no
  /// device notification is shown (the in-app message still appears).
  final bool Function() enabled;

  @override
  Future<void> deliver(LimitAlert alert) async {
    if (!enabled()) return;
    await _notifications.showLimitAlert(
        // Stable id per period: a new alert replaces the previous one.
        id: alert.period == LimitPeriod.daily ? 1001 : 1002,
        title: alert.title,
        body: alert.body,
      );
  }
}

/// Re-checks both spending limits and sends alerts when needed.
///
/// Called after every add / edit / delete of a transaction and after a
/// limit is changed. Reads fresh data from Firestore, so the result is
/// always based on the latest saved expenses.
///
/// ⚠️  LIMITATION: the check runs in the app, right after the user's own
/// change. Expenses written from another device are checked the next time
/// this device saves something. A Cloud Function trigger on
/// transactions/{id} would make this fully server-side (planned for
/// Phase 6 hardening); the de-dupe document format already supports it.
class SpendingLimitAlertService {
  SpendingLimitAlertService({
    required SpendingLimitRepository limits,
    required TransactionRepository transactions,
    required LimitAlertSink sink,
  })  : _limits = limits,
        _transactions = transactions,
        _sink = sink;

  final SpendingLimitRepository _limits;
  final TransactionRepository _transactions;
  final LimitAlertSink _sink;
  final _log = Logger();

  /// Returns the alerts that fired (the UI also shows them in-app).
  Future<List<LimitAlert>> checkLimits(String uid, {DateTime? now}) async {
    final at = now ?? DateTime.now();
    final configured = await _limits.fetchAll(uid);
    if (configured.isEmpty) return const [];

    // The month always contains today, so one query serves both limits.
    final monthRange = LimitPeriod.monthly.rangeAt(at);
    final expenses = await _transactions.fetchExpenses(uid, monthRange);

    final fired = <LimitAlert>[];
    for (final limit in configured.values) {
      final status = SpendingLimitCalculator.evaluate(
        limit: limit,
        transactions: expenses,
        now: at,
      );
      final periodKey = limit.period.periodKeyAt(at);
      final last =
          await _limits.fetchLastNotifiedLevel(uid, limit.period, periodKey);

      final decision = LimitAlertPolicy.decide(
        current: status.level,
        lastNotified: last,
        alertsEnabled: limit.alertsEnabled,
      );

      if (decision.levelToStore != (last ?? LimitLevel.ok)) {
        await _limits.saveLastNotifiedLevel(
            uid, limit.period, periodKey, decision.levelToStore);
      }

      if (decision.notify) {
        final alert = buildAlert(status);
        fired.add(alert);
        try {
          await _sink.deliver(alert);
        } catch (e) {
          _log.w('Limit alert delivery failed: $e');
        }
      }
    }
    return fired;
  }

  /// Human-readable alert text for a status.
  static LimitAlert buildAlert(LimitStatus status) {
    final limit = status.limit;
    final name = limit.period == LimitPeriod.daily ? 'daily' : 'monthly';
    final spent = Money.format(status.spentMinor, limit.currency);
    final total = Money.format(limit.amountMinor, limit.currency);

    final (title, body) = switch (status.level) {
      LimitLevel.exceeded => (
          'You went over your $name limit',
          'Spent $spent of $total — over by '
              '${Money.format(status.exceededByMinor, limit.currency)}.',
        ),
      LimitLevel.reached => (
          'You reached your $name limit',
          'Spent $spent of $total. Nothing left for this period.',
        ),
      LimitLevel.warning => (
          'Close to your $name limit',
          'Spent $spent of $total (${limit.warningThresholdPercent}% warning). '
              '${Money.format(status.remainingMinor, limit.currency)} left.',
        ),
      LimitLevel.ok => ('Spending on track', 'Spent $spent of $total.'),
    };
    return LimitAlert(
      period: limit.period,
      level: status.level,
      title: title,
      body: body,
    );
  }
}

final spendingLimitAlertServiceProvider =
    Provider<SpendingLimitAlertService>((ref) {
  return SpendingLimitAlertService(
    limits: ref.watch(spendingLimitRepositoryProvider),
    transactions: ref.watch(transactionRepositoryProvider),
    sink: DeviceLimitAlertSink(
      ref.watch(notificationServiceProvider),
      enabled: () =>
          ref
              .read(currentUserProfileProvider)
              .value
              ?.notificationPreferences
              .spendingLimits ??
          true,
    ),
  );
});
