import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/money.dart';
import '../../domain/finance_transaction.dart';
import '../../domain/transaction_category.dart';
import 'category_visuals.dart';

/// One row in a transaction list.
///
/// Income is shown in green with "+", expenses in red with "-".
class TransactionTile extends StatelessWidget {
  const TransactionTile({
    super.key,
    required this.transaction,
    this.category,
    this.onTap,
    this.showDate = false,
  });

  final FinanceTransaction transaction;

  /// Current category (for icon / color). May be null if it was deleted.
  final TransactionCategory? category;
  final VoidCallback? onTap;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    final tx = transaction;
    final subtitle = [
      if (tx.description.isNotEmpty) tx.description,
      showDate
          ? '${AppDateUtils.formatShortDay(tx.date)} · ${AppDateUtils.formatTime(tx.date)}'
          : AppDateUtils.formatTime(tx.date),
    ].join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            CategoryIconBadge(
              iconKey: category?.iconKey ?? 'other',
              colorValue: category?.colorValue ?? 0xFF6B7280,
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category?.name ?? tx.categoryName,
                    style: AppTextStyles.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Gap(2),
                  Text(
                    subtitle,
                    style: AppTextStyles.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Gap(8),
            Text(
              Money.format(tx.signedAmountMinor, tx.currency, signed: true),
              style: AppTextStyles.titleMedium.copyWith(
                color: tx.isIncome ? AppColors.success : AppColors.error,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
