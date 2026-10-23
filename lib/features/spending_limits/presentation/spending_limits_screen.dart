import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_states.dart';
import '../domain/spending_limit.dart';
import '../domain/spending_limit_providers.dart';
import 'widgets/limit_progress_card.dart';

/// Overview of the daily and monthly spending limits.
class SpendingLimitsScreen extends ConsumerWidget {
  const SpendingLimitsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusesAsync = ref.watch(limitStatusesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Spending limits')),
      body: statusesAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => Center(child: ErrorState(error: e)),
        data: (statuses) => ListView(
          padding: const EdgeInsets.all(20),
          children: [
            for (final period in LimitPeriod.values) ...[
              if (statuses[period] case final status?)
                LimitProgressCard(
                  status: status,
                  onTap: () => context.push(AppRoutes.editLimit(period.name)),
                )
              else
                SetLimitCard(period: period),
              const Gap(16),
            ],
            const Gap(8),
            const _HowItWorks(),
          ],
        ),
      ),
    );
  }
}

/// Call-to-action shown when a limit has not been configured.
class SetLimitCard extends StatelessWidget {
  const SetLimitCard({super.key, required this.period});

  final LimitPeriod period;

  @override
  Widget build(BuildContext context) {
    final example = period == LimitPeriod.daily ? r'$5' : r'$50';
    return AppCard(
      onTap: () => context.push(AppRoutes.editLimit(period.name)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.softTeal,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              period == LimitPeriod.daily
                  ? Icons.today_rounded
                  : Icons.calendar_month_rounded,
              color: AppColors.primary,
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Set a ${period.label.toLowerCase()}',
                    style: AppTextStyles.titleMedium),
                const Gap(2),
                Text(
                  'e.g. $example per ${period == LimitPeriod.daily ? 'day' : 'month'}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          const Icon(Icons.add_circle_outline_rounded,
              color: AppColors.primary),
        ],
      ),
    );
  }
}

class _HowItWorks extends StatelessWidget {
  const _HowItWorks();

  @override
  Widget build(BuildContext context) {
    const points = [
      'Only expenses count. Income never reduces your limit.',
      'Daily limits reset at local midnight; monthly limits on the 1st.',
      'Only expenses in the limit\'s currency are counted.',
      'You can always record an expense, even over the limit.',
      'With alerts on, you get one notification per new level '
          '(warning, reached, exceeded) per period.',
    ];
    return AppCard(
      color: AppColors.surfaceVariant,
      borderColor: AppColors.divider,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How limits work', style: AppTextStyles.titleMedium),
          const Gap(8),
          for (final p in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('•  '),
                  Expanded(child: Text(p, style: AppTextStyles.bodySmall)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
