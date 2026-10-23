import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/clock_provider.dart';
import '../../../core/utils/date_utils.dart';
import '../../auth/data/auth_repository.dart';
import '../../spending_limits/domain/spending_limit_providers.dart';
import '../../transactions/domain/finance_summary.dart';
import '../../transactions/domain/finance_transaction.dart';
import '../../transactions/domain/transaction_filter.dart';
import '../../transactions/domain/transaction_providers.dart';

/// The month shown in the dashboard summary (defaults to this month).
class SelectedMonthNotifier extends Notifier<DateRange> {
  @override
  DateRange build() => AppDateUtils.monthOf(DateTime.now());

  void previous() => state = AppDateUtils.shiftMonth(state, -1);
  void next() => state = AppDateUtils.shiftMonth(state, 1);
  void reset() => state = AppDateUtils.monthOf(DateTime.now());
}

final selectedMonthProvider =
    NotifierProvider<SelectedMonthNotifier, DateRange>(
  SelectedMonthNotifier.new,
);

/// Everything the Home dashboard displays.
class DashboardData {
  const DashboardData({
    required this.month,
    required this.summary,
    required this.todaySpending,
    required this.recent,
  });

  final DateRange month;

  /// Income / expenses / net for [month], per currency.
  final FinanceSummary summary;

  /// Today's expenses, per currency (income excluded).
  final FinanceSummary todaySpending;

  /// Latest transactions of [month] (max 5).
  final List<FinanceTransaction> recent;

  bool get hasAnyData => !summary.isEmpty || !todaySpending.isEmpty;
}

/// Combines the selected-month stream and today's expenses. Derived from
/// live Firestore streams, so it refreshes after any transaction change.
final dashboardProvider = Provider<AsyncValue<DashboardData>>((ref) {
  final now = watchNow(ref);
  final month = ref.watch(selectedMonthProvider);
  final preferred = ref.watch(currentUserProfileProvider).value?.currency;

  final monthAsync =
      ref.watch(transactionQueryProvider(TransactionFilter(range: month)));
  final currentExpensesAsync =
      ref.watch(transactionQueryProvider(currentMonthExpensesFilter(now)));

  if (monthAsync.hasError) {
    return AsyncValue.error(monthAsync.error!, monthAsync.stackTrace!);
  }
  if (currentExpensesAsync.hasError) {
    return AsyncValue.error(
        currentExpensesAsync.error!, currentExpensesAsync.stackTrace!);
  }
  final monthTx = monthAsync.value;
  final currentExpenses = currentExpensesAsync.value;
  if (monthTx == null || currentExpenses == null) {
    return const AsyncValue.loading();
  }

  final today = AppDateUtils.dayOf(now);
  return AsyncValue.data(DashboardData(
    month: month,
    summary:
        FinanceSummary.fromTransactions(monthTx, preferredCurrency: preferred),
    todaySpending: FinanceSummary.fromTransactions(
      currentExpenses.where((tx) => today.contains(tx.date)),
      preferredCurrency: preferred,
    ),
    recent: monthTx.take(5).toList(),
  ));
});
