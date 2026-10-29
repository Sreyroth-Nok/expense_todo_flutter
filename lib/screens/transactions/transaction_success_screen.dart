import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../routing/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_button.dart';
import '../../widgets/illustrations.dart';
import '../../models/finance_transaction.dart';

/// Shown after a new transaction is saved.
class TransactionSuccessScreen extends StatelessWidget {
  const TransactionSuccessScreen({super.key, required this.type});

  /// Type of the transaction just added ("Add Another" reuses it).
  final TransactionType type;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded),
            tooltip: l.successDone,
            onPressed: () => context.pop(),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 24),
          child: Column(
            children: [
              const Spacer(),
              const SuccessArt(size: 200)
                  .animate()
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(),
              const Gap(24),
              Text(
                l.successTransactionTitle,
                style: AppTextStyles.headlineLarge
                    .copyWith(color: AppColors.primaryDark),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
              const Gap(8),
              Text(
                l.successTransactionBody,
                style: AppTextStyles.bodyLarge
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 300.ms),
              const Spacer(),
              AppPrimaryButton(
                label: l.successViewTransactions,
                onPressed: () => context.go(AppRoutes.transactions),
              ),
              const Gap(12),
              AppOutlinedButton(
                label: l.successAddAnother,
                onPressed: () => context
                    .pushReplacement(AppRoutes.newTransactionOf(type.name)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
