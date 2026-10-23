import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_states.dart';
import '../domain/savings_providers.dart';
import 'widgets/savings_goal_card.dart';

/// All savings goals: in progress first, then completed.
class SavingsGoalsScreen extends ConsumerWidget {
  const SavingsGoalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(savingsGoalsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Savings goals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.newSavingsGoal),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New goal'),
      ),
      body: goalsAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => Center(child: ErrorState(error: e)),
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.savings_outlined,
                title: 'No savings goals yet',
                message: 'Set a target, like a new phone or an emergency '
                    'fund, and record money as you put it aside.',
                actionLabel: 'Create a goal',
                onAction: () => context.push(AppRoutes.newSavingsGoal),
              ),
            );
          }
          final active = goals.where((g) => !g.isCompleted).toList();
          final done = goals.where((g) => g.isCompleted).toList();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
            children: [
              for (final g in active) ...[
                SavingsGoalCard(
                  goal: g,
                  onTap: () => context.push(AppRoutes.savingsGoalDetail(g.id)),
                ),
                const Gap(12),
              ],
              if (done.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  child: Text('Completed', style: AppTextStyles.labelMedium),
                ),
                for (final g in done) ...[
                  SavingsGoalCard(
                    goal: g,
                    onTap: () =>
                        context.push(AppRoutes.savingsGoalDetail(g.id)),
                  ),
                  const Gap(12),
                ],
              ],
            ],
          );
        },
      ),
    );
  }
}
