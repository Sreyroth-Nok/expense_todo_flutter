import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_utils.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/app_card.dart';
import '../../domain/spending_limit.dart';
import '../../domain/spending_limit_calculator.dart';

/// Colors and labels for each limit level, shared by every limit widget.
extension LimitLevelStyle on LimitLevel {
  Color get color => switch (this) {
        LimitLevel.ok => AppColors.primary,
        LimitLevel.warning => AppColors.warning,
        LimitLevel.reached => AppColors.warning,
        LimitLevel.exceeded => AppColors.error,
      };

  /// Progress bar fill. Honey highlights the warning zone.
  Color get barColor => switch (this) {
        LimitLevel.ok => AppColors.primary,
        LimitLevel.warning => AppColors.honey,
        LimitLevel.reached => AppColors.warning,
        LimitLevel.exceeded => AppColors.error,
      };

  String get label => switch (this) {
        LimitLevel.ok => 'On track',
        LimitLevel.warning => 'Warning',
        LimitLevel.reached => 'Limit reached',
        LimitLevel.exceeded => 'Exceeded',
      };
}

/// Shows spending against one limit: spent, limit, remaining, status.
class LimitProgressCard extends StatelessWidget {
  const LimitProgressCard({super.key, required this.status, this.onTap});

  final LimitStatus status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final limit = status.limit;
    final level = status.level;
    final periodText = limit.period == LimitPeriod.daily
        ? 'Today'
        : AppDateUtils.formatMonth(status.range.start);

    final remainingText = switch (level) {
      LimitLevel.exceeded =>
        'Over by ${Money.format(status.exceededByMinor, limit.currency)}',
      LimitLevel.reached => '${Money.format(0, limit.currency)} left',
      _ => '${Money.format(status.remainingMinor, limit.currency)} left',
    };

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                limit.period == LimitPeriod.daily
                    ? Icons.today_rounded
                    : Icons.calendar_month_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const Gap(8),
              Expanded(
                child: Text(
                  '${limit.period.label} · $periodText',
                  style: AppTextStyles.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              AppBadge(label: level.label, color: level.color),
            ],
          ),
          const Gap(12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Money.format(status.spentMinor, limit.currency),
                style: AppTextStyles.headlineMedium.copyWith(
                  color: level == LimitLevel.exceeded
                      ? AppColors.error
                      : AppColors.textPrimary,
                ),
              ),
              const Gap(6),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(
                  'of ${Money.format(limit.amountMinor, limit.currency)}',
                  style: AppTextStyles.bodySmall,
                ),
              ),
            ],
          ),
          const Gap(10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: status.progress.clamp(0.0, 1.0),
              minHeight: 8,
              color: level.barColor,
              backgroundColor: AppColors.divider,
            ),
          ),
          const Gap(8),
          Row(
            children: [
              Expanded(
                child: Text(
                  remainingText,
                  style: AppTextStyles.labelLarge.copyWith(color: level.color),
                ),
              ),
              if (limit.warningThresholdPercent != null)
                Text(
                  'Warn at ${limit.warningThresholdPercent}%',
                  style: AppTextStyles.bodySmall,
                ),
              if (!limit.alertsEnabled) ...[
                const Gap(6),
                const Icon(Icons.notifications_off_outlined,
                    size: 16, color: AppColors.textSecondary),
              ],
            ],
          ),
          if (status.otherCurrencyExpenseCount > 0) ...[
            const Gap(8),
            Text(
              '${status.otherCurrencyExpenseCount} expense(s) in other '
              'currencies are not counted toward this ${limit.currency} limit.',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
