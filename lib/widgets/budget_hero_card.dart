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
import '../providers/transaction_providers.dart';
import 'category_visuals.dart';
import '../models/budget.dart';
import '../providers/budget_providers.dart';

/// Large budget card: total, spent, percent, then one row per category
/// allocation with a honey progress bar (as in the design).
class BudgetHeroCard extends ConsumerWidget {
  const BudgetHeroCard({super.key, required this.budget, this.onTap});

  final Budget budget;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(budgetStatusProvider(budget));
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final byId = {for (final c in categories) c.id: c};
    final s = statusAsync.value;
    final percent = s == null ? 0 : (s.progress * 100).round();

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${budget.name} · ${AppDateUtils.formatShortDay(budget.range.start)} – ${AppDateUtils.formatShortDay(budget.endDate)}',
            style: AppTextStyles.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
          const Gap(4),
          Text(
            Money.format(budget.totalMinor, budget.currency),
            style: AppTextStyles.displayMedium.copyWith(fontSize: 30),
          ),
          const Gap(10),
          Row(
            children: [
              Expanded(
                child: Text(
                  s == null
                      ? '…'
                      : '${Money.format(s.spentMinor, budget.currency)} spent',
                  style: AppTextStyles.bodyMedium,
                ),
              ),
              Text(
                '$percent%',
                style: AppTextStyles.titleMedium.copyWith(
                  color: s?.level.color ?? AppColors.primary,
                ),
              ),
            ],
          ),
          const Gap(8),
          ProgressBar(
            value: s?.progress ?? 0,
            color: s?.level.barColor ?? AppColors.primary,
            height: 10,
          ),
          if (s != null && s.allocationStatuses.isNotEmpty) ...[
            const Gap(18),
            const Divider(),
            for (final a in s.allocationStatuses) ...[
              const Gap(14),
              Row(
                children: [
                  CategoryIconBadge(
                    iconKey: byId[a.categoryId]?.iconKey ?? 'other',
                    colorValue: byId[a.categoryId]?.colorValue ?? 0xFF6B7280,
                    size: 36,
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                byId[a.categoryId]?.name ?? 'Deleted category',
                                style: AppTextStyles.titleMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              '${Money.format(a.spentMinor, budget.currency)} / ${Money.format(a.allocatedMinor, budget.currency)}',
                              style: AppTextStyles.labelMedium,
                            ),
                          ],
                        ),
                        const Gap(6),
                        Row(
                          children: [
                            Expanded(
                              child: ProgressBar(
                                value: a.progress,
                                color: a.level == LimitLevel.ok
                                    ? AppColors.honey
                                    : a.level.barColor,
                                height: 6,
                              ),
                            ),
                            const Gap(8),
                            SizedBox(
                              width: 38,
                              child: Text(
                                '${(a.progress * 100).round()}%',
                                textAlign: TextAlign.end,
                                style: AppTextStyles.labelSmall
                                    .copyWith(color: a.level.color),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}
