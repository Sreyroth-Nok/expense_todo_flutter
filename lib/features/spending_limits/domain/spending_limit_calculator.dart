import '../../../core/utils/date_utils.dart';
import '../../transactions/domain/finance_transaction.dart';
import 'spending_limit.dart';

/// The result of comparing spending against one limit.
class LimitStatus {
  const LimitStatus({
    required this.limit,
    required this.range,
    required this.spentMinor,
    required this.level,
    this.otherCurrencyExpenseCount = 0,
  });

  final SpendingLimit limit;

  /// The local day or month that was evaluated.
  final DateRange range;

  /// Sum of eligible expenses, in the limit's currency (minor units).
  final int spentMinor;

  final LimitLevel level;

  /// Expenses in this period that use a different currency. They are NOT
  /// counted (no exchange rates), and the UI tells the user about them.
  final int otherCurrencyExpenseCount;

  /// May be zero or negative once the limit is reached / exceeded.
  int get remainingMinor => limit.amountMinor - spentMinor;

  int get exceededByMinor => remainingMinor < 0 ? -remainingMinor : 0;

  /// 0.0 – 1.0+ for progress bars only. Never use for money maths.
  double get progress =>
      limit.amountMinor == 0 ? 0 : spentMinor / limit.amountMinor;
}

/// Pure business logic for spending limits (Phase 3 rules).
///
/// 1. Only expenses count — income never does.
/// 2. Only expenses in the limit's currency count.
/// 3. Only expenses whose date falls in the current local day / month count.
/// 4. Daily and monthly limits are evaluated independently.
/// 5. Exceeding a limit never blocks recording an expense — this class only
///    reports the status.
abstract final class SpendingLimitCalculator {
  static LimitStatus evaluate({
    required SpendingLimit limit,
    required Iterable<FinanceTransaction> transactions,
    required DateTime now,
  }) {
    final range = limit.period.rangeAt(now);
    var spent = 0;
    var otherCurrency = 0;

    for (final tx in transactions) {
      if (!tx.isExpense) continue;
      if (!range.contains(tx.date)) continue;
      if (tx.currency != limit.currency) {
        otherCurrency++;
        continue;
      }
      spent += tx.amountMinor;
    }

    return LimitStatus(
      limit: limit,
      range: range,
      spentMinor: spent,
      level: levelFor(
        spentMinor: spent,
        limitMinor: limit.amountMinor,
        warningThresholdPercent: limit.warningThresholdPercent,
      ),
      otherCurrencyExpenseCount: otherCurrency,
    );
  }

  /// Integer-only comparison, so "exactly equal" is exact.
  static LimitLevel levelFor({
    required int spentMinor,
    required int limitMinor,
    int? warningThresholdPercent,
  }) {
    if (spentMinor > limitMinor) return LimitLevel.exceeded;
    if (spentMinor == limitMinor) return LimitLevel.reached;
    if (warningThresholdPercent != null &&
        spentMinor * 100 >= limitMinor * warningThresholdPercent) {
      return LimitLevel.warning;
    }
    return LimitLevel.ok;
  }
}
