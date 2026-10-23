import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/data/auth_repository.dart';
import '../data/savings_repository.dart';
import '../domain/savings_goal.dart';
import '../domain/savings_providers.dart';
import 'widgets/savings_goal_card.dart';

/// One goal with deposit / withdraw actions and contribution history.
class SavingsGoalDetailScreen extends ConsumerWidget {
  const SavingsGoalDetailScreen({super.key, required this.goalId});

  final String goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalAsync = ref.watch(savingsGoalByIdProvider(goalId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Savings goal'),
        actions: [
          if (goalAsync.value case final g?) ...[
            IconButton(
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Edit',
              onPressed: () => context.push(AppRoutes.editSavingsGoal(g.id)),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete',
              onPressed: () => _deleteGoal(context, ref, g),
            ),
          ],
        ],
      ),
      body: goalAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => Center(child: ErrorState(error: e)),
        data: (goal) => goal == null
            ? const Center(
                child: EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Goal not found',
                  message: 'It may have been deleted.',
                ),
              )
            : _GoalBody(goal: goal),
      ),
    );
  }

  Future<void> _deleteGoal(
      BuildContext context, WidgetRef ref, SavingsGoal g) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete "${g.name}"?',
      message: 'The goal and its contribution history will be removed. '
          'This does not change any transactions.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    final uid = ref.read(currentUidProvider);
    if (!ok || uid == null || !context.mounted) return;
    try {
      await ref.read(savingsRepositoryProvider).delete(uid, g.id);
      if (!context.mounted) return;
      AppSnackBar.success(context, 'Goal deleted.');
      context.pop();
    } catch (e) {
      if (context.mounted) AppSnackBar.error(context, readableError(e));
    }
  }
}

class _GoalBody extends ConsumerWidget {
  const _GoalBody({required this.goal});

  final SavingsGoal goal;

  Future<void> _contribute(
      BuildContext context, WidgetRef ref, bool withdraw) async {
    final result = await showModalBottomSheet<(int, String)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (_) => _ContributionSheet(goal: goal, withdraw: withdraw),
    );
    final uid = ref.read(currentUidProvider);
    if (result == null || uid == null || !context.mounted) return;
    final (amount, note) = result;
    try {
      await ref.read(savingsRepositoryProvider).addContribution(
            uid,
            goal.id,
            amountMinor: withdraw ? -amount : amount,
            note: note,
          );
      if (context.mounted) {
        AppSnackBar.success(
            context, withdraw ? 'Withdrawal recorded.' : 'Deposit recorded.');
      }
    } catch (e) {
      if (context.mounted) AppSnackBar.error(context, readableError(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contributions = ref.watch(contributionsProvider(goal.id));
    final uid = ref.watch(currentUidProvider);
    final repo = ref.read(savingsRepositoryProvider);

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        SavingsGoalCard(goal: goal),
        const Gap(16),
        Row(
          children: [
            Expanded(
              child: AppPrimaryButton(
                label: 'Add money',
                icon: Icons.add_rounded,
                onPressed: () => _contribute(context, ref, false),
              ),
            ),
            const Gap(12),
            Expanded(
              child: AppOutlinedButton(
                label: 'Withdraw',
                icon: Icons.remove_rounded,
                onPressed: goal.savedMinor == 0
                    ? null
                    : () => _contribute(context, ref, true),
              ),
            ),
          ],
        ),
        const Gap(8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: goal.isCompleted,
          activeThumbColor: AppColors.primary,
          title: Text('Mark as completed', style: AppTextStyles.titleMedium),
          subtitle: Text(
            goal.isTargetReached
                ? 'You reached the target — nice work!'
                : 'You can complete a goal before reaching the target.',
            style: AppTextStyles.bodySmall,
          ),
          onChanged: uid == null
              ? null
              : (v) async {
                  try {
                    await repo.setCompleted(uid, goal.id, v);
                  } catch (e) {
                    if (context.mounted) {
                      AppSnackBar.error(context, readableError(e));
                    }
                  }
                },
        ),
        const Gap(16),
        Text('History', style: AppTextStyles.titleLarge),
        const Gap(8),
        contributions.when(
          loading: () => const LoadingState(),
          error: (e, _) => ErrorState(error: e),
          data: (list) => list.isEmpty
              ? Text('No deposits yet.', style: AppTextStyles.bodySmall)
              : AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      for (final c in list)
                        ListTile(
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          title: Text(
                            Money.format(c.amountMinor, goal.currency,
                                signed: true),
                            style: AppTextStyles.titleMedium.copyWith(
                              color: c.isWithdrawal
                                  ? AppColors.textPrimary
                                  : AppColors.success,
                            ),
                          ),
                          subtitle: Text(
                            [
                              AppDateUtils.formatDay(c.date),
                              if (c.note.isNotEmpty) c.note,
                            ].join(' · '),
                            style: AppTextStyles.bodySmall,
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline_rounded),
                            color: AppColors.textSecondary,
                            tooltip: 'Remove',
                            onPressed: uid == null
                                ? null
                                : () async {
                                    final ok = await showConfirmDialog(
                                      context,
                                      title: 'Remove this entry?',
                                      message:
                                          'The saved amount will be adjusted.',
                                      confirmLabel: 'Remove',
                                      destructive: true,
                                    );
                                    if (!ok) return;
                                    try {
                                      await repo.deleteContribution(
                                          uid, goal.id, c.id);
                                    } catch (e) {
                                      if (context.mounted) {
                                        AppSnackBar.error(
                                            context, readableError(e));
                                      }
                                    }
                                  },
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// Bottom sheet that returns (amountMinor, note).
class _ContributionSheet extends StatefulWidget {
  const _ContributionSheet({required this.goal, required this.withdraw});

  final SavingsGoal goal;
  final bool withdraw;

  @override
  State<_ContributionSheet> createState() => _ContributionSheetState();
}

class _ContributionSheetState extends State<_ContributionSheet> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _note = TextEditingController();

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currency = widget.goal.currency;
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.withdraw ? 'Withdraw money' : 'Add money',
                style: AppTextStyles.headlineSmall),
            const Gap(16),
            AppTextField(
              label: 'Amount ($currency)',
              controller: _amount,
              autofocus: true,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                final base = AppValidators.amount(currency)(v);
                if (base != null) return base;
                if (widget.withdraw &&
                    Money.parseToMinor(v!, currency)! > widget.goal.savedMinor) {
                  return 'Only ${Money.format(widget.goal.savedMinor, currency)} is saved.';
                }
                return null;
              },
            ),
            const Gap(12),
            AppTextField(
              label: 'Note (optional)',
              controller: _note,
              validator: (v) =>
                  (v?.length ?? 0) > 100 ? 'Use 100 characters or fewer.' : null,
            ),
            const Gap(20),
            AppPrimaryButton(
              label: 'Save',
              onPressed: () {
                if (!(_formKey.currentState?.validate() ?? false)) return;
                Navigator.of(context).pop((
                  Money.parseToMinor(_amount.text, currency)!,
                  _note.text.trim(),
                ));
              },
            ),
          ],
        ),
      ),
    );
  }
}
