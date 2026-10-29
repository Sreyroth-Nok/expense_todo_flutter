import 'package:flutter_test/flutter_test.dart';
import 'package:lifemate/utils/date_utils.dart';

void main() {
  group('AppDateUtils.dayOf', () {
    test('covers local midnight to next midnight (half-open)', () {
      final day = AppDateUtils.dayOf(DateTime(2026, 10, 23, 15, 30));
      expect(day.start, DateTime(2026, 10, 23));
      expect(day.end, DateTime(2026, 10, 24));
      expect(day.contains(DateTime(2026, 10, 23)), isTrue);
      expect(day.contains(DateTime(2026, 10, 23, 23, 59, 59)), isTrue);
      expect(day.contains(DateTime(2026, 10, 24)), isFalse);
    });
  });

  group('AppDateUtils.monthOf', () {
    test('handles normal months and the December → January rollover', () {
      final oct = AppDateUtils.monthOf(DateTime(2026, 10, 31, 23, 59));
      expect(oct.start, DateTime(2026, 10));
      expect(oct.end, DateTime(2026, 11));

      final dec = AppDateUtils.monthOf(DateTime(2026, 12, 5));
      expect(dec.end, DateTime(2027, 1));
    });

    test('shiftMonth moves across years', () {
      final jan = AppDateUtils.monthOf(DateTime(2027, 1, 10));
      final dec = AppDateUtils.shiftMonth(jan, -1);
      expect(dec.start, DateTime(2026, 12));
      expect(dec.end, DateTime(2027, 1));
    });
  });

  test('period keys', () {
    expect(AppDateUtils.dayKey(DateTime(2026, 3, 7)), '2026-03-07');
    expect(AppDateUtils.monthKey(DateTime(2026, 3, 7)), '2026-03');
  });
}
