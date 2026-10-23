import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/money.dart';
import '../../../../shared/widgets/app_button.dart';
import '../../../../shared/widgets/app_text_field.dart';
import '../../../../shared/widgets/form_fields.dart';
import '../../domain/finance_transaction.dart';
import '../../domain/transaction_category.dart';
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

  void _submit() {
    final formValid = _formKey.currentState?.validate() ?? false;
    final category = _categoriesForType
        .where((c) => c.id == _categoryId)
        .firstOrNull;
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
    final categories = _categoriesForType;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          // ── Type ───────────────────────────────────────────────
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(
                value: TransactionType.expense,
                label: Text('Expense'),
                icon: Icon(Icons.arrow_upward_rounded),
              ),
              ButtonSegment(
                value: TransactionType.income,
                label: Text('Income'),
                icon: Icon(Icons.arrow_downward_rounded),
              ),
            ],
            selected: {_type},
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.primary,
              selectedForegroundColor: Colors.white,
            ),
            onSelectionChanged: (s) => setState(() {
              _type = s.first;
              // A category belongs to one type; clear it if it no longer fits.
              if (!_categoriesForType.any((c) => c.id == _categoryId)) {
                _categoryId = null;
              }
            }),
          ),
          const Gap(20),

          // ── Amount + currency ──────────────────────────────────
          AmountCurrencyField(
            fieldKey: const Key('amountField'),
            controller: _amount,
            currency: _currency,
            onCurrencyChanged: (c) => setState(() => _currency = c),
          ),
          const Gap(20),

          // ── Category ───────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Text('Category', style: AppTextStyles.titleMedium),
              ),
              if (widget.onManageCategories != null)
                TextButton(
                  onPressed: widget.onManageCategories,
                  child: const Text('Manage'),
                ),
            ],
          ),
          const Gap(4),
          if (categories.isEmpty)
            Text(
              'No ${_type.label.toLowerCase()} categories yet. Tap "Manage" to add one.',
              style: AppTextStyles.bodySmall,
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final c in categories)
                  ChoiceChip(
                    avatar: Icon(
                      CategoryIcons.of(c.iconKey),
                      size: 18,
                      color: _categoryId == c.id
                          ? Colors.white
                          : Color(c.colorValue),
                    ),
                    label: Text(c.name),
                    selected: _categoryId == c.id,
                    showCheckmark: false,
                    selectedColor: AppColors.primary,
                    backgroundColor: AppColors.background,
                    side: const BorderSide(color: AppColors.border),
                    labelStyle: AppTextStyles.labelLarge.copyWith(
                      color: _categoryId == c.id
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                    onSelected: (_) => setState(() {
                      _categoryId = c.id;
                      _categoryError = false;
                    }),
                  ),
              ],
            ),
          if (_categoryError) ...[
            const Gap(6),
            Text(
              'Please choose a category.',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ],
          const Gap(20),

          // ── Date + time ────────────────────────────────────────
          DateTimeFields(
            value: _date,
            onChanged: (d) => setState(() => _date = d),
          ),
          const Gap(20),

          // ── Description ────────────────────────────────────────
          AppTextField(
            label: 'Description (optional)',
            hint: 'e.g. Lunch with friends',
            controller: _description,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            validator: (v) => (v?.trim().length ?? 0) > 200
                ? 'Description must be 200 characters or fewer.'
                : null,
          ),
          const Gap(28),

          AppPrimaryButton(
            label: widget.initial == null ? 'Save transaction' : 'Save changes',
            icon: Icons.check_rounded,
            isLoading: widget.isSaving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}
