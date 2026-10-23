import 'package:flutter_test/flutter_test.dart';
import 'package:lifemate/features/spending_limits/domain/spending_limit.dart';
import 'package:lifemate/features/spending_limits/domain/spending_limit_calculator.dart';

import '../../helpers/builders.dart';

void main() {
  final now = DateTime(2026, 10, 23, 14, 0);

  LimitStatus daily(List txs, {int limit = 500, int? warnAt}) =>
      SpendingLimitCalculator.evaluate(
        limit: dailyLimit(limit, warnAt: warnAt),
        transactions: txs.cast(),
        now: now,
      );

  group('levels', () {
    test('expense below the limit → ok, positive remaining', () {
      final s = daily([expense(400, now)]);
      expect(s.level, LimitLevel.ok);
      expect(s.remainingMinor, 100);
    });

    test('expense exactly equal to the limit → reached, zero remaining', () {
      final s = daily([expense(500, now)]);
      expect(s.level, LimitLevel.reached);
      expect(s.remainingMinor, 0);
      expect(s.exceededByMinor, 0);
    });

    test(r'spec example: $5 limit, $4 + $2 → exceeded by $1', () {
      final before = daily([expense(400, now)]);
      expect(before.remainingMinor, 100);

      final after = daily([expense(400, now), expense(200, now)]);
      expect(after.spentMinor, 600);
      expect(after.level, LimitLevel.exceeded);
      expect(after.remainingMinor, -100);
      expect(after.exceededByMinor, 100);
    });

    test('warning threshold reached (80% of \$5 = \$4)', () {
      expect(daily([expense(399, now)], warnAt: 80).level, LimitLevel.ok);
      expect(daily([expense(400, now)], warnAt: 80).level, LimitLevel.warning);
    });

    test('without a threshold there is no warning level', () {
      expect(daily([expense(499, now)]).level, LimitLevel.ok);
    });
  });

  group('what counts', () {
    test('income never affects spending limits', () {
      final s = daily([income(100000, now), expense(100, now)]);
      expect(s.spentMinor, 100);
      expect(s.level, LimitLevel.ok);
    });

    test('expenses in other currencies are not combined', () {
      final s = daily([expense(300, now), expense(50000, now, currency: 'KHR')]);
      expect(s.spentMinor, 300);
      expect(s.otherCurrencyExpenseCount, 1);
    });

    test('expense edited to a lower amount lowers the total', () {
      final original = expense(600, now);
      expect(daily([original]).level, LimitLevel.exceeded);
      final edited = original.copyWith(amountMinor: 300);
      final s = daily([edited]);
      expect(s.level, LimitLevel.ok);
      expect(s.remainingMinor, 200);
    });

    test('deleted expense no longer counts', () {
      final a = expense(300, now);
      final b = expense(300, now);
      expect(daily([a, b]).level, LimitLevel.exceeded);
      expect(daily([a]).level, LimitLevel.ok); // b deleted
    });
  });

  group('period boundaries', () {
    test('midnight: 23:59 yesterday does not count, 00:00 today does', () {
      final midnight = DateTime(2026, 10, 23);
      final s = SpendingLimitCalculator.evaluate(
        limit: dailyLimit(500),
        transactions: [
          expense(900, DateTime(2026, 10, 22, 23, 59, 59)),
          expense(100, midnight),
        ],
        now: DateTime(2026, 10, 23, 0, 0, 1),
      );
      expect(s.spentMinor, 100);
      expect(s.range.start, midnight);
    });

    test('daily total resets on the next local day', () {
      final yesterday = DateTime(2026, 10, 22, 20);
      final s = SpendingLimitCalculator.evaluate(
        limit: dailyLimit(500),
        transactions: [expense(800, yesterday)],
        now: DateTime(2026, 10, 23, 8),
      );
      expect(s.spentMinor, 0);
      expect(s.level, LimitLevel.ok);
    });

    test('month boundary: Oct 31 23:59 vs Nov 1 00:00', () {
      final txs = [
        expense(4000, DateTime(2026, 10, 31, 23, 59)),
        expense(700, DateTime(2026, 11, 1, 0, 0)),
      ];
      final nov = SpendingLimitCalculator.evaluate(
        limit: monthlyLimit(5000),
        transactions: txs,
        now: DateTime(2026, 11, 1, 9),
      );
      expect(nov.spentMinor, 700);

      final oct = SpendingLimitCalculator.evaluate(
        limit: monthlyLimit(5000),
        transactions: txs,
        now: DateTime(2026, 10, 31, 23, 59, 30),
      );
      expect(oct.spentMinor, 4000);
    });
  });

  test('daily and monthly limits are evaluated independently', () {
    // $6 today exceeds the $5 daily limit but is fine for the $50 month.
    final txs = [expense(600, now), expense(1000, DateTime(2026, 10, 2))];
    final d = SpendingLimitCalculator.evaluate(
        limit: dailyLimit(500), transactions: txs, now: now);
    final m = SpendingLimitCalculator.evaluate(
        limit: monthlyLimit(5000), transactions: txs, now: now);
    expect(d.level, LimitLevel.exceeded);
    expect(m.level, LimitLevel.ok);
    expect(m.spentMinor, 1600);

    // Monthly can trigger while today is fine.
    final m2 = SpendingLimitCalculator.evaluate(
      limit: monthlyLimit(5000),
      transactions: [expense(5200, DateTime(2026, 10, 1)), expense(100, now)],
      now: now,
    );
    final d2 = SpendingLimitCalculator.evaluate(
      limit: dailyLimit(500),
      transactions: [expense(5200, DateTime(2026, 10, 1)), expense(100, now)],
      now: now,
    );
    expect(m2.level, LimitLevel.exceeded);
    expect(d2.level, LimitLevel.ok);
  });
}
