import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../routing/app_routes.dart';
import '../../models/scheduled_notice.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/clock_provider.dart';
import '../../utils/date_utils.dart';
import '../../utils/money.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_states.dart';
import '../../services/auth_repository.dart';
import '../../services/reminder_repository.dart';
import '../../models/reminder.dart';
import '../../providers/reminder_providers.dart';

/// Planner → Reminders: overdue, upcoming and finished reminders.
class RemindersTab extends ConsumerWidget {
  const RemindersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-reminder',
        onPressed: () => context.push(AppRoutes.newReminder),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_alert_rounded),
        label: const Text('Reminder'),
      ),
      body: remindersAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => Center(child: ErrorState(error: e)),
        data: (all) {
          final pending = upcomingReminders(all, now);
          final overdue = pending.where((p) => p.$1.isOverdueAt(now)).toList();
          final upcoming =
              pending.where((p) => !p.$1.isOverdueAt(now)).toList();
          final finished = all.where((r) => !r.isPending).take(20).toList();

          if (all.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.notifications_none_rounded,
                title: 'No reminders',
                message: 'Add reminders and bill due dates. You get a '
                    'notification even when LifeMate is closed.',
                actionLabel: 'Add a bill reminder',
                onAction: () => context.push(
                    AppRoutes.newReminderOf(ReminderKind.bill.name)),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              for (final (title, items, color) in [
                ('Overdue', overdue, AppColors.error),
                ('Upcoming', upcoming, AppColors.textSecondary),
              ])
                if (items.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 6),
                    child: Text(title,
                        style: AppTextStyles.labelMedium.copyWith(color: color)),
                  ),
                  for (final (r, at) in items) ...[
                    ReminderTile(reminder: r, at: at),
                    const Gap(8),
                  ],
                ],
              if (finished.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 16, bottom: 6),
                  child: Text('Done & dismissed',
                      style: AppTextStyles.labelMedium),
                ),
                for (final r in finished) ...[
                  ReminderTile(reminder: r, at: r.remindAt),
                  const Gap(8),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}

/// A reminder card with Done / Dismiss / Reopen actions.
class ReminderTile extends ConsumerWidget {
  const ReminderTile({super.key, required this.reminder, required this.at});

  final Reminder reminder;

  /// The occurrence to display (next one for repeating reminders).
  final DateTime at;

  Future<void> _update(
      BuildContext context, WidgetRef ref, Reminder next, String msg) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    try {
      await ref.read(reminderRepositoryProvider).save(uid, next);
      if (context.mounted) AppSnackBar.success(context, msg);
    } catch (e) {
      if (context.mounted) AppSnackBar.error(context, readableError(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = reminder;
    final now = DateTime.now();
    final overdue = r.isOverdueAt(now);
    final details = [
      '${AppDateUtils.relativeDayLabel(at, now: now)} ${AppDateUtils.formatTime(at)}',
      if (r.repeat != NoticeRepeat.none) r.repeat.label,
    ].join(' · ');

    return Opacity(
      opacity: r.isPending ? 1 : 0.6,
      child: AppCard(
        padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
        onTap: () => context.push(AppRoutes.editReminder(r.id)),
        child: Row(
          children: [
            Icon(
              r.isBill
                  ? Icons.receipt_long_rounded
                  : Icons.notifications_active_rounded,
              color: overdue
                  ? AppColors.error
                  : r.isBill
                      ? AppColors.warning
                      : AppColors.primary,
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.title,
                    style: AppTextStyles.titleMedium.copyWith(
                      decoration: r.status == ReminderStatus.completed
                          ? TextDecoration.lineThrough
                          : null,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(2),
                  Text(
                    details,
                    style: AppTextStyles.bodySmall.copyWith(
                        color: overdue ? AppColors.error : null),
                  ),
                  if (r.isBill && r.amountMinor != null)
                    Text(
                      Money.format(r.amountMinor!, r.currency ?? 'USD'),
                      style: AppTextStyles.labelLarge,
                    ),
                ],
              ),
            ),
            if (r.isPending)
              IconButton(
                tooltip: r.isBill ? 'Mark as paid' : 'Mark as done',
                icon: const Icon(Icons.check_circle_outline_rounded,
                    color: AppColors.success),
                onPressed: () => _update(
                  context,
                  ref,
                  r.completed(now),
                  r.repeat == NoticeRepeat.none
                      ? 'Marked as done.'
                      : 'Done — next one is scheduled.',
                ),
              ),
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (v) => switch (v) {
                'dismiss' => _update(context, ref, r.dismissed(), 'Dismissed.'),
                _ => _update(context, ref, r.reopened(), 'Reminder reopened.'),
              },
              itemBuilder: (_) => [
                if (r.isPending)
                  const PopupMenuItem(value: 'dismiss', child: Text('Dismiss'))
                else
                  const PopupMenuItem(value: 'reopen', child: Text('Reopen')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
