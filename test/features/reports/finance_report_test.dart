import 'package:flutter_test/flutter_test.dart';
import 'package:lifemate/utils/date_utils.dart';
import 'package:lifemate/models/finance_report.dart';
import 'package:lifemate/models/finance_transaction.dart';

import '../../helpers/builders.dart';

FinanceTransaction tx(int minor, DateTime d,
        {String category = 'food',
        String currency = 'USD',
        bool isIncome = false,
        String description = ''}) =>
    FinanceTransaction(
      type: isIncome ? TransactionType.income : TransactionType.expense,
      amountMinor: minor,
      currency: currency,
      categoryId: category,
      categoryName: category,
      description: description,
      date: d,
    );

void main() {
  final october = AppDateUtils.monthOf(DateTime(2026, 10, 15));

  group('FinanceReport.build', () {
    final report = FinanceReport.build(october, [
      tx(1000, DateTime(2026, 10, 1, 8)),
      tx(500, DateTime(2026, 10, 1, 20), category: 'transport'),
      tx(2500, DateTime(2026, 10, 20), category: 'transport'),
      tx(90000, DateTime(2026, 10, 25), isIncome: true, category: 'salary'),
      tx(30000, DateTime(2026, 10, 2), currency: 'KHR'),
      tx(7777, DateTime(2026, 11, 1)), // outside the range
    ]);

    test('summary is per currency and respects the range', () {
      expect(report.transactions, hasLength(5));
      expect(report.summary.byCurrency['USD']!.expenseMinor, 4000);
      expect(report.summary.byCurrency['USD']!.incomeMinor, 90000);
      expect(report.summary.byCurrency['KHR']!.expenseMinor, 30000);
    });

    test('spending by category is sorted, per currency, expenses only', () {
      final usd = report.expensesByCategory['USD']!;
      expect(usd.map((c) => c.categoryId), ['transport', 'food']);
      expect(usd.first.amountMinor, 3000);
      expect(usd.first.count, 2);
      expect(report.expensesByCategory['USD']!.any((c) => c.categoryId == 'salary'),
          isFalse);
    });

    test('daily totals include zero days', () {
      final days = report.dailyExpenses['USD']!;
      expect(days, hasLength(31));
      expect(days[0].amountMinor, 1500); // Oct 1
      expect(days[1].amountMinor, 0); // Oct 2 (KHR not mixed in)
      expect(days[19].amountMinor, 2500); // Oct 20
    });

    test('monthly totals', () {
      expect(report.monthlyExpenses['USD']!.single.amountMinor, 4000);
    });

    test('long ranges skip the daily view but keep months', () {
      final year = FinanceReport.build(
        DateRange(DateTime(2026), DateTime(2027)),
        [expense(100, DateTime(2026, 3, 3)), expense(200, DateTime(2026, 7, 7))],
      );
      expect(year.dailyExpenses, isEmpty);
      expect(year.monthlyExpenses['USD'], hasLength(12));
      expect(year.monthlyExpenses['USD']![2].amountMinor, 100);
    });

    test('empty range gives an empty report', () {
      expect(FinanceReport.build(october, const []).isEmpty, isTrue);
    });
  });

  group('ReportCsv', () {
    test('header, BOM, exact amounts and signs', () {
      final csv = ReportCsv.build([
        tx(450, DateTime(2026, 10, 3, 9, 5), description: 'Lunch'),
        tx(12000, DateTime(2026, 10, 3), currency: 'KHR', isIncome: true),
      ]);
      final lines = csv.trim().split('\n').map((l) => l.trim()).toList();
      expect(csv.startsWith('﻿'), isTrue);
      expect(lines[0].replaceAll('﻿', ''),
          'Date,Time,Type,Category,Description,Amount,Currency');
      expect(lines[1], '2026-10-03,09:05,Expense,food,Lunch,-4.50,USD');
      expect(lines[2], '2026-10-03,00:00,Income,food,,12000,KHR');
    });

    test('quotes commas, quotes and new lines', () {
      final csv = ReportCsv.build(
          [tx(100, DateTime(2026, 10, 3), description: 'Rice, "jasmine"\nbag')]);
      expect(csv, contains('"Rice, ""jasmine""\nbag"'));
    });

    test('neutralises spreadsheet formulas in text cells', () {
      final csv = ReportCsv.build(
          [tx(100, DateTime(2026, 10, 3), description: '=HYPERLINK("x")')]);
      expect(csv, contains("'=HYPERLINK"));
      expect(csv, contains(',-1.00,')); // numbers are untouched
    });
  });
}
