import 'package:flutter_test/flutter_test.dart';
import 'package:lifemate/models/scheduled_notice.dart';

void main() {
  group('NoticeRepeat.nextOccurrence', () {
    final first = DateTime(2026, 10, 5, 9, 0);

    test('future first occurrence is returned as-is', () {
      for (final r in NoticeRepeat.values) {
        expect(r.nextOccurrence(first, DateTime(2026, 10, 1)), first);
      }
    });

    test('one-off in the past has no next occurrence', () {
      expect(NoticeRepeat.none.nextOccurrence(first, DateTime(2026, 10, 6)),
          isNull);
    });

    test('daily and weekly keep the time of day', () {
      expect(
        NoticeRepeat.daily.nextOccurrence(first, DateTime(2026, 10, 7, 10)),
        DateTime(2026, 10, 8, 9),
      );
      expect(
        NoticeRepeat.weekly.nextOccurrence(first, DateTime(2026, 10, 6)),
        DateTime(2026, 10, 12, 9),
      );
    });

    test('monthly keeps the day and clamps short months', () {
      final jan31 = DateTime(2026, 1, 31, 9);
      expect(NoticeRepeat.monthly.nextOccurrence(jan31, DateTime(2026, 2, 1)),
          DateTime(2026, 2, 28, 9));
      // March goes back to the 31st, it does not stay on the 28th.
      expect(NoticeRepeat.monthly.nextOccurrence(jan31, DateTime(2026, 3, 1)),
          DateTime(2026, 3, 31, 9));
    });

    test('addMonthsClamped handles leap years', () {
      expect(addMonthsClamped(DateTime(2028, 1, 31), 1), DateTime(2028, 2, 29));
      expect(addMonthsClamped(DateTime(2026, 12, 15), 1), DateTime(2027, 1, 15));
    });
  });

  group('ScheduledNotice.idFor', () {
    test('is stable and kind-specific', () {
      expect(ScheduledNotice.idFor('reminder', 'abc'),
          ScheduledNotice.idFor('reminder', 'abc'));
      expect(ScheduledNotice.idFor('reminder', 'abc'),
          isNot(ScheduledNotice.idFor('task', 'abc')));
    });

    test('never collides with reserved spending-limit ids', () {
      for (var i = 0; i < 500; i++) {
        final id = ScheduledNotice.idFor('task', 'doc$i');
        expect(id, greaterThanOrEqualTo(ScheduledNotice.firstScheduledId));
        expect(id, lessThan(0x7fffffff));
      }
    });
  });
}
