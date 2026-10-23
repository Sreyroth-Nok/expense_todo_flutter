import 'finance_transaction.dart';

/// Income / expense totals for ONE currency.
class CurrencyTotals {
  const CurrencyTotals({
    required this.currency,
    this.incomeMinor = 0,
    this.expenseMinor = 0,
  });

  final String currency;
  final int incomeMinor;
  final int expenseMinor;

  int get netMinor => incomeMinor - expenseMinor;

  CurrencyTotals add(FinanceTransaction tx) => CurrencyTotals(
        currency: currency,
        incomeMinor: incomeMinor + (tx.isIncome ? tx.amountMinor : 0),
        expenseMinor: expenseMinor + (tx.isExpense ? tx.amountMinor : 0),
      );
}

/// Totals grouped by currency.
///
/// Different currencies are NEVER added together: LifeMate has no
/// exchange-rate feature, so each currency gets its own [CurrencyTotals].
///
/// Totals are calculated on the fly from transactions instead of being
/// stored in Firestore. This avoids extra writes and can never drift out
/// of sync when a transaction is edited or deleted.
class FinanceSummary {
  const FinanceSummary(this.byCurrency);

  /// Currency code → totals, ordered with [preferredCurrency] first.
  final Map<String, CurrencyTotals> byCurrency;

  bool get isEmpty => byCurrency.isEmpty;

  factory FinanceSummary.fromTransactions(
    Iterable<FinanceTransaction> transactions, {
    String? preferredCurrency,
  }) {
    final totals = <String, CurrencyTotals>{};
    for (final tx in transactions) {
      final current =
          totals[tx.currency] ?? CurrencyTotals(currency: tx.currency);
      totals[tx.currency] = current.add(tx);
    }

    final codes = totals.keys.toList()
      ..sort((a, b) {
        if (a == preferredCurrency) return -1;
        if (b == preferredCurrency) return 1;
        return a.compareTo(b);
      });
    return FinanceSummary({for (final c in codes) c: totals[c]!});
  }
}
