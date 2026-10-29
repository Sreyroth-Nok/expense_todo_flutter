import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../utils/money.dart';
import 'app_text_field.dart';
import 'form_fields.dart';
import 'ui_kit.dart';
import '../models/finance_transaction.dart';
import '../models/transaction_category.dart';
import 'category_visuals.dart';

/// The add / edit transaction form.
///
/// It knows nothing about Firebase: it receives the data it needs and
/// returns a [FinanceTransaction] through [onSubmit]. This keeps it easy to
/// widget-test.
class TransactionForm extends StatefulWidget {
  const TransactionForm({
    super.key,
    this.initial,
    this.initialType = TransactionType.expense,
    required this.categories,
    required this.defaultCurrency,
    required this.onSubmit,
    this.onManageCategories,
    this.isSaving = false,
  });

  /// The transaction being edited, or null when adding.
  final FinanceTransaction? initial;
  final TransactionType initialType;
  final List<TransactionCategory> categories;
  final String defaultCurrency;
  final ValueChanged<FinanceTransaction> onSubmit;
  final VoidCallback? onManageCategories;
  final bool isSaving;

  @override
  State<TransactionForm> createState() => _TransactionFormState();
}

class _TransactionFormState extends State<TransactionForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _description;
  late TransactionType _type;
  late String _currency;
  late DateTime _date;
  String? _categoryId;
  bool _categoryError = false;

  @override
  void initState() {
    super.initState();
    final tx = widget.initial;
    _type = tx?.type ?? widget.initialType;
    _currency = tx?.currency ?? widget.defaultCurrency;
    _date = tx?.date ?? DateTime.now();
    _categoryId = tx?.categoryId;
    _amount = TextEditingController(
      text: tx == null ? '' : Money.toInputText(tx.amountMinor, tx.currency),
    );
    _description = TextEditingController(text: tx?.description ?? '');
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  List<TransactionCategory> get _categoriesForType =>
      widget.categories.where((c) => c.type == _type).toList();

  TransactionCategory? get _selectedCategory =>
      _categoriesForType.where((c) => c.id == _categoryId).firstOrNull;

  Future<void> _pickCategory() async {
    final picked = await showModalBottomSheet<TransactionCategory>(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      builder: (_) => CategoryPickerSheet(
        categories: _categoriesForType,
        selectedId: _categoryId,
        onManage: widget.onManageCategories,
      ),
    );
    if (picked != null) {
      setState(() {
        _categoryId = picked.id;
        _categoryError = false;
      });
    }
  }

  void _submit() {
    final formValid = _formKey.currentState?.validate() ?? false;
    final category = _selectedCategory;
    setState(() => _categoryError = category == null);
    if (!formValid || category == null) return;

    final base = widget.initial ??
        FinanceTransaction(
          type: _type,
          amountMinor: 0,
          currency: _currency,
          categoryId: '',
          categoryName: '',
          date: _date,
        );
    widget.onSubmit(base.copyWith(
      type: _type,
      amountMinor: Money.parseToMinor(_amount.text, _currency),
      currency: _currency,
      categoryId: category.id,
      categoryName: category.name,
      description: _description.text.trim(),
      date: _date,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedCategory;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          PillTabs<TransactionType>(
            options: const [TransactionType.expense, TransactionType.income],
            selected: _type,
            labelOf: (t) => t.label,
            onSelected: (t) => setState(() {
              _type = t;
              // A category belongs to one type; clear it if it no longer fits.
              if (_selectedCategory == null) _categoryId = null;
            }),
          ),
          const Gap(22),

          AmountCurrencyField(
            fieldKey: const Key('amountField'),
            controller: _amount,
            currency: _currency,
            onCurrencyChanged: (c) => setState(() => _currency = c),
          ),
          const Gap(18),

          // ── Category select row ────────────────────────────────
          const FieldLabel('Category'),
          InkWell(
            key: const Key('categoryField'),
            onTap: _pickCategory,
            borderRadius: BorderRadius.circular(14),
            child: InputDecorator(
              decoration: InputDecoration(
                errorText: _categoryError ? 'Please choose a category.' : null,
                suffixIcon: const Icon(Icons.chevron_right_rounded),
              ),
              child: selected == null
                  ? Text('Select category',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary))
                  : Row(
                      children: [
                        CategoryIconBadge(
                          iconKey: selected.iconKey,
                          colorValue: selected.colorValue,
                          size: 26,
                        ),
                        const Gap(10),
                        Expanded(
                          child: Text(selected.name,
                              style: AppTextStyles.bodyMedium,
                              overflow: TextOverflow.ellipsis),
                        ),
                      ],
                    ),
            ),
          ),
          const Gap(18),

          DateTimeFields(
            value: _date,
            onChanged: (d) => setState(() => _date = d),
          ),
          const Gap(18),

          AppTextField(
            label: 'Description (optional)',
            hint: 'Enter description…',
            controller: _description,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            validator: (v) => (v?.trim().length ?? 0) > 200
                ? 'Description must be 200 characters or fewer.'
                : null,
          ),
          const Gap(28),

          HoneyButton(
            label: widget.initial == null ? 'Save' : 'Save changes',
            icon: Icons.check_rounded,
            isLoading: widget.isSaving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

/// Bottom sheet with a grid of categories to choose from.
class CategoryPickerSheet extends StatelessWidget {
  const CategoryPickerSheet({
    super.key,
    required this.categories,
    this.selectedId,
    this.onManage,
  });

  final List<TransactionCategory> categories;
  final String? selectedId;
  final VoidCallback? onManage;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Select category',
                      style: AppTextStyles.headlineSmall),
                ),
                if (onManage != null)
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onManage!();
                    },
                    child: const Text('Manage'),
                  ),
              ],
            ),
            const Gap(12),
            if (categories.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'No categories of this type yet. Tap "Manage" to add one.',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.center,
                ),
              )
            else
              Flexible(
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.82,
                  children: [
                    for (final c in categories)
                      InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () => Navigator.of(context).pop(c),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: c.id == selectedId
                                  ? AppColors.primary
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CategoryIconBadge(
                                iconKey: c.iconKey,
                                colorValue: c.colorValue,
                                size: 44,
                              ),
                              const Gap(6),
                              Text(
                                c.name,
                                style: AppTextStyles.labelMedium
                                    .copyWith(color: AppColors.textPrimary),
                                maxLines: 2,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
