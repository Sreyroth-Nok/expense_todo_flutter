import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show mapEquals;

import '../utils/date_utils.dart';
import 'spending_limit.dart';
import '../services/spending_limit_calculator.dart';
import 'finance_transaction.dart';

/// A spending plan for a date range, optionally split by category.
///
/// Firestore path: users/{userId}/budgets/{budgetId}
///
/// Fields:
///   name                     – 1–40 chars
///   startDate                – Timestamp, local midnight of the first day
///   endDate                  – Timestamp, local midnight of the LAST day
///                              (inclusive; the range ends the next midnight)
///   currency                 – only expenses in this currency count
///   totalAmountMinorUnits    – int > 0
///   allocations              – map { categoryId: amountMinorUnits }
///   warningThresholdPercent  – null or 1–99
///   createdAt / updatedAt    – server timestamps
///
/// DESIGN NOTE: allocations live in a map inside the budget document
/// instead of a sub-collection. A budget has at most a few dozen
/// allocations, they are always read together with the budget, and one
/// document means a budget is saved atomically in a single write.
class Budget {
  const Budget({
    this.id = '',
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.currency,
    required this.totalMinor,
    this.allocations = const {},
    this.warningThresholdPercent = 80,
  });

  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final String currency;
  final int totalMinor;
  final Map<String, int> allocations;
  final int? warningThresholdPercent;

  /// Half-open range [first day 00:00, day after last day 00:00).
  DateRange get range => DateRange(
        DateTime(startDate.year, startDate.month, startDate.day),
        DateTime(endDate.year, endDate.month, endDate.day + 1),
      );

  int get allocatedMinor => allocations.values.fold(0, (a, b) => a + b);

  bool isActiveAt(DateTime now) => range.contains(now);
  bool isUpcomingAt(DateTime now) => now.isBefore(range.start);
  bool isPastAt(DateTime now) => !now.isBefore(range.end);

  factory Budget.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final rawAllocations = data['allocations'] as Map<String, dynamic>? ?? {};
    return Budget(
      id: doc.id,
      name: data['name'] as String? ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      currency: data['currency'] as String? ?? 'USD',
      totalMinor: (data['totalAmountMinorUnits'] as num?)?.toInt() ?? 0,
      allocations: {
        for (final e in rawAllocations.entries)
          e.key: (e.value as num).toInt(),
      },
      warningThresholdPercent:
          (data['warningThresholdPercent'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'startDate': Timestamp.fromDate(range.start),
        'endDate': Timestamp.fromDate(
            DateTime(endDate.year, endDate.month, endDate.day)),
        'currency': currency,
        'totalAmountMinorUnits': totalMinor,
        'allocations': allocations,
        'warningThresholdPercent': warningThresholdPercent,
      };

  /// Value equality: a Budget is used as a Riverpod family key, so two
  /// identical budgets must be equal or a new Firestore listener would be
  /// opened on every rebuild.
  @override
  bool operator ==(Object other) =>
      other is Budget &&
      other.id == id &&
      other.name == name &&
      other.startDate == startDate &&
      other.endDate == endDate &&
      other.currency == currency &&
      other.totalMinor == totalMinor &&
      other.warningThresholdPercent == warningThresholdPercent &&
      mapEquals(other.allocations, allocations);

  @override
  int get hashCode => Object.hash(
        id,
        name,
        startDate,
        endDate,
        currency,
        totalMinor,
        warningThresholdPercent,
        Object.hashAllUnordered(
            allocations.entries.map((e) => Object.hash(e.key, e.value))),
      );

  /// Returns a readable problem, or null when the budget is valid.
  String? validate() {
    if (name.trim().isEmpty || name.trim().length > 40) {
      return 'Name must be 1–40 characters.';
    }
    if (range.end.isBefore(range.start) ||
        DateTime(endDate.year, endDate.month, endDate.day)
            .isBefore(range.start)) {
      return 'The end date must be on or after the start date.';
    }
    if (range.end.difference(range.start).inDays > 367) {
      return 'A budget can cover at most one year.';
    }
    if (totalMinor <= 0) return 'Total amount must be greater than zero.';
    if (allocations.values.any((v) => v <= 0)) {
      return 'Each category amount must be greater than zero.';
    }
    if (allocatedMinor > totalMinor) {
      return 'Category amounts add up to more than the total budget.';
    }
    if (allocations.length > 50) return 'Too many category allocations.';
    final t = warningThresholdPercent;
    if (t != null && (t < 1 || t > 99)) {
      return 'Warning threshold must be between 1% and 99%.';
    }
    return null;
  }
}

/// Spending against one category allocation.
class AllocationStatus {
  const AllocationStatus({
    required this.categoryId,
    required this.allocatedMinor,
    required this.spentMinor,
    required this.level,
  });

  final String categoryId;
  final int allocatedMinor;
  final int spentMinor;
  final LimitLevel level;

  int get remainingMinor => allocatedMinor - spentMinor;
  double get progress => allocatedMinor == 0 ? 0 : spentMinor / allocatedMinor;
}

/// The calculated state of a budget.
class BudgetStatus {
  const BudgetStatus({
    required this.budget,
    required this.spentMinor,
    required this.level,
    required this.allocationStatuses,
    required this.unallocatedSpentMinor,
    required this.spentByCategory,
    this.otherCurrencyExpenseCount = 0,
  });

  final Budget budget;
  final int spentMinor;
  final LimitLevel level;
  final List<AllocationStatus> allocationStatuses;

  /// Spending in categories that have no allocation.
  final int unallocatedSpentMinor;
  final Map<String, int> spentByCategory;
  final int otherCurrencyExpenseCount;

  int get remainingMinor => budget.totalMinor - spentMinor;
  double get progress =>
      budget.totalMinor == 0 ? 0 : spentMinor / budget.totalMinor;
}

/// Pure budget maths.
abstract final class BudgetCalculator {
  /// Counts every eligible expense exactly once:
  ///   • expenses only (income ignored)
  ///   • same currency as the budget
  ///   • date inside the budget range
  ///   • duplicate transaction ids are ignored, so merging lists from two
  ///     sources can never double-count an expense.
  static BudgetStatus evaluate(
    Budget budget,
    Iterable<FinanceTransaction> transactions,
  ) {
    final range = budget.range;
    final seenIds = <String>{};
    final byCategory = <String, int>{};
    var spent = 0;
    var otherCurrency = 0;

    for (final tx in transactions) {
      if (!tx.isExpense || !range.contains(tx.date)) continue;
      if (tx.id.isNotEmpty && !seenIds.add(tx.id)) continue;
      if (tx.currency != budget.currency) {
        otherCurrency++;
        continue;
      }
      spent += tx.amountMinor;
      byCategory[tx.categoryId] = (byCategory[tx.categoryId] ?? 0) + tx.amountMinor;
    }

    final allocationStatuses = [
      for (final entry in budget.allocations.entries)
        AllocationStatus(
          categoryId: entry.key,
          allocatedMinor: entry.value,
          spentMinor: byCategory[entry.key] ?? 0,
          level: SpendingLimitCalculator.levelFor(
            spentMinor: byCategory[entry.key] ?? 0,
            limitMinor: entry.value,
            warningThresholdPercent: budget.warningThresholdPercent,
          ),
        ),
    ]..sort((a, b) => b.progress.compareTo(a.progress));

    final unallocated = byCategory.entries
        .where((e) => !budget.allocations.containsKey(e.key))
        .fold(0, (total, e) => total + e.value);

    return BudgetStatus(
      budget: budget,
      spentMinor: spent,
      level: SpendingLimitCalculator.levelFor(
        spentMinor: spent,
        limitMinor: budget.totalMinor,
        warningThresholdPercent: budget.warningThresholdPercent,
      ),
      allocationStatuses: allocationStatuses,
      unallocatedSpentMinor: unallocated,
      spentByCategory: byCategory,
      otherCurrencyExpenseCount: otherCurrency,
    );
  }
}
