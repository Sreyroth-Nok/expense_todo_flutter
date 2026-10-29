import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../shared/widgets/app_card.dart';
import '../../reminders/domain/reminder_providers.dart';
import '../../reminders/presentation/reminders_tab.dart';
import '../../tasks/domain/task_providers.dart';
import '../../tasks/presentation/widgets/task_tile.dart';
import '../domain/calendar_event.dart';
import '../domain/calendar_providers.dart';

/// Planner → Calendar: month grid + agenda of the selected day.
///
/// Dots under a date: teal = event, honey = task due, orange = reminder.
class CalendarTab extends ConsumerStatefulWidget {
  const CalendarTab({super.key});

  @override
  ConsumerState<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends ConsumerState<CalendarTab> {
  late DateRange _month = AppDateUtils.monthOf(DateTime.now());
  late DateTime _selected = AppDateUtils.dayOf(DateTime.now()).start;

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsInRangeProvider(_month)).value ?? const [];
    final tasks = ref.watch(tasksProvider).value ?? const [];
    final reminders = ref.watch(remindersProvider).value ?? const [];
    final now = DateTime.now();
    final pendingReminders = upcomingReminders(reminders, now);

    bool hasEvent(DateTime d) => events.any((e) => e.occursOn(d));
    bool hasTask(DateTime d) => tasks.any((t) => !t.isDone && t.isDueOn(d));
    bool hasReminder(DateTime d) =>
        pendingReminders.any((p) => AppDateUtils.isSameDay(p.$2, d));

    final dayEvents = events.where((e) => e.occursOn(_selected)).toList();
    final dayTasks = tasks.where((t) => t.isDueOn(_selected)).toList();
    final dayReminders = pendingReminders
        .where((p) => AppDateUtils.isSameDay(p.$2, _selected))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-event',
        onPressed: () => context.push(AppRoutes.newEventOn(_selected)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.event_rounded),
        label: const Text('Event'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 96),
        children: [
          _MonthHeader(
            month: _month,
            onPrevious: () =>
                setState(() => _month = AppDateUtils.shiftMonth(_month, -1)),
            onNext: () =>
                setState(() => _month = AppDateUtils.shiftMonth(_month, 1)),
            onToday: () => setState(() {
              _month = AppDateUtils.monthOf(now);
              _selected = AppDateUtils.dayOf(now).start;
            }),
          ),
          _MonthGrid(
            month: _month,
            selected: _selected,
            onSelect: (d) => setState(() => _selected = d),
            dotsFor: (d) => [
              if (hasEvent(d)) AppColors.primary,
              if (hasTask(d)) AppColors.honey,
              if (hasReminder(d)) AppColors.warning,
            ],
          ),
          const Gap(16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(AppDateUtils.relativeDayLabel(_selected, now: now),
                style: AppTextStyles.titleLarge),
          ),
          const Gap(8),
          if (dayEvents.isEmpty && dayTasks.isEmpty && dayReminders.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Nothing planned for this day.',
                  style: AppTextStyles.bodySmall),
            ),
          for (final e in dayEvents) ...[
            _EventCard(event: e),
            const Gap(8),
          ],
          for (final (r, at) in dayReminders) ...[
            ReminderTile(reminder: r, at: at),
            const Gap(8),
          ],
          if (dayTasks.isNotEmpty)
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [for (final t in dayTasks) TaskTile(task: t)],
              ),
            ),
        ],
      ),
    );
  }
}

class _MonthHeader extends StatelessWidget {
  const _MonthHeader({
    required this.month,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateRange month;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Gap(4),
        Expanded(
          child: Text(AppDateUtils.formatMonth(month.start),
              style: AppTextStyles.headlineSmall),
        ),
        TextButton(onPressed: onToday, child: const Text('Today')),
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: 'Previous month',
          onPressed: onPrevious,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: 'Next month',
          onPressed: onNext,
        ),
      ],
    );
  }
}

/// A Monday-first month grid.
class _MonthGrid extends StatelessWidget {
  const _MonthGrid({
    required this.month,
    required this.selected,
    required this.onSelect,
    required this.dotsFor,
  });

  final DateRange month;
  final DateTime selected;
  final ValueChanged<DateTime> onSelect;
  final List<Color> Function(DateTime day) dotsFor;

  static const _weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  Widget build(BuildContext context) {
    final first = month.start;
    final leading = first.weekday - 1; // Monday = 1
    final daysInMonth = DateTime(first.year, first.month + 1, 0).day;
    final cells = leading + daysInMonth;
    final rows = (cells / 7).ceil();
    final today = DateTime.now();

    return Column(
      children: [
        Row(
          children: [
            for (final w in _weekdays)
              Expanded(
                child: Center(
                  child: Text(w, style: AppTextStyles.labelSmall),
                ),
              ),
          ],
        ),
        const Gap(4),
        for (var r = 0; r < rows; r++)
          Row(
            children: [
              for (var c = 0; c < 7; c++)
                Expanded(
                  child: Builder(builder: (context) {
                    final dayNumber = r * 7 + c - leading + 1;
                    if (dayNumber < 1 || dayNumber > daysInMonth) {
                      return const SizedBox(height: 48);
                    }
                    final day = DateTime(first.year, first.month, dayNumber);
                    final isSelected = AppDateUtils.isSameDay(day, selected);
                    final isToday = AppDateUtils.isSameDay(day, today);
                    final dots = dotsFor(day);
                    return InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => onSelect(day),
                      child: SizedBox(
                        height: 52,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 36,
                              height: 36,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? AppColors.primary : null,
                                border: isToday && !isSelected
                                    ? Border.all(
                                        color: AppColors.primary, width: 1.5)
                                    : null,
                              ),
                              child: Text(
                                '$dayNumber',
                                style: AppTextStyles.labelLarge.copyWith(
                                  color: isSelected
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontWeight: isSelected || isToday
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            const Gap(2),
                            SizedBox(
                              height: 5,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  for (final color in dots)
                                    Container(
                                      width: 5,
                                      height: 5,
                                      margin: const EdgeInsets.symmetric(
                                          horizontal: 1),
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ),
            ],
          ),
      ],
    );
  }
}

/// Time label for an event, e.g. "All day" or "9:00 AM – 10:30 AM".
String eventTimeLabel(CalendarEvent e) {
  final multiDay = !AppDateUtils.isSameDay(e.startAt, e.lastDay);
  if (e.allDay) {
    return multiDay
        ? 'All day · until ${AppDateUtils.formatShortDay(e.lastDay)}'
        : 'All day';
  }
  final end = multiDay
      ? '${AppDateUtils.formatShortDay(e.endAt)} ${AppDateUtils.formatTime(e.endAt)}'
      : AppDateUtils.formatTime(e.endAt);
  return '${AppDateUtils.formatTime(e.startAt)} – $end';
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event});

  final CalendarEvent event;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(AppRoutes.editEvent(event.id)),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 66,
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    event.allDay
                        ? 'All day'
                        : AppDateUtils.formatTime(event.startAt),
                    style: AppTextStyles.labelMedium,
                  ),
                ),
              ),
              Container(
                width: 4,
                decoration: BoxDecoration(
                  color: AppColors.honey,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title, style: AppTextStyles.titleMedium),
                    const Gap(2),
                    Text(
                      [
                        eventTimeLabel(event),
                        if (event.location.isNotEmpty) event.location,
                      ].join(' · '),
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              if (event.reminderMinutesBefore != null)
                const Padding(
                  padding: EdgeInsets.only(top: 2),
                  child: Icon(Icons.notifications_active_outlined,
                      size: 18, color: AppColors.textSecondary),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
