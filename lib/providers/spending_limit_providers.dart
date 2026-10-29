import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

import '../utils/app_exception.dart';
import 'clock_provider.dart';
import '../utils/date_utils.dart';
import '../services/auth_repository.dart';
import '../models/finance_transaction.dart';
import '../models/transaction_filter.dart';
import 'transaction_providers.dart';
import '../services/spending_limit_alert_service.dart';
import '../services/spending_limit_repository.dart';
import '../services/limit_alert_policy.dart';
import '../models/spending_limit.dart';
import '../services/spending_limit_calculator.dart';

/// The user's configured limits (a missing key = that limit is not set).
final spendingLimitsProvider =
    StreamProvider<Map<LimitPeriod, SpendingLimit>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const {});
  return ref.watch(spendingLimitRepositoryProvider).watchAll(uid);
});

/// Filter for this month's expenses. The month always contains today, so
/// this one query feeds both limits and "today's spending".
TransactionFilter currentMonthExpensesFilter(DateTime now) => TransactionFilter(
      range: AppDateUtils.monthOf(now),
      type: TransactionType.expense,
    );

/// Live status of each configured limit. Recalculates automatically when
/// an expense is added, edited or deleted (the Firestore stream emits),
/// when a limit changes, and at local midnight (via [clockProvider]).
final limitStatusesProvider =
    Provider<AsyncValue<Map<LimitPeriod, LimitStatus>>>((ref) {
  final now = watchNow(ref);
  final limitsAsync = ref.watch(spendingLimitsProvider);
  final expensesAsync =
      ref.watch(transactionQueryProvider(currentMonthExpensesFilter(now)));

  if (limitsAsync.hasError) {
    return AsyncValue.error(limitsAsync.error!, limitsAsync.stackTrace!);
  }
  if (expensesAsync.hasError) {
    return AsyncValue.error(expensesAsync.error!, expensesAsync.stackTrace!);
  }
  final limits = limitsAsync.value;
  final expenses = expensesAsync.value;
  if (limits == null || expenses == null) return const AsyncValue.loading();

  return AsyncValue.data({
    for (final limit in limits.values)
      limit.period: SpendingLimitCalculator.evaluate(
        limit: limit,
        transactions: expenses,
        now: now,
      ),
  });
});

/// Saving / deleting limits. After each change the limits are re-checked,
/// because lowering a limit can put the user over it immediately.
class SpendingLimitService {
  SpendingLimitService(this._ref);
  final Ref _ref;

  String _requireUid() {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) throw const AuthException('Please log in again.');
    return uid;
  }

  static void validate(SpendingLimit limit) {
    if (limit.amountMinor <= 0) {
      throw const ValidationException('Limit must be greater than zero.');
    }
    final t = limit.warningThresholdPercent;
    if (t != null && (t < 1 || t > 99)) {
      throw const ValidationException(
          'Warning threshold must be between 1% and 99%.');
    }
  }

  Future<List<LimitAlert>> save(SpendingLimit limit,
      {required bool isNew}) async {
    validate(limit);
    final uid = _requireUid();
    await _ref
        .read(spendingLimitRepositoryProvider)
        .save(uid, limit, isNew: isNew);
    return _recheck(uid);
  }

  Future<void> delete(LimitPeriod period) async {
    final uid = _requireUid();
    await _ref.read(spendingLimitRepositoryProvider).delete(uid, period);
  }

  Future<List<LimitAlert>> _recheck(String uid) async {
    try {
      return await _ref.read(spendingLimitAlertServiceProvider).checkLimits(uid);
    } catch (e) {
      Logger().w('Spending-limit check failed: $e');
      return const [];
    }
  }
}

final spendingLimitServiceProvider = Provider<SpendingLimitService>((ref) {
  return SpendingLimitService(ref);
});
