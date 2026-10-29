import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../utils/app_constants.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/date_utils.dart';
import '../../utils/money.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/form_fields.dart';
import '../../services/auth_repository.dart';
import '../../models/finance_transaction.dart';
import '../../models/transaction_category.dart';
import '../../providers/transaction_providers.dart';
import '../../widgets/category_visuals.dart';
import '../../services/budget_repository.dart';
import '../../models/budget.dart';
import '../../providers/budget_providers.dart';

/// Create a budget, or edit one when [budgetId] is given.
class BudgetFormScreen extends ConsumerWidget {
  const BudgetFormScreen({super.key, this.budgetId});

  final String? budgetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final currency = ref.watch(currentUserProfileProvider).value?.currency ??
        AppConstants.defaultCurrency;
    final existingAsync = budgetId == null
        ? const AsyncValue<Budget?>.data(null)
        : ref.watch(budgetByIdProvider(budgetId!));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(budgetId == null ? 'New budget' : 'Edit budget'),
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
          (AsyncData(value: final cats), AsyncData(value: final existing)) =>
            budgetId != null && existing == null
                ? const Center(
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Budget not found',
                      message: 'It may have been deleted.',
                    ),
                  )
                : _BudgetForm(
                    existing: existing,
                    defaultCurrency: currency,
                    expenseCategories: cats
                        .where((c) => c.type == TransactionType.expense)
                        .toList(),
                  ),
          _ => const LoadingState(),
        },
      ),
    );
  }
}

class _BudgetForm extends ConsumerStatefulWidget {
  const _BudgetForm({
    required this.existing,
    required this.defaultCurrency,
    required this.expenseCategories,
  });

  final Budget? existing;
  final String defaultCurrency;
  final List<TransactionCategory> expenseCategories;

  @override
  ConsumerState<_BudgetForm> createState() => _BudgetFormState();
}

class _BudgetFormState extends ConsumerState<_BudgetForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _total;
  late String _currency;
  late DateRange _range;
  late int? _threshold;

  /// categoryId → amount text field.
  final Map<String, TextEditingController> _allocations = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final b = widget.existing;
    _currency = b?.currency ?? widget.defaultCurrency;
    _name = TextEditingController(text: b?.name ?? '');
    _total = TextEditingController(
        text: b == null ? '' : Money.toInputText(b.totalMinor, b.currency));
    _range = b?.range ?? AppDateUtils.monthOf(DateTime.now());
    _threshold = b == null ? 80 : b.warningThresholdPercent;
    for (final e in (b?.allocations ?? const <String, int>{}).entries) {
      _allocations[e.key] =
          TextEditingController(text: Money.toInputText(e.value, b!.currency));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _total.dispose();
    for (final c in _allocations.values) {
      c.dispose();
    }
    super.dispose();
  }

  DateTime get _lastDay => _range.end.subtract(const Duration(days: 1));

  Future<void> _pickRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 5),
      initialDateRange: DateTimeRange(start: _range.start, end: _lastDay),
    );
    if (picked == null) return;
    setState(() {
      _range = DateRange(
        AppDateUtils.dayOf(picked.start).start,
        AppDateUtils.dayOf(picked.end).end,
      );
    });
  }

  Future<void> _addAllocation() async {
    final available = widget.expenseCategories
        .where((c) => !_allocations.containsKey(c.id))
        .toList();
    if (available.isEmpty) {
      AppSnackBar.info(context, 'Every expense category already has an amount.');
      return;
    }
    final picked = await showModalBottomSheet<TransactionCategory>(
      context: context,
      backgroundColor: AppColors.background,
      builder: (context) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            for (final c in available)
              ListTile(
                leading: CategoryIconBadge(
                    iconKey: c.iconKey, colorValue: c.colorValue, size: 36),
                title: Text(c.name),
                onTap: () => Navigator.of(context).pop(c),
              ),
          ],
        ),
      ),
    );
    if (picked == null) return;
    setState(() => _allocations[picked.id] = TextEditingController());
  }

  /// Sum of the allocation fields that currently parse.
  int get _allocatedMinor => _allocations.values
      .map((c) => Money.parseToMinor(c.text, _currency) ?? 0)
      .fold(0, (a, b) => a + b);

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final budget = Budget(
      id: widget.existing?.id ?? '',
      name: _name.text.trim(),
      startDate: _range.start,
      endDate: _lastDay,
      currency: _currency,
      totalMinor: Money.parseToMinor(_total.text, _currency)!,
      allocations: {
        for (final e in _allocations.entries)
          e.key: Money.parseToMinor(e.value.text, _currency)!,
      },
      warningThresholdPercent: _threshold,
    );
    final problem = budget.validate();
    if (problem != null) {
      AppSnackBar.error(context, problem);
      return;
    }
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    setState(() => _saving = true);
    try {
      await ref.read(budgetRepositoryProvider).save(uid, budget);
      if (!mounted) return;
      AppSnackBar.success(context, 'Budget saved.');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.error(context, readableError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final byId = {for (final c in widget.expenseCategories) c.id: c};
    final total = Money.parseToMinor(_total.text, _currency);

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          AppTextField(
            label: 'Budget name',
            hint: 'e.g. October living costs',
            controller: _name,
            textCapitalization: TextCapitalization.sentences,
            validator: (v) {
              final r = AppValidators.required(v, fieldName: 'Name');
              if (r != null) return r;
              return v!.trim().length > 40 ? 'Use 40 characters or fewer.' : null;
            },
          ),
          const Gap(16),
          PickerField(
            label: 'Period',
            value:
                '${AppDateUtils.formatDay(_range.start)} – ${AppDateUtils.formatDay(_lastDay)}',
            icon: Icons.date_range_rounded,
            onTap: _pickRange,
          ),
          const Gap(16),
          AmountCurrencyField(
            label: 'Total budget',
            controller: _total,
            onChanged: (_) => setState(() {}),
            currency: _currency,
            onCurrencyChanged: (c) => setState(() => _currency = c),
          ),
          const Gap(20),
          const FormSectionLabel('Warn me at',
              hint: 'Shows a warning when spending reaches this share.'),
          AppChoiceChips<int?>(
            options: const [null, 50, 75, 80, 90],
            selected: _threshold,
            labelOf: (t) => t == null ? 'Off' : '$t%',
            onSelected: (t) => setState(() => _threshold = t),
          ),
          const Gap(24),
          FormSectionLabel(
            'Category amounts (optional)',
            hint: total == null
                ? 'Split the total across expense categories.'
                : 'Allocated ${Money.format(_allocatedMinor, _currency)} of '
                    '${Money.format(total, _currency)}',
          ),
          for (final entry in _allocations.entries) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: CategoryIconBadge(
                    iconKey: byId[entry.key]?.iconKey ?? 'other',
                    colorValue: byId[entry.key]?.colorValue ?? 0xFF6B7280,
                    size: 40,
                  ),
                ),
                const Gap(10),
                Expanded(
                  child: AppTextField(
                    label: byId[entry.key]?.name ?? 'Deleted category',
                    controller: entry.value,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: AppValidators.amount(_currency),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded),
                  color: AppColors.textSecondary,
                  tooltip: 'Remove',
                  onPressed: () => setState(() {
                    _allocations.remove(entry.key)?.dispose();
                  }),
                ),
              ],
            ),
            const Gap(10),
          ],
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: _addAllocation,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add category amount'),
            ),
          ),
          if (total != null && _allocatedMinor > total)
            Text(
              'Category amounts are more than the total budget.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          const Gap(24),
          AppPrimaryButton(
            label: 'Save budget',
            icon: Icons.check_rounded,
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
