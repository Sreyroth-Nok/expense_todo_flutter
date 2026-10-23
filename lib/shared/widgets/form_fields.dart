import 'package:flutter/material.dart';
import 'package:gap/gap.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/utils/date_utils.dart';
import '../../core/utils/money.dart';
import '../../core/utils/validators.dart';
import 'app_text_field.dart';

/// Read-only field that opens a picker when tapped (date, time, ...).
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
    this.errorText,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          errorText: errorText,
          enabled: onTap != null,
        ),
        child: Text(
          value,
          style: AppTextStyles.bodyMedium,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

/// Date + time pickers side by side, editing one [DateTime].
class DateTimeFields extends StatelessWidget {
  const DateTimeFields({
    super.key,
    required this.value,
    required this.onChanged,
    this.dateLabel = 'Date',
    this.timeLabel = 'Time',
    this.showTime = true,
    this.firstDate,
    this.errorText,
  });

  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final String dateLabel;
  final String timeLabel;
  final bool showTime;
  final DateTime? firstDate;
  final String? errorText;

  Future<void> _pickDate(BuildContext context) async {
    final first = firstDate ?? DateTime(2000);
    final picked = await showDatePicker(
      context: context,
      initialDate: value.isBefore(first) ? first : value,
      firstDate: first,
      lastDate: DateTime(DateTime.now().year + 10),
    );
    if (picked == null) return;
    onChanged(DateTime(
        picked.year, picked.month, picked.day, value.hour, value.minute));
  }

  Future<void> _pickTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(value),
    );
    if (picked == null) return;
    onChanged(DateTime(
        value.year, value.month, value.day, picked.hour, picked.minute));
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: PickerField(
            label: dateLabel,
            value: AppDateUtils.formatDay(value),
            icon: Icons.calendar_today_outlined,
            onTap: () => _pickDate(context),
            errorText: errorText,
          ),
        ),
        if (showTime) ...[
          const Gap(12),
          Expanded(
            flex: 2,
            child: PickerField(
              label: timeLabel,
              value: AppDateUtils.formatTime(value),
              icon: Icons.schedule_outlined,
              onTap: () => _pickTime(context),
            ),
          ),
        ],
      ],
    );
  }
}

/// Amount text field with a currency dropdown next to it.
class AmountCurrencyField extends StatelessWidget {
  const AmountCurrencyField({
    super.key,
    required this.controller,
    required this.currency,
    required this.onCurrencyChanged,
    this.label = 'Amount',
    this.fieldKey,
    this.optional = false,
    this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String currency;
  final ValueChanged<String> onCurrencyChanged;
  final String label;
  final Key? fieldKey;

  /// When true an empty field is valid (e.g. an optional bill amount).
  final bool optional;

  @override
  Widget build(BuildContext context) {
    final validate = AppValidators.amount(currency);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: AppTextField(
            key: fieldKey,
            label: label,
            hint: Currencies.of(currency).decimals == 0 ? '0' : '0.00',
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            validator: (v) =>
                optional && (v == null || v.trim().isEmpty) ? null : validate(v),
            prefixIcon: const Icon(Icons.payments_outlined),
            onChanged: onChanged,
          ),
        ),
        const Gap(12),
        SizedBox(
          width: 110,
          child: DropdownButtonFormField<String>(
            initialValue: currency,
            decoration: const InputDecoration(labelText: 'Currency'),
            items: [
              for (final c in Currencies.supported)
                DropdownMenuItem(value: c.code, child: Text(c.code)),
            ],
            onChanged: (v) {
              if (v != null) onCurrencyChanged(v);
            },
          ),
        ),
      ],
    );
  }
}

/// A row of single-choice chips styled with the LifeMate palette.
class AppChoiceChips<T> extends StatelessWidget {
  const AppChoiceChips({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in options)
          ChoiceChip(
            label: Text(labelOf(option)),
            selected: option == selected,
            showCheckmark: false,
            selectedColor: AppColors.primary,
            backgroundColor: AppColors.background,
            side: const BorderSide(color: AppColors.border),
            labelStyle: AppTextStyles.labelLarge.copyWith(
              color:
                  option == selected ? Colors.white : AppColors.textPrimary,
            ),
            onSelected: (_) => onSelected(option),
          ),
      ],
    );
  }
}

/// Small bold label above a form section.
class FormSectionLabel extends StatelessWidget {
  const FormSectionLabel(this.text, {super.key, this.hint});

  final String text;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: AppTextStyles.titleMedium),
          if (hint != null) ...[
            const Gap(2),
            Text(hint!, style: AppTextStyles.bodySmall),
          ],
        ],
      ),
    );
  }
}
