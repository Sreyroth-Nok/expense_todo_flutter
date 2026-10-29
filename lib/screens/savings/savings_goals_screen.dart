import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../routing/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/date_utils.dart';
import '../../utils/money.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_states.dart';
import '../../widgets/illustrations.dart';
import '../../widgets/progress_bar.dart';
import '../../models/savings_goal.dart';
import '../../providers/savings_providers.dart';

/// Savings goals: the first goal in a featured card, the others as rows.
class SavingsGoalsScreen extends ConsumerWidget {
  const SavingsGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Savings Goals')),
      bottomNavigationBar: goalsAsync.value?.isNotEmpty ?? false
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: AppPrimaryButton(
                label: 'Create Goal',
                icon: Icons.add_rounded,
                onPressed: () => context.push(AppRoutes.newSavingsGoal),
              ),
            )
          : null,
      body: goalsAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => Center(child: ErrorState(error: e)),
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  icon: Icons.savings_rounded,
                  title: 'No savings goals yet',
                  message: 'Set a target, like a new phone or an emergency '
                      'fund, and record money as you put it aside.',
                  actionLabel: 'Create Goal',
                  onAction: () => context.push(AppRoutes.newSavingsGoal),
                ),
              ),
            );
          }
          final active = goals.where((g) => !g.isCompleted).toList();
          final done = goals.where((g) => g.isCompleted).toList();
          final featured = active.isNotEmpty ? active.first : null;
          final others = active.skip(1).toList();

          void open(SavingsGoal g) =>
              context.push(AppRoutes.savingsGoalDetail(g.id));

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            children: [
              if (featured != null) ...[
                _FeaturedGoal(goal: featured, onTap: () => open(featured)),
                const Gap(20),
              ],
              if (others.isNotEmpty)
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Column(
                    children: [
                      for (final g in others)
                        _GoalRow(goal: g, onTap: () => open(g)),
                    ],
                  ),
                ),
              if (done.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 20, bottom: 8),
                  child: Text('Completed', style: AppTextStyles.labelMedium),
                ),
                AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Column(
                    children: [
                      for (final g in done)
                        _GoalRow(goal: g, onTap: () => open(g)),
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _FeaturedGoal extends StatelessWidget {
  const _FeaturedGoal({required this.goal, required this.onTap});

  final SavingsGoal goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          const SavingsArt(size: 130),
          const Gap(8),
          Text(goal.name,
              style: AppTextStyles.headlineSmall, textAlign: TextAlign.center),
          const Gap(14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Money.format(goal.savedMinor, goal.currency),
                style: AppTextStyles.headlineLarge,
              ),
              const Gap(6),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '/ ${Money.format(goal.targetMinor, goal.currency)}',
                  style: AppTextStyles.bodySmall,
                ),
              ),
              const Spacer(),
              Text(
                '${goal.percent}%',
                style: AppTextStyles.titleLarge
                    .copyWith(color: AppColors.primary),
              ),
            ],
          ),
          const Gap(10),
          ProgressBar(
            value: goal.progress,
            color: goal.isTargetReached ? AppColors.success : AppColors.primary,
            height: 10,
          ),
          if (goal.targetDate != null) ...[
            const Gap(12),
            Row(
              children: [
                Text('Target Date', style: AppTextStyles.bodySmall),
                const Spacer(),
                Text(AppDateUtils.formatDay(goal.targetDate!),
                    style: AppTextStyles.labelLarge),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.goal, required this.onTap});

  final SavingsGoal goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = goal.isCompleted ? AppColors.success : AppColors.honey;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(36),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                goal.isCompleted
                    ? Icons.emoji_events_rounded
                    : Icons.savings_rounded,
                color: goal.isCompleted ? AppColors.success : AppColors.warning,
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(goal.name,
                            style: AppTextStyles.titleMedium,
                            overflow: TextOverflow.ellipsis),
                      ),
                      Text('${goal.percent}%',
                          style: AppTextStyles.labelLarge),
                    ],
                  ),
                  const Gap(6),
                  ProgressBar(value: goal.progress, color: color, height: 6),
                  const Gap(4),
                  Text(
                    '${Money.format(goal.savedMinor, goal.currency)} of ${Money.format(goal.targetMinor, goal.currency)}',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
