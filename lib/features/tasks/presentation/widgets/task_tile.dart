import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/ui_kit.dart';
import '../../../auth/data/auth_repository.dart';
import '../../data/task_repository.dart';
import '../../domain/planner_task.dart';

extension TaskPriorityStyle on TaskPriority {
  Color get color => switch (this) {
        TaskPriority.low => AppColors.textSecondary,
        TaskPriority.medium => AppColors.warning,
        TaskPriority.high => AppColors.error,
      };
}

/// Due-date label such as "Today 3:00 PM" or "Fri, 24 Oct 2026".
String taskDueLabel(PlannerTask t, {DateTime? now}) {
  final d = t.dueAt;
  if (d == null) return 'No due date';
  final day = AppDateUtils.relativeDayLabel(d, now: now);
  return t.hasDueTime ? '$day ${AppDateUtils.formatTime(d)}' : day;
}

/// A task row with a completion checkbox. Tapping opens the editor.
class TaskTile extends ConsumerWidget {
  const TaskTile({super.key, required this.task});

  final PlannerTask task;

  Future<void> _toggle(BuildContext context, WidgetRef ref) async {
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    try {
      await ref.read(taskRepositoryProvider).setStatus(
          uid, task.id, task.isDone ? TaskStatus.todo : TaskStatus.done);
    } catch (e) {
      if (context.mounted) AppSnackBar.error(context, readableError(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final overdue = task.isOverdueAt(now);

    return InkWell(
      onTap: () => context.push(AppRoutes.editTask(task.id)),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            RoundCheck(
              checked: task.isDone,
              semanticLabel: task.title,
              onChanged: (_) => _toggle(context, ref),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: AppTextStyles.titleMedium.copyWith(
                      decoration:
                          task.isDone ? TextDecoration.lineThrough : null,
                      color: task.isDone
                          ? AppColors.textSecondary
                          : AppColors.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(2),
                  Row(
                    children: [
                      if (task.reminderEnabled && !task.isDone) ...[
                        const Icon(Icons.notifications_active_outlined,
                            size: 13, color: AppColors.textSecondary),
                        const Gap(3),
                      ],
                      Flexible(
                        child: Text(
                          overdue
                              ? 'Overdue · ${taskDueLabel(task, now: now)}'
                              : taskDueLabel(task, now: now),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: overdue
                                ? AppColors.error
                                : AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (task.status == TaskStatus.inProgress) ...[
                        const Gap(6),
                        const AppBadge(
                            label: 'In progress', color: AppColors.primary),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const Gap(8),
            if (!task.isDone)
              AppBadge(label: task.priority.label, color: task.priority.color),
            const Gap(4),
          ],
        ),
      ),
    );
  }
}
