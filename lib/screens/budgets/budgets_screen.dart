import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../routing/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/clock_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_states.dart';
import '../../models/budget.dart';
import '../../providers/budget_providers.dart';
import '../../widgets/budget_hero_card.dart';
import '../../widgets/budget_progress_card.dart';

/// Budgets: the current budget in a large card with its categories, then
/// other active, upcoming and past budgets.
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Budgets')),
      bottomNavigationBar: budgetsAsync.value?.isNotEmpty ?? false
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: AppPrimaryButton(
                label: 'Create Budget',
                icon: Icons.add_rounded,
                onPressed: () => context.push(AppRoutes.newBudget),
              ),
            )
          : null,
      body: budgetsAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => Center(child: ErrorState(error: e)),
        data: (budgets) {
          if (budgets.isEmpty) {
            return Center(
              child: SingleChildScrollView(
                child: EmptyState(
                  icon: Icons.pie_chart_rounded,
                  title: 'No budgets yet',
                  message: 'Plan how much to spend in a period, and split it '
                      'across categories like food or transport.',
                  actionLabel: 'Create Budget',
                  onAction: () => context.push(AppRoutes.newBudget),
                ),
              ),
            );
          }
          final active = budgets.where((b) => b.isActiveAt(now)).toList();
          final upcoming = budgets.where((b) => b.isUpcomingAt(now)).toList();
          final past = budgets.where((b) => b.isPastAt(now)).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              if (active.isNotEmpty) ...[
                BudgetHeroCard(
                  budget: active.first,
                  onTap: () =>
                      context.push(AppRoutes.budgetDetail(active.first.id)),
                ),
                const Gap(12),
              ],
              for (final (title, list) in [
                ('Also active', active.skip(1).toList()),
                ('Upcoming', upcoming),
                ('Past', past),
              ])
                if (list.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 8),
                    child: Text(title, style: AppTextStyles.labelMedium),
                  ),
                  for (final Budget b in list) ...[
                    BudgetProgressCard(
                      budget: b,
                      onTap: () => context.push(AppRoutes.budgetDetail(b.id)),
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
