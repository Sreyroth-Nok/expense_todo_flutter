import 'package:lifemate/features/spending_limits/domain/spending_limit.dart';
import 'package:lifemate/features/transactions/domain/finance_transaction.dart';

/// Small factories that keep tests short and readable.

FinanceTransaction expense(int minor, DateTime date, {String currency = 'USD'}) =>
    FinanceTransaction(
      type: TransactionType.expense,
      amountMinor: minor,
      currency: currency,
      categoryId: 'food',
      categoryName: 'Food & Drinks',
      date: date,
    );

FinanceTransaction income(int minor, DateTime date, {String currency = 'USD'}) =>
    FinanceTransaction(
      type: TransactionType.income,
      amountMinor: minor,
      currency: currency,
      categoryId: 'salary',
      categoryName: 'Salary',
      date: date,
    );

SpendingLimit dailyLimit(int minor, {int? warnAt, bool alerts = true}) =>
    SpendingLimit(
      period: LimitPeriod.daily,
      amountMinor: minor,
      currency: 'USD',
      alertsEnabled: alerts,
      warningThresholdPercent: warnAt,
    );

SpendingLimit monthlyLimit(int minor, {int? warnAt, bool alerts = true}) =>
    SpendingLimit(
      period: LimitPeriod.monthly,
      amountMinor: minor,
      currency: 'USD',
      alertsEnabled: alerts,
      warningThresholdPercent: warnAt,
    );
