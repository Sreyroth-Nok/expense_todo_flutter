import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/services/scheduled_notice.dart';
import '../../../core/utils/clock_provider.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money.dart';
import '../../../shared/models/notification_preferences.dart';
import '../../auth/data/auth_repository.dart';
import '../../calendar/domain/calendar_event.dart';
import '../../calendar/domain/calendar_providers.dart';
import '../../savings/domain/savings_goal.dart';
import '../../savings/domain/savings_providers.dart';
import '../../tasks/domain/planner_task.dart';
import '../../tasks/domain/task_providers.dart';
import 'reminder.dart';
import 'reminder_providers.dart';

/// Turns the user's data into device notifications (pure, unit-tested).
///
///   • pending reminders / bills → at their next occurrence (OS repeats)
///   • tasks with "Remind me"    → at the due time (09:00 for date-only)
///   • events with a reminder    → start time minus the chosen minutes
///   • savings goals             → monthly on the chosen day at 09:00
///
/// Kinds switched off in [preferences] are skipped entirely.
List<ScheduledNotice> buildScheduledNotices({
  required Iterable<Reminder> reminders,
  required Iterable<PlannerTask> tasks,
  required Iterable<CalendarEvent> events,
  required Iterable<SavingsGoal> goals,
  required DateTime now,
  NotificationPreferences preferences = const NotificationPreferences(),
}) {
  final notices = <ScheduledNotice>[];

  for (final r in preferences.reminders ? reminders : const <Reminder>[]) {
    final at = r.nextAt(now);
    if (at == null || !at.isAfter(now)) continue;
    final amount = r.isBill && r.amountMinor != null
        ? ' — ${Money.format(r.amountMinor!, r.currency ?? 'USD')}'
        : '';
    notices.add(ScheduledNotice(
      id: ScheduledNotice.idFor('reminder', r.id),
      title: r.isBill ? 'Bill due: ${r.title}' : r.title,
      body: r.notes.isNotEmpty
          ? '${r.notes}$amount'
          : (r.isBill ? 'Payment due$amount' : 'Reminder'),
      at: at,
      repeat: r.repeat,
    ));
  }

  for (final t in preferences.tasks ? tasks : const <PlannerTask>[]) {
    final at = t.reminderAt;
    if (at == null || !at.isAfter(now)) continue;
    notices.add(ScheduledNotice(
      id: ScheduledNotice.idFor('task', t.id),
      title: 'Task due: ${t.title}',
      body: t.notes.isNotEmpty ? t.notes : 'Priority: ${t.priority.label}',
      at: at,
    ));
  }

  for (final e in preferences.events ? events : const <CalendarEvent>[]) {
    final at = e.reminderAt;
    if (at == null || !at.isAfter(now)) continue;
    notices.add(ScheduledNotice(
      id: ScheduledNotice.idFor('event', e.id),
      title: e.title,
      body: [
        e.allDay ? 'All day' : 'Starts ${AppDateUtils.formatTime(e.startAt)}',
        if (e.location.isNotEmpty) e.location,
      ].join(' · '),
      at: at,
    ));
  }

  for (final g in preferences.savings ? goals : const <SavingsGoal>[]) {
    final day = g.reminderDayOfMonth;
    if (day == null || g.isCompleted) continue;
    final first = DateTime(now.year, now.month, day, 9);
    final at = NoticeRepeat.monthly.nextOccurrence(first, now);
    if (at == null) continue;
    notices.add(ScheduledNotice(
      id: ScheduledNotice.idFor('goal', g.id),
      title: 'Time to save for ${g.name}',
      body: '${Money.format(g.remainingMinor, g.currency)} to go '
          '(${g.percent}% saved).',
      at: at,
      repeat: NoticeRepeat.monthly,
    ));
  }

  return notices;
}

/// Keeps the device's scheduled notifications in sync with Firestore.
///
/// Watched by the main shell while the user is signed in. Because it
/// listens to live streams, an edit made on ANOTHER device also updates
/// this device's schedule the next time this app is open. Signing out
/// produces empty lists, which cancels everything that was scheduled.
final notificationSyncProvider = Provider<void>((ref) {
  final now = watchNow(ref);
  final reminders = ref.watch(remindersProvider);
  final tasks = ref.watch(tasksProvider);
  final events = ref.watch(eventsInRangeProvider(upcomingRange(now)));
  final goals = ref.watch(savingsGoalsProvider);
  final profile = ref.watch(currentUserProfileProvider);

  // Wait until every source has loaded, so a half-loaded state never
  // cancels notifications that are still valid.
  if (!reminders.hasValue ||
      !tasks.hasValue ||
      !events.hasValue ||
      !goals.hasValue ||
      !profile.hasValue) {
    return;
  }

  ref.read(notificationServiceProvider).replaceScheduled(
        buildScheduledNotices(
          reminders: reminders.value!,
          tasks: tasks.value!,
          events: events.value!,
          goals: goals.value!,
          now: DateTime.now(),
          preferences: profile.value?.notificationPreferences ??
              const NotificationPreferences(),
        ),
      );
});
