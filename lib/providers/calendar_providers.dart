import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/date_utils.dart';
import '../services/auth_repository.dart';
import '../services/calendar_repository.dart';
import '../models/calendar_event.dart';

/// Events overlapping a date range (DateRange has value equality, so it is
/// a safe family key).
final eventsInRangeProvider = StreamProvider.autoDispose
    .family<List<CalendarEvent>, DateRange>((ref, range) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(calendarRepositoryProvider).watchRange(uid, range);
});

final eventByIdProvider =
    StreamProvider.autoDispose.family<CalendarEvent?, String>((ref, id) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(calendarRepositoryProvider).watchOne(uid, id);
});

/// Events from today until [days] days ahead (dashboard + notifications).
DateRange upcomingRange(DateTime now, {int days = 60}) {
  final today = AppDateUtils.dayOf(now).start;
  return DateRange(today, DateTime(today.year, today.month, today.day + days));
}
