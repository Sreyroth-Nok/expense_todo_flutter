import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/money.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/spending_limit.dart';
import '../domain/spending_limit_providers.dart';
import 'limit_alert_messages.dart';

/// Create or edit the daily / monthly limit.
class SpendingLimitFormScreen extends ConsumerWidget {
  const SpendingLimitFormScreen({super.key, required this.period});

  final LimitPeriod period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final limitsAsync = ref.watch(spendingLimitsProvider);
    final currency = ref.watch(currentUserProfileProvider).value?.currency ??
        AppConstants.defaultCurrency;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(period.label),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: limitsAsync.when(
          loading: () => const LoadingState(),
          error: (e, _) => Center(child: ErrorState(error: e)),
          data: (limits) => _LimitForm(
            period: period,
            existing: limits[period],
            defaultCurrency: currency,
          ),
        ),
      ),
    );
  }
}

class _LimitForm extends ConsumerStatefulWidget {
  const _LimitForm({
    required this.period,
    required this.existing,
    required this.defaultCurrency,
  });

  final LimitPeriod period;
  final SpendingLimit? existing;
  final String defaultCurrency;

  @override
  ConsumerState<_LimitForm> createState() => _LimitFormState();
}

class _LimitFormState extends ConsumerState<_LimitForm> {
  static const _thresholdOptions = <int?>[null, 50, 75, 80, 90];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late String _currency;
  late bool _alertsEnabled;
  late int? _threshold;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final l = widget.existing;
    _currency = l?.currency ?? widget.defaultCurrency;
    _alertsEnabled = l?.alertsEnabled ?? true;
    _threshold = l == null ? 80 : l.warningThresholdPercent;
    _amount = TextEditingController(
      text: l == null ? '' : Money.toInputText(l.amountMinor, l.currency),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  /// Ask for notification permission at the moment it is needed.
  Future<void> _onAlertsChanged(bool enabled) async {
    setState(() => _alertsEnabled = enabled);
    if (!enabled) return;
    final granted =
        await ref.read(notificationServiceProvider).requestPermission();
    if (!granted && mounted) {
      AppSnackBar.info(
        context,
        'Notifications are blocked for LifeMate. You will still see alerts '
        'inside the app. You can allow notifications in system settings.',
      );
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final limit = SpendingLimit(
      period: widget.period,
      amountMinor: Money.parseToMinor(_amount.text, _currency)!,
      currency: _currency,
      alertsEnabled: _alertsEnabled,
      warningThresholdPercent: _threshold,
    );

    setState(() => _saving = true);
    try {
      final alerts = await ref
          .read(spendingLimitServiceProvider)
          .save(limit, isNew: widget.existing == null);
      if (!mounted) return;
      AppSnackBar.success(context, '${widget.period.label} saved.');
      showLimitAlerts(context, alerts);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.error(context, readableError(e));
    }
  }

  Future<void> _delete() async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Remove ${widget.period.label.toLowerCase()}?',
      message: 'Your expenses are not affected. You can set a new limit later.',
      confirmLabel: 'Remove',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await ref.read(spendingLimitServiceProvider).delete(widget.period);
      if (!mounted) return;
      AppSnackBar.success(context, '${widget.period.label} removed.');
      context.pop();
    } catch (e) {
      if (mounted) AppSnackBar.error(context, readableError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final perText = widget.period == LimitPeriod.daily ? 'per day' : 'per month';

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          Text(
            widget.period == LimitPeriod.daily
                ? 'How much do you want to spend at most each day?'
                : 'How much do you want to spend at most each month?',
            style: AppTextStyles.bodyLarge,
          ),
          const Gap(16),
          AmountCurrencyField(
            label: 'Limit $perText',
            controller: _amount,
            currency: _currency,
            onCurrencyChanged: (c) => setState(() => _currency = c),
          ),
          const Gap(6),
          Text(
            'Only expenses in $_currency count toward this limit.',
            style: AppTextStyles.bodySmall,
          ),
          const Gap(24),

          Text('Early warning', style: AppTextStyles.titleMedium),
          const Gap(4),
          Text(
            'Get a warning before you reach the limit.',
            style: AppTextStyles.bodySmall,
          ),
          const Gap(10),
          AppChoiceChips<int?>(
            options: _thresholdOptions,
            selected: _threshold,
            labelOf: (t) => t == null ? 'Off' : '$t%',
            onSelected: (t) => setState(() => _threshold = t),
          ),
          const Gap(20),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _alertsEnabled,
            activeThumbColor: AppColors.primary,
            onChanged: _onAlertsChanged,
            title: Text('Alerts', style: AppTextStyles.titleMedium),
            subtitle: Text(
              'Notify me when I hit the warning, reach or go over the limit.',
              style: AppTextStyles.bodySmall,
            ),
          ),
          const Gap(28),

          AppPrimaryButton(
            label: 'Save limit',
            icon: Icons.check_rounded,
            isLoading: _saving,
            onPressed: _save,
          ),
          if (widget.existing != null) ...[
            const Gap(12),
            TextButton.icon(
              onPressed: _saving ? null : _delete,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('Remove limit'),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
            ),
          ],
        ],
      ),
    );
  }
}
