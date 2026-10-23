import 'package:intl/intl.dart';

/// A half-open time range: [start] is included, [end] is excluded.
///
/// Using half-open ranges means an expense at exactly 00:00 belongs to the
/// new day, never to both days.
class DateRange {
  const DateRange(this.start, this.end);

  final DateTime start;
  final DateTime end;

  bool contains(DateTime moment) =>
      !moment.isBefore(start) && moment.isBefore(end);

  @override
  bool operator ==(Object other) =>
      other is DateRange && other.start == start && other.end == end;

  @override
  int get hashCode => Object.hash(start, end);

  @override
  String toString() => 'DateRange($start → $end)';
}

/// Local-calendar helpers used for daily and monthly periods.
///
/// ⚠️  ASSUMPTION (Phase 3): "local" means the **device's** time zone.
/// The profile field `timeZone` will become configurable in Settings
/// (Phase 6) using the `timezone` package. All helpers take an explicit
/// [DateTime] so they are easy to test and to switch over later.
abstract final class AppDateUtils {
  /// The local calendar day containing [moment]: [00:00, next day 00:00).
  ///
  /// Uses the DateTime constructor (not `add(Duration(days: 1))`) so that
  /// days with a daylight-saving shift still end at midnight.
  static DateRange dayOf(DateTime moment) {
    final local = moment.toLocal();
    return DateRange(
      DateTime(local.year, local.month, local.day),
      DateTime(local.year, local.month, local.day + 1),
    );
  }

  /// The local calendar month containing [moment].
  static DateRange monthOf(DateTime moment) {
    final local = moment.toLocal();
    return DateRange(
      DateTime(local.year, local.month),
      DateTime(local.year, local.month + 1),
    );
  }

  /// Shifts a month range by [months] (negative goes back in time).
  static DateRange shiftMonth(DateRange month, int months) {
    return DateRange(
      DateTime(month.start.year, month.start.month + months),
      DateTime(month.start.year, month.start.month + months + 1),
    );
  }

  /// Stable key for a day period, e.g. "2026-10-23".
  static String dayKey(DateTime moment) =>
      DateFormat('yyyy-MM-dd').format(moment.toLocal());

  /// Stable key for a month period, e.g. "2026-10".
  static String monthKey(DateTime moment) =>
      DateFormat('yyyy-MM').format(moment.toLocal());

  static bool isSameDay(DateTime a, DateTime b) {
    final la = a.toLocal();
    final lb = b.toLocal();
    return la.year == lb.year && la.month == lb.month && la.day == lb.day;
  }

  // ── Display formatting ─────────────────────────────────────────
  static String formatDay(DateTime d) =>
      DateFormat('EEE, d MMM yyyy').format(d.toLocal());

  static String formatShortDay(DateTime d) =>
      DateFormat('d MMM').format(d.toLocal());

  static String formatMonth(DateTime d) =>
      DateFormat('MMMM yyyy').format(d.toLocal());

  static String formatTime(DateTime d) =>
      DateFormat('h:mm a').format(d.toLocal());

  /// "Today", "Yesterday", or a formatted date — used for list headers.
  static String relativeDayLabel(DateTime d, {DateTime? now}) {
    final today = now ?? DateTime.now();
    if (isSameDay(d, today)) return 'Today';
    if (isSameDay(d, DateTime(today.year, today.month, today.day - 1))) {
      return 'Yesterday';
    }
    return formatDay(d);
  }
}
