import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/clock_provider.dart';
import '../../../shared/widgets/app_states.dart';
import '../domain/budget.dart';
import '../domain/budget_providers.dart';
import 'widgets/budget_progress_card.dart';

/// Budgets grouped into Active, Upcoming and Past.
class BudgetsScreen extends ConsumerWidget {
  const BudgetsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetsAsync = ref.watch(budgetsProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Budgets')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.newBudget),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New budget'),
      ),
      body: budgetsAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => Center(child: ErrorState(error: e)),
        data: (budgets) {
          if (budgets.isEmpty) {
            return Center(
              child: EmptyState(
                icon: Icons.pie_chart_outline_rounded,
                title: 'No budgets yet',
                message: 'Plan how much to spend in a period, and split it '
                    'across categories like food or transport.',
                actionLabel: 'Create a budget',
                onAction: () => context.push(AppRoutes.newBudget),
              ),
            );
          }
          final active = budgets.where((b) => b.isActiveAt(now)).toList();
          final upcoming = budgets.where((b) => b.isUpcomingAt(now)).toList();
          final past = budgets.where((b) => b.isPastAt(now)).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
            children: [
              for (final (title, list) in [
                ('Active', active),
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
