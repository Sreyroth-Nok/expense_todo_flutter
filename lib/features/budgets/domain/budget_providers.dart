import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../../transactions/domain/finance_transaction.dart';
import '../../transactions/domain/transaction_filter.dart';
import '../../transactions/domain/transaction_providers.dart';
import '../data/budget_repository.dart';
import 'budget.dart';

/// All budgets of the signed-in user.
final budgetsProvider = StreamProvider<List<Budget>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(budgetRepositoryProvider).watchAll(uid);
});

final budgetByIdProvider =
    StreamProvider.autoDispose.family<Budget?, String>((ref, id) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(budgetRepositoryProvider).watchOne(uid, id);
});

/// Live status of [budget]: listens to the expenses of the budget's range
/// only (server-side date filter), and recalculates on every change.
final budgetStatusProvider = Provider.autoDispose
    .family<AsyncValue<BudgetStatus>, Budget>((ref, budget) {
  final expenses = ref.watch(transactionQueryProvider(
    TransactionFilter(range: budget.range, type: TransactionType.expense),
  ));
  return expenses.whenData((txs) => BudgetCalculator.evaluate(budget, txs));
});
