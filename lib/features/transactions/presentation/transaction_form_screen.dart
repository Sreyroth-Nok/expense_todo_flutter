import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../../shared/widgets/app_states.dart';
import '../../auth/data/auth_repository.dart';
import '../../spending_limits/presentation/limit_alert_messages.dart';
import '../domain/finance_transaction.dart';
import '../domain/transaction_providers.dart';
import 'widgets/transaction_form.dart';

/// Add a new transaction, or edit one when [transactionId] is given.
class TransactionFormScreen extends ConsumerStatefulWidget {
  const TransactionFormScreen({
    super.key,
    this.transactionId,
    this.initialType = TransactionType.expense,
  });

  final String? transactionId;
  final TransactionType initialType;

  bool get isEditing => transactionId != null;

  @override
  ConsumerState<TransactionFormScreen> createState() =>
      _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  bool _saving = false;

  Future<void> _save(FinanceTransaction tx) async {
    setState(() => _saving = true);
    final service = ref.read(transactionServiceProvider);
    try {
      final alerts =
          widget.isEditing ? await service.update(tx) : await service.add(tx);
      if (!mounted) return;
      showLimitAlerts(context, alerts);
      if (widget.isEditing) {
        AppSnackBar.success(context, 'Transaction updated.');
        context.pop();
      } else {
        // New transaction → the "Transaction Added!" confirmation screen.
        context.pushReplacement(AppRoutes.transactionSuccessOf(tx.type.name));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.error(context, readableError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final currency = ref.watch(currentUserProfileProvider).value?.currency ??
        AppConstants.defaultCurrency;
    final existingAsync = widget.isEditing
        ? ref.watch(transactionByIdProvider(widget.transactionId!))
        : const AsyncValue<FinanceTransaction?>.data(null);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit transaction' : 'New transaction'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: switch ((categoriesAsync, existingAsync)) {
          (AsyncError(:final error), _) || (_, AsyncError(:final error)) =>
            Center(child: ErrorState(error: error)),
          (AsyncData(value: final categories), AsyncData(value: final existing)) =>
            widget.isEditing && existing == null
                ? const Center(
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Transaction not found',
                      message: 'It may have been deleted.',
                    ),
                  )
                : TransactionForm(
                    initial: existing,
                    initialType: widget.initialType,
                    categories: categories,
                    defaultCurrency: currency,
                    isSaving: _saving,
                    onSubmit: _save,
                    onManageCategories: () =>
                        context.push(AppRoutes.categories),
                  ),
          _ => const LoadingState(),
        },
      ),
    );
  }
}
