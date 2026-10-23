import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../auth/data/auth_repository.dart';
import '../data/savings_repository.dart';
import '../domain/savings_goal.dart';
import '../domain/savings_providers.dart';

/// Create a savings goal, or edit one when [goalId] is given.
class SavingsGoalFormScreen extends ConsumerWidget {
  const SavingsGoalFormScreen({super.key, this.goalId});

  final String? goalId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currentUserProfileProvider).value?.currency ??
        AppConstants.defaultCurrency;
    final existing = goalId == null
        ? const AsyncValue<SavingsGoal?>.data(null)
        : ref.watch(savingsGoalByIdProvider(goalId!));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(goalId == null ? 'New savings goal' : 'Edit goal'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: existing.when(
          loading: () => const LoadingState(),
          error: (e, _) => Center(child: ErrorState(error: e)),
          data: (goal) => goalId != null && goal == null
              ? const Center(
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Goal not found',
                    message: 'It may have been deleted.',
                  ),
                )
              : _GoalForm(existing: goal, defaultCurrency: currency),
        ),
      ),
    );
  }
}

class _GoalForm extends ConsumerStatefulWidget {
  const _GoalForm({required this.existing, required this.defaultCurrency});

  final SavingsGoal? existing;
  final String defaultCurrency;

  @override
  ConsumerState<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends ConsumerState<_GoalForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late final _target = TextEditingController(
    text: widget.existing == null
        ? ''
        : Money.toInputText(
            widget.existing!.targetMinor, widget.existing!.currency),
  );
  final _starting = TextEditingController();
  late String _currency = widget.existing?.currency ?? widget.defaultCurrency;
  late DateTime? _targetDate = widget.existing?.targetDate;
  late int? _reminderDay = widget.existing?.reminderDayOfMonth;
  bool _saving = false;

  bool get _isNew => widget.existing == null;

  @override
  void dispose() {
    _name.dispose();
    _target.dispose();
    _starting.dispose();
    super.dispose();
  }

  Future<void> _pickTargetDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _targetDate ?? DateTime(now.year, now.month + 3, now.day),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 30),
    );
    if (picked != null) setState(() => _targetDate = picked);
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    final goal = SavingsGoal(
      id: widget.existing?.id ?? '',
      name: _name.text.trim(),
      currency: _currency,
      targetMinor: Money.parseToMinor(_target.text, _currency)!,
      savedMinor: widget.existing?.savedMinor ?? 0,
      targetDate: _targetDate,
      isCompleted: widget.existing?.isCompleted ?? false,
      reminderDayOfMonth: _reminderDay,
    );

    setState(() => _saving = true);
    try {
      if (_reminderDay != null) {
        final granted =
            await ref.read(notificationServiceProvider).requestPermission();
        if (!granted && mounted) {
          AppSnackBar.info(context,
              'Notifications are blocked, so the monthly reminder will not pop up.');
        }
      }
      final repo = ref.read(savingsRepositoryProvider);
      if (_isNew) {
        await repo.create(
          uid,
          goal,
          startingAmountMinor: _starting.text.trim().isEmpty
              ? 0
              : Money.parseToMinor(_starting.text, _currency)!,
        );
      } else {
        await repo.update(uid, goal);
      }
      if (!mounted) return;
      AppSnackBar.success(context, 'Goal saved.');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.error(context, readableError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          AppTextField(
            label: 'Goal name',
            hint: 'e.g. Emergency fund',
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            validator: (v) {
              final r = AppValidators.required(v, fieldName: 'Name');
              if (r != null) return r;
              return v!.trim().length > 40 ? 'Use 40 characters or fewer.' : null;
            },
          ),
          const Gap(16),
          if (_isNew)
            AmountCurrencyField(
              label: 'Target amount',
              controller: _target,
              currency: _currency,
              onCurrencyChanged: (c) => setState(() => _currency = c),
            )
          else ...[
            // Currency is fixed once money has been recorded in it.
            AppTextField(
              label: 'Target amount ($_currency)',
              controller: _target,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: AppValidators.amount(_currency),
              prefixIcon: const Icon(Icons.flag_outlined),
            ),
          ],
          if (_isNew) ...[
            const Gap(16),
            AppTextField(
              label: 'Already saved (optional)',
              hint: '0',
              controller: _starting,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) => v == null || v.trim().isEmpty
                  ? null
                  : AppValidators.amount(_currency)(v),
              prefixIcon: const Icon(Icons.savings_outlined),
            ),
          ],
          const Gap(16),
          Row(
            children: [
              Expanded(
                child: PickerField(
                  label: 'Target date (optional)',
                  value: _targetDate == null
                      ? 'No date'
                      : AppDateUtils.formatDay(_targetDate!),
                  icon: Icons.event_outlined,
                  onTap: _pickTargetDate,
                ),
              ),
              if (_targetDate != null)
                IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  tooltip: 'Clear date',
                  onPressed: () => setState(() => _targetDate = null),
                ),
            ],
          ),
          const Gap(20),
          const FormSectionLabel('Monthly reminder (optional)',
              hint: 'A notification at 9:00 AM on this day of each month.'),
          AppChoiceChips<int?>(
            options: const [null, 1, 5, 10, 15, 20, 25, 28],
            selected: _reminderDay,
            labelOf: (d) => d == null ? 'Off' : 'Day $d',
            onSelected: (d) => setState(() => _reminderDay = d),
          ),
          const Gap(28),
          AppPrimaryButton(
            label: 'Save goal',
            icon: Icons.check_rounded,
            isLoading: _saving,
            onPressed: _save,
          ),
          if (!_isNew) ...[
            const Gap(12),
            Text(
              'To change the saved amount, use "Add money" or "Withdraw" on '
              'the goal screen so your history stays correct.',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}
