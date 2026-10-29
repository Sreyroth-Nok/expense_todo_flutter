import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../../shared/widgets/app_states.dart';
import '../../auth/data/auth_repository.dart';
import '../data/budget_repository.dart';
import '../domain/budget.dart';
import '../domain/budget_providers.dart';
import 'widgets/budget_hero_card.dart';

/// One budget: overall progress and spending per category.
class BudgetDetailScreen extends ConsumerWidget {
  const BudgetDetailScreen({super.key, required this.budgetId});

  final String budgetId;

  Future<void> _delete(BuildContext context, WidgetRef ref, Budget b) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete "${b.name}"?',
      message: 'Only the budget is removed. Your transactions are not affected.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    final uid = ref.read(currentUidProvider);
    if (!ok || uid == null || !context.mounted) return;
    try {
      await ref.read(budgetRepositoryProvider).delete(uid, b.id);
      if (!context.mounted) return;
      AppSnackBar.success(context, 'Budget deleted.');
      context.pop();
    } catch (e) {
      if (context.mounted) AppSnackBar.error(context, readableError(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgetAsync = ref.watch(budgetByIdProvider(budgetId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Budget'),
        actions: [
          if (budgetAsync.value case final b?) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () => context.push(AppRoutes.editBudget(b.id)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete',
              onPressed: () => _delete(context, ref, b),
            ),
          ],
        ],
      ),
      body: budgetAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => Center(child: ErrorState(error: e)),
        data: (budget) => budget == null
            ? const Center(
                child: EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Budget not found',
                  message: 'It may have been deleted.',
                ),
              )
            : _BudgetBody(budget: budget),
      ),
    );
  }
}

class _BudgetBody extends ConsumerWidget {
  const _BudgetBody({required this.budget});

  final Budget budget;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(budgetStatusProvider(budget));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        BudgetHeroCard(budget: budget),
        const Gap(24),
        Text('Other spending', style: AppTextStyles.titleLarge),
        const Gap(8),
        statusAsync.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(error: e),
          data: (s) => AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (s.allocationStatuses.isEmpty)
                  Text(
                    'No category amounts set. All spending counts toward '
                    'the total only.',
                    style: AppTextStyles.bodySmall,
                  ),
                if (s.unallocatedSpentMinor > 0) ...[
                  const Divider(),
                  const Gap(10),
                  Row(
                    children: [
                      Expanded(
                        child: Text('Other categories',
                            style: AppTextStyles.bodyMedium),
                      ),
                      Text(
                        Money.format(s.unallocatedSpentMinor, budget.currency),
                        style: AppTextStyles.labelLarge,
                      ),
                    ],
                  ),
                ],
                if (s.otherCurrencyExpenseCount > 0) ...[
                  const Gap(10),
                  Text(
                    '${s.otherCurrencyExpenseCount} expense(s) in other '
                    'currencies are not counted in this ${budget.currency} budget.',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
