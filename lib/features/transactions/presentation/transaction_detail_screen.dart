import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../../shared/widgets/app_states.dart';
import '../../spending_limits/presentation/limit_alert_messages.dart';
import '../domain/finance_transaction.dart';
import '../domain/transaction_providers.dart';
import 'widgets/category_visuals.dart';

/// Read-only view of one transaction with Edit and Delete actions.
class TransactionDetailScreen extends ConsumerStatefulWidget {
  const TransactionDetailScreen({super.key, required this.transactionId});

  final String transactionId;

  @override
  ConsumerState<TransactionDetailScreen> createState() =>
      _TransactionDetailScreenState();
}

class _TransactionDetailScreenState
    extends ConsumerState<TransactionDetailScreen> {
  bool _deleting = false;

  Future<void> _delete(FinanceTransaction tx) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete transaction?',
      message:
          '${Money.format(tx.amountMinor, tx.currency)} · ${tx.categoryName}\n\n'
          'This cannot be undone. Your totals and spending limits will be '
          'recalculated.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;

    setState(() => _deleting = true);
    try {
      final alerts =
          await ref.read(transactionServiceProvider).delete(tx.id);
      if (!mounted) return;
      AppSnackBar.success(context, 'Transaction deleted.');
      showLimitAlerts(context, alerts);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      AppSnackBar.error(context, readableError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionByIdProvider(widget.transactionId));
    final categories = ref.watch(categoriesProvider).value ?? const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Transaction')),
      body: SafeArea(
        child: txAsync.when(
          loading: () => const LoadingState(),
          error: (e, _) => Center(child: ErrorState(error: e)),
          data: (tx) {
            if (tx == null) {
              // Happens briefly after deleting, or for an invalid link.
              return const Center(
                child: EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'Transaction not found',
                  message: 'It may have been deleted.',
                ),
              );
            }
            final category =
                categories.where((c) => c.id == tx.categoryId).firstOrNull;
            final amountColor =
                tx.isIncome ? AppColors.success : AppColors.textPrimary;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Center(
                  child: CategoryIconBadge(
                    iconKey: category?.iconKey ?? 'other',
                    colorValue: category?.colorValue ?? 0xFF6B7280,
                    size: 64,
                  ),
                ),
                const Gap(16),
                Center(
                  child: Text(
                    Money.format(tx.signedAmountMinor, tx.currency,
                        signed: true),
                    style: AppTextStyles.displayMedium
                        .copyWith(color: amountColor),
                  ),
                ),
                const Gap(8),
                Center(
                  child: AppBadge(
                    label: tx.type.label,
                    color: tx.isIncome ? AppColors.success : AppColors.primary,
                  ),
                ),
                const Gap(24),
                AppCard(
                  child: Column(
                    children: [
                      _DetailRow(
                          label: 'Category',
                          value: category?.name ?? tx.categoryName),
                      _DetailRow(
                          label: 'Date',
                          value: AppDateUtils.formatDay(tx.date)),
                      _DetailRow(
                          label: 'Time',
                          value: AppDateUtils.formatTime(tx.date)),
                      _DetailRow(label: 'Currency', value: tx.currency),
                      _DetailRow(
                        label: 'Description',
                        value: tx.description.isEmpty ? '—' : tx.description,
                      ),
                      if (tx.createdAt != null)
                        _DetailRow(
                          label: 'Created',
                          value:
                              '${AppDateUtils.formatShortDay(tx.createdAt!)}, ${AppDateUtils.formatTime(tx.createdAt!)}',
                        ),
                      if (tx.updatedAt != null &&
                          tx.updatedAt != tx.createdAt)
                        _DetailRow(
                          label: 'Last edited',
                          value:
                              '${AppDateUtils.formatShortDay(tx.updatedAt!)}, ${AppDateUtils.formatTime(tx.updatedAt!)}',
                          isLast: true,
                        ),
                    ],
                  ),
                ),
                const Gap(28),
                AppPrimaryButton(
                  label: 'Edit',
                  icon: Icons.edit_outlined,
                  onPressed: _deleting
                      ? null
                      : () => context.push(AppRoutes.editTransaction(tx.id)),
                ),
                const Gap(12),
                OutlinedButton.icon(
                  onPressed: _deleting ? null : () => _delete(tx),
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 1.5),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    this.isLast = false,
  });

  final String label;
  final String value;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppTextStyles.bodySmall),
          ),
          Expanded(child: Text(value, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
