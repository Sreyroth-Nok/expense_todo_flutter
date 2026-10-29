import 'package:flutter_test/flutter_test.dart';
import 'package:lifemate/models/budget.dart';
import 'package:lifemate/models/spending_limit.dart';
import 'package:lifemate/models/finance_transaction.dart';

import '../../helpers/builders.dart';

FinanceTransaction cat(FinanceTransaction t, String categoryId, [String id = '']) =>
    FinanceTransaction(
      id: id,
      type: t.type,
      amountMinor: t.amountMinor,
      currency: t.currency,
      categoryId: categoryId,
      categoryName: categoryId,
      date: t.date,
    );

void main() {
  final october = Budget(
    id: 'b1',
    name: 'October',
    startDate: DateTime(2026, 10, 1),
    endDate: DateTime(2026, 10, 31),
    currency: 'USD',
    totalMinor: 50000,
    allocations: const {'food': 20000, 'transport': 5000},
    warningThresholdPercent: 80,
  );

  test('range includes the whole last day', () {
    expect(october.range.contains(DateTime(2026, 10, 31, 23, 59)), isTrue);
    expect(october.range.contains(DateTime(2026, 11, 1)), isFalse);
  });

  test('counts only expenses in the budget currency and period', () {
    final s = BudgetCalculator.evaluate(october, [
      cat(expense(1000, DateTime(2026, 10, 3)), 'food'),
      cat(income(99999, DateTime(2026, 10, 3)), 'salary'),
      cat(expense(5000, DateTime(2026, 9, 30, 23, 59)), 'food'), // before
      cat(expense(7000, DateTime(2026, 11, 1)), 'food'), // after
      cat(expense(40000, DateTime(2026, 10, 3), currency: 'KHR'), 'food'),
    ]);
    expect(s.spentMinor, 1000);
    expect(s.otherCurrencyExpenseCount, 1);
    expect(s.remainingMinor, 49000);
  });

  test('never counts the same expense twice', () {
    final tx = cat(expense(1500, DateTime(2026, 10, 10)), 'food', 'tx-1');
    final s = BudgetCalculator.evaluate(october, [tx, tx]);
    expect(s.spentMinor, 1500);
  });

  test('per-category allocation progress and unallocated spending', () {
    final s = BudgetCalculator.evaluate(october, [
      cat(expense(16000, DateTime(2026, 10, 2)), 'food', 'a'), // 80% of food
      cat(expense(6000, DateTime(2026, 10, 2)), 'transport', 'b'), // over
      cat(expense(3000, DateTime(2026, 10, 2)), 'shopping', 'c'), // no allocation
    ]);
    final food = s.allocationStatuses.firstWhere((a) => a.categoryId == 'food');
    final transport =
        s.allocationStatuses.firstWhere((a) => a.categoryId == 'transport');
    expect(food.level, LimitLevel.warning);
    expect(transport.level, LimitLevel.exceeded);
    expect(transport.remainingMinor, -1000);
    expect(s.unallocatedSpentMinor, 3000);
    expect(s.spentMinor, 25000);
    expect(s.level, LimitLevel.ok); // 50% of the total
  });

  test('total threshold warning, reached and exceeded', () {
    Budget simple(int total) => Budget(
          name: 'x',
          startDate: DateTime(2026, 10, 1),
          endDate: DateTime(2026, 10, 31),
          currency: 'USD',
          totalMinor: total,
        );
    final txs = [cat(expense(4000, DateTime(2026, 10, 5)), 'food', 'a')];
    expect(BudgetCalculator.evaluate(simple(5000), txs).level, LimitLevel.warning);
    expect(BudgetCalculator.evaluate(simple(4000), txs).level, LimitLevel.reached);
    expect(BudgetCalculator.evaluate(simple(3999), txs).level, LimitLevel.exceeded);
  });

  group('validation', () {
    Budget make({
      DateTime? start,
      DateTime? end,
      int total = 1000,
      Map<String, int> allocations = const {},
      String name = 'B',
    }) =>
        Budget(
          name: name,
          startDate: start ?? DateTime(2026, 10, 1),
          endDate: end ?? DateTime(2026, 10, 31),
          currency: 'USD',
          totalMinor: total,
          allocations: allocations,
        );

    test('valid budget passes', () => expect(make().validate(), isNull));
    test('end before start fails', () {
      expect(make(end: DateTime(2026, 9, 30)).validate(), isNotNull);
    });
    test('same start and end day is allowed (one-day budget)', () {
      expect(make(end: DateTime(2026, 10, 1)).validate(), isNull);
    });
    test('allocations above the total fail', () {
      expect(make(allocations: {'a': 600, 'b': 500}).validate(),
          contains('more than the total'));
    });
    test('zero total, empty name and > 1 year fail', () {
      expect(make(total: 0).validate(), isNotNull);
      expect(make(name: ' ').validate(), isNotNull);
      expect(make(end: DateTime(2028, 1, 1)).validate(), isNotNull);
    });
  });

  test('value equality (needed for Riverpod family keys)', () {
    final copy = Budget(
      id: 'b1',
      name: 'October',
      startDate: DateTime(2026, 10, 1),
      endDate: DateTime(2026, 10, 31),
      currency: 'USD',
      totalMinor: 50000,
      allocations: const {'transport': 5000, 'food': 20000},
      warningThresholdPercent: 80,
    );
    expect(copy, october);
    expect(copy.hashCode, october.hashCode);
  });
}
