import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../data/reminder_repository.dart';
import 'reminder.dart';

final remindersProvider = StreamProvider<List<Reminder>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(reminderRepositoryProvider).watchAll(uid);
});

final reminderByIdProvider =
    StreamProvider.autoDispose.family<Reminder?, String>((ref, id) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(reminderRepositoryProvider).watchOne(uid, id);
});

/// Pending reminders sorted by their next occurrence (overdue first).
List<(Reminder, DateTime)> upcomingReminders(
  Iterable<Reminder> reminders,
  DateTime now, {
  bool billsOnly = false,
}) {
  final result = <(Reminder, DateTime)>[];
  for (final r in reminders) {
    if (!r.isPending || (billsOnly && !r.isBill)) continue;
    // Overdue one-off reminders keep their original time.
    final at = r.nextAt(now) ?? r.remindAt;
    result.add((r, at));
  }
  result.sort((a, b) => a.$2.compareTo(b.$2));
  return result;
}
