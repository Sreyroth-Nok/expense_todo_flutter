import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../utils/app_constants.dart';
import '../../services/notification_service.dart';
import '../../models/scheduled_notice.dart';
import '../../theme/app_colors.dart';
import '../../utils/money.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/form_fields.dart';
import '../../services/auth_repository.dart';
import '../../services/reminder_repository.dart';
import '../../models/reminder.dart';
import '../../providers/reminder_providers.dart';

/// Create or edit a reminder / bill reminder.
class ReminderFormScreen extends ConsumerWidget {
  const ReminderFormScreen({
    super.key,
    this.reminderId,
    this.initialKind = ReminderKind.general,
  });

  final String? reminderId;
  final ReminderKind initialKind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currentUserProfileProvider).value?.currency ??
        AppConstants.defaultCurrency;
    final existing = reminderId == null
        ? const AsyncValue<Reminder?>.data(null)
        : ref.watch(reminderByIdProvider(reminderId!));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(reminderId == null ? 'New reminder' : 'Edit reminder'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: () => context.pop(),
        ),
        actions: [
          if (existing.value case final r?)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete',
              onPressed: () => _delete(context, ref, r),
            ),
        ],
      ),
      body: SafeArea(
        child: existing.when(
          loading: () => const LoadingState(),
          error: (e, _) => Center(child: ErrorState(error: e)),
          data: (r) => reminderId != null && r == null
              ? const Center(
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Reminder not found',
                    message: 'It may have been deleted.',
                  ),
                )
              : _ReminderForm(
                  existing: r,
                  initialKind: initialKind,
                  defaultCurrency: currency,
                ),
        ),
      ),
    );
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Reminder r) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete reminder?',
      message: '"${r.title}" and its scheduled notifications will be removed.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    final uid = ref.read(currentUidProvider);
    if (!ok || uid == null || !context.mounted) return;
    try {
      await ref.read(reminderRepositoryProvider).delete(uid, r.id);
      if (!context.mounted) return;
      AppSnackBar.success(context, 'Reminder deleted.');
      context.pop();
    } catch (e) {
      if (context.mounted) AppSnackBar.error(context, readableError(e));
    }
  }
}

class _ReminderForm extends ConsumerStatefulWidget {
  const _ReminderForm({
    required this.existing,
    required this.initialKind,
    required this.defaultCurrency,
  });

  final Reminder? existing;
  final ReminderKind initialKind;
  final String defaultCurrency;

  @override
  ConsumerState<_ReminderForm> createState() => _ReminderFormState();
}

class _ReminderFormState extends ConsumerState<_ReminderForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _notes = TextEditingController(text: widget.existing?.notes);
  late final _amount = TextEditingController(
    text: widget.existing?.amountMinor == null
        ? ''
        : Money.toInputText(widget.existing!.amountMinor!,
            widget.existing!.currency ?? widget.defaultCurrency),
  );
  late ReminderKind _kind = widget.existing?.kind ?? widget.initialKind;
  late String _currency = widget.existing?.currency ?? widget.defaultCurrency;
  late NoticeRepeat _repeat = widget.existing?.repeat ??
      (widget.initialKind == ReminderKind.bill
          ? NoticeRepeat.monthly
          : NoticeRepeat.none);
  late DateTime _at = widget.existing?.remindAt ?? _defaultTime();
  String? _timeError;
  bool _saving = false;

  static DateTime _defaultTime() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day + 1, 9);
  }

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    _amount.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final formOk = _formKey.currentState?.validate() ?? false;
    // A one-off reminder in the past would never fire.
    final inPast = _repeat == NoticeRepeat.none &&
        _at.isBefore(DateTime.now()) &&
        widget.existing == null;
    setState(() => _timeError = inPast ? 'Choose a time in the future.' : null);
    if (!formOk || inPast) return;

    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final amount = _kind == ReminderKind.bill && _amount.text.trim().isNotEmpty
        ? Money.parseToMinor(_amount.text, _currency)
        : null;

    final reminder = Reminder(
      id: widget.existing?.id ?? '',
      title: _title.text.trim(),
      notes: _notes.text.trim(),
      kind: _kind,
      remindAt: _at,
      repeat: _repeat,
      amountMinor: amount,
      currency: amount == null ? null : _currency,
      status: widget.existing?.status ?? ReminderStatus.pending,
    );

    setState(() => _saving = true);
    try {
      final granted =
          await ref.read(notificationServiceProvider).requestPermission();
      if (!granted && mounted) {
        AppSnackBar.info(context,
            'Notifications are blocked. The reminder is saved and shown in the app, but will not pop up.');
      }
      await ref.read(reminderRepositoryProvider).save(uid, reminder);
      if (!mounted) return;
      AppSnackBar.success(context, 'Reminder saved.');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.error(context, readableError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBill = _kind == ReminderKind.bill;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          SegmentedButton<ReminderKind>(
            segments: const [
              ButtonSegment(
                value: ReminderKind.general,
                label: Text('Reminder'),
                icon: Icon(Icons.notifications_outlined),
              ),
              ButtonSegment(
                value: ReminderKind.bill,
                label: Text('Bill'),
                icon: Icon(Icons.receipt_long_outlined),
              ),
            ],
            selected: {_kind},
            showSelectedIcon: false,
            style: SegmentedButton.styleFrom(
              selectedBackgroundColor: AppColors.primary,
              selectedForegroundColor: Colors.white,
            ),
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          const Gap(20),
          AppTextField(
            label: isBill ? 'Bill name' : 'Title',
            hint: isBill ? 'e.g. Internet bill' : 'e.g. Call grandma',
            controller: _title,
            textCapitalization: TextCapitalization.sentences,
            validator: (v) {
              final r = AppValidators.required(v, fieldName: 'Title');
              if (r != null) return r;
              return v!.trim().length > 100 ? 'Use 100 characters or fewer.' : null;
            },
          ),
          const Gap(16),
          DateTimeFields(
            dateLabel: isBill ? 'Due date' : 'Date',
            value: _at,
            errorText: _timeError,
            onChanged: (d) => setState(() {
              _at = d;
              _timeError = null;
            }),
          ),
          const Gap(20),
          const FormSectionLabel('Repeat'),
          AppChoiceChips<NoticeRepeat>(
            options: NoticeRepeat.values,
            selected: _repeat,
            labelOf: (r) => r.label,
            onSelected: (r) => setState(() => _repeat = r),
          ),
          if (isBill) ...[
            const Gap(20),
            AmountCurrencyField(
              label: 'Amount (optional)',
              controller: _amount,
              currency: _currency,
              optional: true,
              onCurrencyChanged: (c) => setState(() => _currency = c),
            ),
          ],
          const Gap(16),
          AppTextField(
            label: 'Notes (optional)',
            controller: _notes,
            maxLines: 2,
            validator: (v) =>
                (v?.length ?? 0) > 300 ? 'Use 300 characters or fewer.' : null,
          ),
          const Gap(28),
          AppPrimaryButton(
            label: 'Save reminder',
            icon: Icons.check_rounded,
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
