import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'clock_provider.dart';
import '../utils/date_utils.dart';
import '../services/auth_repository.dart';
import 'spending_limit_providers.dart';
import '../models/finance_summary.dart';
import '../models/finance_transaction.dart';
import '../models/transaction_filter.dart';
import 'transaction_providers.dart';

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

  final FinanceSummary summary;

  /// Today's expenses, per currency (income excluded).
  final FinanceSummary todaySpending;

  /// Latest transactions of [month] (max 5).
  final List<FinanceTransaction> recent;

  bool get hasAnyData => !summary.isEmpty || !todaySpending.isEmpty;
}

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
