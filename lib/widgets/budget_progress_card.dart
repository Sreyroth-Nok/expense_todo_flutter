import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/date_utils.dart';
import '../utils/money.dart';
import 'app_card.dart';
import 'progress_bar.dart';
import '../models/spending_limit.dart';
import 'limit_progress_card.dart';
import '../models/budget.dart';
import '../providers/budget_providers.dart';

/// Compact card: budget name, period, spent of total, remaining, status.
/// Loads its own live status.
class BudgetProgressCard extends ConsumerWidget {
  const BudgetProgressCard({super.key, required this.budget, this.onTap});

  final Budget budget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(budgetStatusProvider(budget));
    final period =
        '${AppDateUtils.formatShortDay(budget.range.start)} – ${AppDateUtils.formatShortDay(budget.endDate)}';

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.pie_chart_rounded,
                  color: AppColors.primary, size: 20),
              const Gap(8),
              Expanded(
                child: Text(budget.name,
                    style: AppTextStyles.titleMedium,
                    overflow: TextOverflow.ellipsis),
              ),
              if (statusAsync.value case final s?)
                AppBadge(
                  label: s.level == LimitLevel.ok ? 'On track' : s.level.label,
                  color: s.level.color,
                ),
            ],
          ),
          const Gap(2),
          Text(period, style: AppTextStyles.bodySmall),
          const Gap(10),
          statusAsync.when(
            loading: () => const ProgressBar(value: 0),
            error: (e, _) => Text('Could not load spending.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.error)),
            data: (s) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${Money.format(s.spentMinor, budget.currency)} of ${Money.format(budget.totalMinor, budget.currency)}',
                  style: AppTextStyles.titleLarge.copyWith(
                    color: s.level == LimitLevel.exceeded
                        ? AppColors.error
                        : AppColors.textPrimary,
                  ),
                ),
                const Gap(8),
                ProgressBar(value: s.progress, color: s.level.barColor),
                const Gap(6),
                Text(
                  s.remainingMinor >= 0
                      ? '${Money.format(s.remainingMinor, budget.currency)} left'
                      : 'Over by ${Money.format(-s.remainingMinor, budget.currency)}',
                  style:
                      AppTextStyles.labelLarge.copyWith(color: s.level.color),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
