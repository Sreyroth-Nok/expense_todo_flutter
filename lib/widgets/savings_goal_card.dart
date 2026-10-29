import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/date_utils.dart';
import '../utils/money.dart';
import 'app_card.dart';
import 'progress_bar.dart';
import '../models/savings_goal.dart';

/// Goal name, saved of target, percent, and target-date hint.
class SavingsGoalCard extends StatelessWidget {
  const SavingsGoalCard({super.key, required this.goal, this.onTap});

  final SavingsGoal goal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final days = goal.daysLeft(DateTime.now());
    final dateHint = goal.targetDate == null
        ? null
        : days! >= 0
            ? 'Target ${AppDateUtils.formatShortDay(goal.targetDate!)} · $days days left'
            : 'Target date passed (${AppDateUtils.formatShortDay(goal.targetDate!)})';

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                goal.isCompleted
                    ? Icons.emoji_events_rounded
                    : Icons.savings_rounded,
                color: goal.isCompleted ? AppColors.honey : AppColors.primary,
                size: 20,
              ),
              const Gap(8),
              Expanded(
                child: Text(goal.name,
                    style: AppTextStyles.titleMedium,
                    overflow: TextOverflow.ellipsis),
              ),
              if (goal.isCompleted)
                const AppBadge(label: 'Completed', color: AppColors.success)
              else
                Text('${goal.percent}%',
                    style: AppTextStyles.titleMedium
                        .copyWith(color: AppColors.primary)),
            ],
          ),
          const Gap(10),
          Text(
            '${Money.format(goal.savedMinor, goal.currency)} of ${Money.format(goal.targetMinor, goal.currency)}',
            style: AppTextStyles.titleLarge,
          ),
          const Gap(8),
          ProgressBar(
            value: goal.progress,
            color: goal.isTargetReached ? AppColors.success : AppColors.honey,
          ),
          const Gap(6),
          Text(
            goal.isTargetReached
                ? 'Target reached 🎉'
                : '${Money.format(goal.remainingMinor, goal.currency)} to go',
            style: AppTextStyles.labelLarge.copyWith(
              color: goal.isTargetReached
                  ? AppColors.success
                  : AppColors.textSecondary,
            ),
          ),
          if (dateHint != null) ...[
            const Gap(2),
            Text(
              dateHint,
              style: AppTextStyles.bodySmall.copyWith(
                color: days! < 0 && !goal.isCompleted
                    ? AppColors.warning
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
