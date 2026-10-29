import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../domain/spending_limit.dart';
import '../domain/spending_limit_calculator.dart';
import '../domain/spending_limit_providers.dart';
import 'limit_alert_messages.dart';
import 'widgets/limit_progress_card.dart';

/// Daily / monthly spending limits: progress, warning banner and an
/// alerts switch (as in the design).
class SpendingLimitsScreen extends ConsumerStatefulWidget {
  const SpendingLimitsScreen({super.key});

  @override
  ConsumerState<SpendingLimitsScreen> createState() =>
      _SpendingLimitsScreenState();
}

class _SpendingLimitsScreenState extends ConsumerState<SpendingLimitsScreen> {
  LimitPeriod _period = LimitPeriod.daily;
  bool _savingAlerts = false;

  Future<void> _setAlerts(LimitStatus status, bool enabled) async {
    setState(() => _savingAlerts = true);
    try {
      if (enabled) {
        await ref.read(notificationServiceProvider).requestPermission();
      }
      final alerts = await ref.read(spendingLimitServiceProvider).save(
            status.limit.copyWith(alertsEnabled: enabled),
            isNew: false,
          );
      if (mounted) showLimitAlerts(context, alerts);
    } catch (e) {
      if (mounted) AppSnackBar.error(context, readableError(e));
    } finally {
      if (mounted) setState(() => _savingAlerts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusesAsync = ref.watch(limitStatusesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Spending limits')),
      body: statusesAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => Center(child: ErrorState(error: e)),
        data: (statuses) {
          final status = statuses[_period];
          // Banner for the most severe limit that needs attention.
          LimitStatus? attention;
          for (final s in statuses.values) {
            if (s.level == LimitLevel.ok) continue;
            if (attention == null || s.level.isMoreSevereThan(attention.level)) {
              attention = s;
            }
          }

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              PillTabs<LimitPeriod>(
                options: LimitPeriod.values,
                selected: _period,
                labelOf: (p) => p == LimitPeriod.daily ? 'Daily' : 'Monthly',
                onSelected: (p) => setState(() => _period = p),
              ),
              const Gap(18),
              if (status != null)
                LimitProgressCard(
                  status: status,
                  onTap: () => context.push(AppRoutes.editLimit(_period.name)),
                )
              else
                SetLimitCard(period: _period),
              const Gap(12),
              // The other period below.
              for (final other in LimitPeriod.values.where((p) => p != _period))
                if (statuses[other] case final s?)
                  LimitProgressCard(
                    status: s,
                    onTap: () => context.push(AppRoutes.editLimit(other.name)),
                  )
                else
                  SetLimitCard(period: other),
              if (attention != null) ...[
                const Gap(16),
                _AttentionBanner(status: attention),
              ],
              if (status != null) ...[
                const Gap(16),
                AppCard(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    value: status.limit.alertsEnabled,
                    activeThumbColor: AppColors.primary,
                    title:
                        Text('Enable alerts', style: AppTextStyles.titleMedium),
                    subtitle: Text(
                      _period == LimitPeriod.daily
                          ? 'Notify me about my daily limit'
                          : 'Notify me about my monthly limit',
                      style: AppTextStyles.bodySmall,
                    ),
                    onChanged:
                        _savingAlerts ? null : (v) => _setAlerts(status, v),
                  ),
                ),
              ],
              const Gap(20),
              const _HowItWorks(),
            ],
          );
        },
      ),
    );
  }
}

/// Honey banner when a limit is close, reached or exceeded.
class _AttentionBanner extends StatelessWidget {
  const _AttentionBanner({required this.status});

  final LimitStatus status;

  @override
  Widget build(BuildContext context) {
    final name = status.limit.period == LimitPeriod.daily ? 'daily' : 'monthly';
    final currency = status.limit.currency;
    final exceeded = status.level == LimitLevel.exceeded;
    final (icon, text, color) = switch (status.level) {
      LimitLevel.exceeded => (
          Icons.error_outline_rounded,
          'You went over your $name limit by '
              '${Money.format(status.exceededByMinor, currency)}.',
          AppColors.error,
        ),
      LimitLevel.reached => (
          Icons.warning_amber_rounded,
          'You reached your $name limit. Nothing left for this period.',
          AppColors.warning,
        ),
      _ => (
          Icons.lightbulb_outline_rounded,
          "You're close to your $name limit "
              '(${Money.format(status.remainingMinor, currency)} remaining).',
          AppColors.warning,
        ),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: (exceeded ? AppColors.error : AppColors.honey).withAlpha(34),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(70)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color),
          const Gap(10),
          Expanded(child: Text(text, style: AppTextStyles.bodyMedium)),
        ],
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
