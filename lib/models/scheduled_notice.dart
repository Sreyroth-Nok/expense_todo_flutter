/// How a scheduled notification repeats.
enum NoticeRepeat {
  none,
  daily,
  weekly,
  monthly;

  static NoticeRepeat fromName(String? name) =>
      values.firstWhere((r) => r.name == name, orElse: () => NoticeRepeat.none);

  String get label => switch (this) {
        none => 'Does not repeat',
        daily => 'Every day',
        weekly => 'Every week',
        monthly => 'Every month',
      };

  /// The first occurrence at or after [after], starting from [first].
  ///
  /// Monthly repeats keep the original day of month and clamp to the last
  /// day for short months (31 Jan → 28 Feb → 31 Mar).
  /// Returns null for a non-repeating time that is already in the past.
  DateTime? nextOccurrence(DateTime first, DateTime after) {
    if (!first.isBefore(after)) return first;
    switch (this) {
      case NoticeRepeat.none:
        return null;
      case NoticeRepeat.daily:
      case NoticeRepeat.weekly:
        final step = this == NoticeRepeat.daily ? 1 : 7;
        var candidate = first;
        var i = 0;
        // Constructor arithmetic keeps the wall-clock time across DST.
        while (candidate.isBefore(after)) {
          i += step;
          candidate = DateTime(first.year, first.month, first.day + i,
              first.hour, first.minute);
        }
        return candidate;
      case NoticeRepeat.monthly:
        var months = 0;
        var candidate = first;
        while (candidate.isBefore(after)) {
          months++;
          candidate = addMonthsClamped(first, months);
        }
        return candidate;
    }
  }
}

/// [date] plus [months], clamping the day to the target month's length.
DateTime addMonthsClamped(DateTime date, int months) {
  final firstOfTarget = DateTime(date.year, date.month + months);
  final lastDay = DateTime(firstOfTarget.year, firstOfTarget.month + 1, 0).day;
  final day = date.day > lastDay ? lastDay : date.day;
  return DateTime(firstOfTarget.year, firstOfTarget.month, day, date.hour,
      date.minute);
}

/// A notification to be scheduled on the device.
class ScheduledNotice {
  const ScheduledNotice({
    required this.id,
    required this.title,
    required this.body,
    required this.at,
    this.repeat = NoticeRepeat.none,
  });

  final int id;
  final String title;
  final String body;

  /// Next time it should fire (local time).
  final DateTime at;
  final NoticeRepeat repeat;

  /// Ids below this are reserved for immediate alerts (spending limits use
  /// 1001 and 1002), so the scheduler never cancels them.
  static const int firstScheduledId = 10000;

  /// Stable notification id for a document, e.g. idFor('reminder', docId).
  ///
  /// Uses FNV-1a hashing so the same document always gets the same id on
  /// every device and app start, which lets us cancel / replace it.
  static int idFor(String kind, String docId) {
    var hash = 0x811c9dc5;
    for (final unit in '$kind:$docId'.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0x7fffffff;
    }
    // Keep inside a positive 31-bit range above the reserved ids.
    return firstScheduledId + (hash % (0x7fffffff - firstScheduledId));
  }
}
