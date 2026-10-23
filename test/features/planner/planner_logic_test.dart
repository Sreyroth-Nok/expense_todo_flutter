import 'package:flutter_test/flutter_test.dart';
import 'package:lifemate/core/services/scheduled_notice.dart';
import 'package:lifemate/features/calendar/domain/calendar_event.dart';
import 'package:lifemate/features/reminders/domain/notification_sync.dart';
import 'package:lifemate/features/reminders/domain/reminder.dart';
import 'package:lifemate/features/reminders/domain/reminder_providers.dart';
import 'package:lifemate/features/savings/domain/savings_goal.dart';
import 'package:lifemate/features/tasks/domain/planner_task.dart';
import 'package:lifemate/shared/models/notification_preferences.dart';

void main() {
  final now = DateTime(2026, 10, 23, 14, 0);

  group('TaskQueries', () {
    final overdue = PlannerTask(
        id: '1', title: 'Old', dueAt: DateTime(2026, 10, 22), priority: TaskPriority.low);
    final todayTimed = PlannerTask(
        id: '2', title: 'Call', dueAt: DateTime(2026, 10, 23, 16), hasDueTime: true);
    final todayPastTime = PlannerTask(
        id: '3', title: 'Meeting', dueAt: DateTime(2026, 10, 23, 9), hasDueTime: true);
    final todayDateOnly = PlannerTask(
        id: '4', title: 'Groceries', dueAt: DateTime(2026, 10, 23));
    final tomorrow = PlannerTask(
        id: '5', title: 'Rent', dueAt: DateTime(2026, 10, 24), priority: TaskPriority.high);
    const noDate = PlannerTask(id: '6', title: 'Someday');
    final doneToday = PlannerTask(
        id: '7', title: 'Done', dueAt: DateTime(2026, 10, 23), status: TaskStatus.done);
    final all = [overdue, todayTimed, todayPastTime, todayDateOnly, tomorrow, noDate, doneToday];

    test('overdue: past deadline and not done (date-only = end of day)', () {
      expect(TaskQueries.overdue(all, now).map((t) => t.id), ['1', '3']);
      expect(todayDateOnly.isOverdueAt(now), isFalse);
    });

    test('today: due today, not overdue, done ones at the end', () {
      expect(TaskQueries.dueToday(all, now).map((t) => t.id), ['2', '4', '7']);
    });

    test('upcoming: after today, incomplete', () {
      expect(TaskQueries.upcoming(all, now).map((t) => t.id), ['5']);
    });

    test('sort by priority puts high first and done last', () {
      final sorted = TaskQueries.sort(all, TaskSort.priority).map((t) => t.id);
      expect(sorted.first, '5');
      expect(sorted.last, '7');
    });

    test('sort by due date puts tasks without a date after dated ones', () {
      final sorted = TaskQueries.sort(all, TaskSort.dueDate)
          .where((t) => !t.isDone)
          .map((t) => t.id)
          .toList();
      expect(sorted.last, '6');
      expect(sorted.first, '1');
    });

    test('reminder time: due time, or 9:00 for date-only tasks', () {
      final timed = PlannerTask(
          title: 'a', dueAt: DateTime(2026, 10, 24, 16), hasDueTime: true, reminderEnabled: true);
      final dateOnly = PlannerTask(
          title: 'b', dueAt: DateTime(2026, 10, 24), reminderEnabled: true);
      expect(timed.reminderAt, DateTime(2026, 10, 24, 16));
      expect(dateOnly.reminderAt, DateTime(2026, 10, 24, 9));
      expect(timed.copyWith(status: TaskStatus.done).reminderAt, isNull);
    });
  });

  group('Reminder', () {
    final bill = Reminder(
      id: 'r1',
      title: 'Internet',
      kind: ReminderKind.bill,
      remindAt: DateTime(2026, 10, 5, 9),
      repeat: NoticeRepeat.monthly,
      amountMinor: 2500,
      currency: 'USD',
    );

    test('repeating reminder: next occurrence is in the future', () {
      expect(bill.nextAt(now), DateTime(2026, 11, 5, 9));
      expect(bill.isOverdueAt(now), isFalse);
    });

    test('paying a monthly bill moves it to the next month, still pending', () {
      final paid = bill.completed(now);
      expect(paid.isPending, isTrue);
      expect(paid.remindAt, DateTime(2026, 11, 5, 9));
    });

    test('paying early (before due) skips to the month after', () {
      final early = Reminder(
        title: 'Rent',
        remindAt: DateTime(2026, 10, 25, 9),
        repeat: NoticeRepeat.monthly,
      ).completed(now);
      expect(early.remindAt, DateTime(2026, 11, 25, 9));
    });

    test('one-off: overdue when past, completed when done', () {
      final once = Reminder(title: 'Call', remindAt: DateTime(2026, 10, 22, 9));
      expect(once.isOverdueAt(now), isTrue);
      expect(once.nextAt(now), isNull);
      expect(once.completed(now).status, ReminderStatus.completed);
      expect(once.dismissed().status, ReminderStatus.dismissed);
    });

    test('upcomingReminders: pending only, sorted, bills filter', () {
      final general = Reminder(id: 'g', title: 'G', remindAt: DateTime(2026, 10, 24, 8));
      final done = Reminder(
          id: 'd', title: 'D', remindAt: DateTime(2026, 10, 24), status: ReminderStatus.completed);
      final list = upcomingReminders([bill, general, done], now);
      expect(list.map((p) => p.$1.id), ['g', 'r1']);
      expect(upcomingReminders([bill, general], now, billsOnly: true).single.$1.id,
          'r1');
    });
  });

  group('buildScheduledNotices', () {
    test('schedules only future items and skips done / completed', () {
      final notices = buildScheduledNotices(
        now: now,
        reminders: [
          Reminder(id: 'future', title: 'F', remindAt: DateTime(2026, 10, 24, 9)),
          Reminder(id: 'past', title: 'P', remindAt: DateTime(2026, 10, 22, 9)),
          Reminder(
              id: 'done',
              title: 'D',
              remindAt: DateTime(2026, 10, 30),
              status: ReminderStatus.completed),
        ],
        tasks: [
          PlannerTask(
              id: 't1', title: 'T', dueAt: DateTime(2026, 10, 25), reminderEnabled: true),
          PlannerTask(id: 't2', title: 'No reminder', dueAt: DateTime(2026, 10, 25)),
        ],
        events: [
          CalendarEvent(
            id: 'e1',
            title: 'Dentist',
            startAt: DateTime(2026, 10, 24, 10),
            endAt: DateTime(2026, 10, 24, 11),
            reminderMinutesBefore: 30,
          ),
        ],
        goals: const [
          SavingsGoal(
              id: 'g1', name: 'Fund', currency: 'USD', targetMinor: 1000, reminderDayOfMonth: 1),
          SavingsGoal(
              id: 'g2',
              name: 'Done',
              currency: 'USD',
              targetMinor: 1000,
              isCompleted: true,
              reminderDayOfMonth: 1),
        ],
      );

      final byId = {for (final n in notices) n.id: n};
      expect(notices, hasLength(4));
      expect(byId[ScheduledNotice.idFor('reminder', 'future')], isNotNull);
      expect(byId[ScheduledNotice.idFor('reminder', 'past')], isNull);
      expect(byId[ScheduledNotice.idFor('task', 't1')]!.at,
          DateTime(2026, 10, 25, 9));
      expect(byId[ScheduledNotice.idFor('event', 'e1')]!.at,
          DateTime(2026, 10, 24, 9, 30));
      final goal = byId[ScheduledNotice.idFor('goal', 'g1')]!;
      expect(goal.at, DateTime(2026, 11, 1, 9));
      expect(goal.repeat, NoticeRepeat.monthly);
    });
  });

  test('notification preferences switch kinds off', () {
    final notices = buildScheduledNotices(
      now: now,
      preferences: const NotificationPreferences(reminders: false, savings: false),
      reminders: [Reminder(id: 'r', title: 'R', remindAt: DateTime(2026, 10, 24))],
      tasks: [
        PlannerTask(id: 't', title: 'T', dueAt: DateTime(2026, 10, 25), reminderEnabled: true),
      ],
      events: const [],
      goals: const [
        SavingsGoal(id: 'g', name: 'G', currency: 'USD', targetMinor: 1, reminderDayOfMonth: 1),
      ],
    );
    expect(notices.map((n) => n.id), [ScheduledNotice.idFor('task', 't')]);
  });

  test('notification preferences map round-trip with safe defaults', () {
    final prefs = NotificationPreferences.fromMap({'tasks': false});
    expect(prefs.tasks, isFalse);
    expect(prefs.reminders, isTrue); // missing keys default to on
    expect(NotificationPreferences.fromMap(prefs.toMap()).tasks, isFalse);
    expect(NotificationPreferences.fromMap(null).spendingLimits, isTrue);
  });

  group('CalendarEvent', () {
    final trip = CalendarEvent(
      title: 'Trip',
      startAt: DateTime(2026, 10, 30),
      endAt: DateTime(2026, 11, 3), // exclusive → last day Nov 2
      allDay: true,
    );

    test('multi-day events appear on each day they cover', () {
      expect(trip.occursOn(DateTime(2026, 10, 30)), isTrue);
      expect(trip.occursOn(DateTime(2026, 11, 2)), isTrue);
      expect(trip.occursOn(DateTime(2026, 11, 3)), isFalse);
      expect(trip.lastDay.day, 2);
    });

    test('validation: end after start, max 31 days', () {
      expect(trip.validate(), isNull);
      expect(
        CalendarEvent(
                title: 'x', startAt: DateTime(2026, 10, 1, 10), endAt: DateTime(2026, 10, 1, 9))
            .validate(),
        isNotNull,
      );
      expect(
        CalendarEvent(title: 'x', startAt: DateTime(2026, 1, 1), endAt: DateTime(2026, 3, 1))
            .validate(),
        isNotNull,
      );
    });
  });
}
