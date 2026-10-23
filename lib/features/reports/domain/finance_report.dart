import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money.dart';
import '../../transactions/domain/finance_summary.dart';
import '../../transactions/domain/finance_transaction.dart';

/// Expense total for one category in one currency.
class CategoryTotal {
  const CategoryTotal({
    required this.categoryId,
    required this.categoryName,
    required this.amountMinor,
    required this.count,
  });

  final String categoryId;
  final String categoryName;
  final int amountMinor;
  final int count;
}

/// Expense total for one day or month.
class PeriodTotal {
  const PeriodTotal(this.start, this.amountMinor);
  final DateTime start;
  final int amountMinor;
}

/// Everything shown on the Reports screen for a date range.
///
/// Built in memory from the range's transactions. Firestore aggregation
/// queries cannot group by currency, category and day, and a personal
/// account's transactions for a chosen range are small enough to download
/// (the query is always limited to the range, never the full history).
class FinanceReport {
  const FinanceReport({
    required this.range,
    required this.transactions,
    required this.summary,
    required this.expensesByCategory,
    required this.dailyExpenses,
    required this.monthlyExpenses,
  });

  final DateRange range;

  /// The range's transactions, newest first.
  final List<FinanceTransaction> transactions;
  final FinanceSummary summary;

  /// currency → categories sorted by amount (largest first).
  final Map<String, List<CategoryTotal>> expensesByCategory;

  /// currency → one entry per day of the range (zeros included). Empty when
  /// the range is longer than [maxDailyDays].
  final Map<String, List<PeriodTotal>> dailyExpenses;

  /// currency → one entry per calendar month touched by the range.
  final Map<String, List<PeriodTotal>> monthlyExpenses;

  static const int maxDailyDays = 62;

  bool get isEmpty => transactions.isEmpty;

  factory FinanceReport.build(
    DateRange range,
    Iterable<FinanceTransaction> all, {
    String? preferredCurrency,
  }) {
    final txs = all.where((t) => range.contains(t.date)).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final expenses = txs.where((t) => t.isExpense);

    // ── By category ─────────────────────────────────────────────
    final catAmounts = <String, Map<String, int>>{};
    final catCounts = <String, Map<String, int>>{};
    final catNames = <String, String>{};
    for (final t in expenses) {
      catAmounts.putIfAbsent(t.currency, () => {});
      catCounts.putIfAbsent(t.currency, () => {});
      catAmounts[t.currency]![t.categoryId] =
          (catAmounts[t.currency]![t.categoryId] ?? 0) + t.amountMinor;
      catCounts[t.currency]![t.categoryId] =
          (catCounts[t.currency]![t.categoryId] ?? 0) + 1;
      catNames[t.categoryId] = t.categoryName;
    }
    final byCategory = {
      for (final currency in catAmounts.keys)
        currency: [
          for (final e in catAmounts[currency]!.entries)
            CategoryTotal(
              categoryId: e.key,
              categoryName: catNames[e.key] ?? 'Uncategorized',
              amountMinor: e.value,
              count: catCounts[currency]![e.key]!,
            ),
        ]..sort((a, b) => b.amountMinor.compareTo(a.amountMinor)),
    };

    // ── Daily / monthly ─────────────────────────────────────────
    final currencies = catAmounts.keys.toList();
    // Rounded so a daylight-saving day (23 or 25 hours) still counts as one.
    final dayCount = (range.end.difference(range.start).inHours / 24).round();
    final daily = <String, List<PeriodTotal>>{};
    final monthly = <String, List<PeriodTotal>>{};

    for (final currency in currencies) {
      final inCurrency = expenses.where((t) => t.currency == currency).toList();

      if (dayCount <= maxDailyDays) {
        final perDay = <String, int>{};
        for (final t in inCurrency) {
          final k = AppDateUtils.dayKey(t.date);
          perDay[k] = (perDay[k] ?? 0) + t.amountMinor;
        }
        final days = <PeriodTotal>[];
        var d = range.start;
        var i = 0;
        while (d.isBefore(range.end)) {
          days.add(PeriodTotal(d, perDay[AppDateUtils.dayKey(d)] ?? 0));
          i++;
          d = DateTime(range.start.year, range.start.month, range.start.day + i);
        }
        daily[currency] = days;
      }

      final perMonth = <String, int>{};
      for (final t in inCurrency) {
        final k = AppDateUtils.monthKey(t.date);
        perMonth[k] = (perMonth[k] ?? 0) + t.amountMinor;
      }
      final months = <PeriodTotal>[];
      var m = DateTime(range.start.year, range.start.month);
      while (m.isBefore(range.end)) {
        months.add(PeriodTotal(m, perMonth[AppDateUtils.monthKey(m)] ?? 0));
        m = DateTime(m.year, m.month + 1);
      }
      monthly[currency] = months;
    }

    return FinanceReport(
      range: range,
      transactions: txs,
      summary:
          FinanceSummary.fromTransactions(txs, preferredCurrency: preferredCurrency),
      expensesByCategory: byCategory,
      dailyExpenses: daily,
      monthlyExpenses: monthly,
    );
  }
}

/// Converts transactions to CSV (RFC 4180 quoting).
abstract final class ReportCsv {
  static const header = [
    'Date',
    'Time',
    'Type',
    'Category',
    'Description',
    'Amount',
    'Currency',
  ];

  /// Amounts are exported as plain decimal text (e.g. 4.50) from integer
  /// minor units, so spreadsheets get exact values. Expenses are negative.
  /// Starts with a UTF-8 BOM so Excel shows Khmer text correctly.
  static String build(Iterable<FinanceTransaction> transactions) {
    final buffer = StringBuffer('﻿');
    buffer.writeln(header.map(_escape).join(','));
    for (final t in transactions) {
      final amount = Money.toInputText(t.amountMinor, t.currency);
      buffer.writeln([
        AppDateUtils.dayKey(t.date),
        _hhmm(t.date),
        t.type.label,
        t.categoryName,
        t.description,
        t.isExpense ? '-$amount' : amount,
        t.currency,
      ].map(_escape).join(','));
    }
    return buffer.toString();
  }

  static String _hhmm(DateTime d) {
    final l = d.toLocal();
    return '${l.hour.toString().padLeft(2, '0')}:${l.minute.toString().padLeft(2, '0')}';
  }

  static String _escape(String value) {
    // Also neutralise spreadsheet formulas (CSV injection): =, +, -, @ at
    // the start of a TEXT cell are prefixed with an apostrophe. Numbers
    // like "-4.50" are left alone.
    var v = value;
    final isNumber = RegExp(r'^-?\d+(\.\d+)?$').hasMatch(v);
    if (!isNumber && v.isNotEmpty && '=+-@'.contains(v[0])) v = "'$v";
    if (v.contains(RegExp(r'[",\n\r]'))) {
      return '"${v.replaceAll('"', '""')}"';
    }
    return v;
  }
}
