import 'package:flutter_test/flutter_test.dart';
import 'package:lifemate/models/finance_summary.dart';
import 'package:lifemate/models/finance_transaction.dart';
import 'package:lifemate/models/transaction_filter.dart';
import 'package:lifemate/utils/date_utils.dart';

import '../../helpers/builders.dart';

void main() {
  final d = DateTime(2026, 10, 23, 12);

  group('FinanceSummary', () {
    test('sums income, expenses and net exactly', () {
      final s = FinanceSummary.fromTransactions([
        income(100000, d),
        expense(450, d),
        expense(1050, d),
      ]);
      final usd = s.byCurrency['USD']!;
      expect(usd.incomeMinor, 100000);
      expect(usd.expenseMinor, 1500);
      expect(usd.netMinor, 98500);
    });

    test('never combines different currencies', () {
      final s = FinanceSummary.fromTransactions([
        expense(500, d),
        expense(20000, d, currency: 'KHR'),
      ]);
      expect(s.byCurrency.keys, containsAll(['USD', 'KHR']));
      expect(s.byCurrency['USD']!.expenseMinor, 500);
      expect(s.byCurrency['KHR']!.expenseMinor, 20000);
    });

    test('puts the preferred currency first', () {
      final s = FinanceSummary.fromTransactions(
        [expense(1, d), expense(1, d, currency: 'KHR')],
        preferredCurrency: 'KHR',
      );
      expect(s.byCurrency.keys.first, 'KHR');
    });

    test('empty input gives an empty summary', () {
      expect(FinanceSummary.fromTransactions(const []).isEmpty, isTrue);
    });
  });

  group('TransactionFilter.matches', () {
    final lunch = expense(450, d).copyWith(description: 'Lunch with Sok');

    test('search matches description and category, case-insensitive', () {
      expect(const TransactionFilter(search: 'sok').matches(lunch), isTrue);
      expect(const TransactionFilter(search: 'FOOD').matches(lunch), isTrue);
      expect(const TransactionFilter(search: 'taxi').matches(lunch), isFalse);
    });

    test('type, category and date range filters', () {
      expect(const TransactionFilter(type: TransactionType.income).matches(lunch),
          isFalse);
      expect(const TransactionFilter(categoryId: 'food').matches(lunch), isTrue);
      expect(const TransactionFilter(categoryId: 'bills').matches(lunch), isFalse);
      expect(
        TransactionFilter(range: AppDateUtils.dayOf(DateTime(2026, 10, 24)))
            .matches(lunch),
        isFalse,
      );
    });

    test('equal filters are equal (needed for Riverpod family keys)', () {
      final a = TransactionFilter(range: AppDateUtils.monthOf(d));
      final b = TransactionFilter(range: AppDateUtils.monthOf(d));
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
  });
}
