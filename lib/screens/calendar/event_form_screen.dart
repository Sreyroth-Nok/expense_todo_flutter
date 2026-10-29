import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../services/notification_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/form_fields.dart';
import '../../services/auth_repository.dart';
import '../../services/calendar_repository.dart';
import '../../models/calendar_event.dart';
import '../../providers/calendar_providers.dart';

/// Create or edit a calendar event.
class EventFormScreen extends ConsumerWidget {
  const EventFormScreen({super.key, this.eventId, this.initialDay});

  final String? eventId;
  final DateTime? initialDay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existing = eventId == null
        ? const AsyncValue<CalendarEvent?>.data(null)
        : ref.watch(eventByIdProvider(eventId!));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(eventId == null ? 'New event' : 'Edit event'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: () => context.pop(),
        ),
        actions: [
          if (existing.value case final e?)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete',
              onPressed: () => _delete(context, ref, e),
            ),
        ],
      ),
      body: SafeArea(
        child: existing.when(
          loading: () => const LoadingState(),
          error: (e, _) => Center(child: ErrorState(error: e)),
          data: (e) => eventId != null && e == null
              ? const Center(
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Event not found',
                    message: 'It may have been deleted.',
                  ),
                )
              : _EventForm(existing: e, initialDay: initialDay),
        ),
      ),
    );
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, CalendarEvent e) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete event?',
      message: '"${e.title}" will be removed from your calendar.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    final uid = ref.read(currentUidProvider);
    if (!ok || uid == null || !context.mounted) return;
    try {
      await ref.read(calendarRepositoryProvider).delete(uid, e.id);
      if (!context.mounted) return;
      AppSnackBar.success(context, 'Event deleted.');
      context.pop();
    } catch (err) {
      if (context.mounted) AppSnackBar.error(context, readableError(err));
    }
  }
}

class _EventForm extends ConsumerStatefulWidget {
  const _EventForm({required this.existing, this.initialDay});

  final CalendarEvent? existing;
  final DateTime? initialDay;

  @override
  ConsumerState<_EventForm> createState() => _EventFormState();
}

class _EventFormState extends ConsumerState<_EventForm> {
  static const _reminderOptions = <int?>[null, 0, 5, 15, 30, 60, 1440];

  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _location = TextEditingController(text: widget.existing?.location);
  late final _notes = TextEditingController(text: widget.existing?.notes);
  late bool _allDay = widget.existing?.allDay ?? false;
  late DateTime _start;
  late DateTime _end; // For all-day events: the LAST day (inclusive).
  late int? _reminder = widget.existing?.reminderMinutesBefore;
  String? _rangeError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _start = e.startAt;
      _end = e.allDay ? e.lastDay : e.endAt;
    } else {
      final now = DateTime.now();
      final day = widget.initialDay ?? now;
      _start = DateTime(day.year, day.month, day.day, now.hour + 1);
      _end = _start.add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    _notes.dispose();
    super.dispose();
  }

  CalendarEvent _build() {
    final start = _allDay ? DateTime(_start.year, _start.month, _start.day) : _start;
    final end = _allDay ? DateTime(_end.year, _end.month, _end.day + 1) : _end;
    return CalendarEvent(
      id: widget.existing?.id ?? '',
      title: _title.text.trim(),
      startAt: start,
      endAt: end,
      allDay: _allDay,
      location: _location.text.trim(),
      notes: _notes.text.trim(),
      reminderMinutesBefore: _reminder,
    );
  }

  Future<void> _save() async {
    final formOk = _formKey.currentState?.validate() ?? false;
    final event = _build();
    final problem = event.validate();
    final rangeProblem =
        problem != null && !problem.startsWith('Title') ? problem : null;
    setState(() => _rangeError = rangeProblem);
    if (!formOk || problem != null) return;

    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    setState(() => _saving = true);
    try {
      if (event.reminderAt != null) {
        final granted =
            await ref.read(notificationServiceProvider).requestPermission();
        if (!granted && mounted) {
          AppSnackBar.info(context,
              'Notifications are blocked — the event is saved without a pop-up reminder.');
        }
      }
      await ref.read(calendarRepositoryProvider).save(uid, event);
      if (!mounted) return;
      AppSnackBar.success(context, 'Event saved.');
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.error(context, readableError(e));
    }
  }

  String _reminderLabel(int? m) => switch (m) {
        null => 'None',
        0 => _allDay ? '9:00 AM' : 'At start',
        1440 => '1 day before',
        60 => '1 hour before',
        _ => '$m min before',
      };

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          AppTextField(
            label: 'Title',
            hint: 'e.g. Dentist appointment',
            controller: _title,
            autofocus: widget.existing == null,
            textCapitalization: TextCapitalization.sentences,
            validator: (v) {
              final r = AppValidators.required(v, fieldName: 'Title');
              if (r != null) return r;
              return v!.trim().length > 100 ? 'Use 100 characters or fewer.' : null;
            },
          ),
          const Gap(12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _allDay,
            activeThumbColor: AppColors.primary,
            title: Text('All day', style: AppTextStyles.titleMedium),
            onChanged: (v) => setState(() {
              _allDay = v;
              if (v && _end.isBefore(_start)) _end = _start;
            }),
          ),
          const Gap(8),
          DateTimeFields(
            dateLabel: 'Starts',
            value: _start,
            showTime: !_allDay,
            onChanged: (d) => setState(() {
              // Keep the duration when moving the start.
              final duration = _end.difference(_start);
              _start = d;
              _end = d.add(duration);
              _rangeError = null;
            }),
          ),
          const Gap(12),
          DateTimeFields(
            dateLabel: 'Ends',
            value: _end,
            showTime: !_allDay,
            errorText: _rangeError,
            onChanged: (d) => setState(() {
              _end = d;
              _rangeError = null;
            }),
          ),
          const Gap(16),
          AppTextField(
            label: 'Location (optional)',
            controller: _location,
            prefixIcon: const Icon(Icons.place_outlined),
            validator: (v) =>
                (v?.length ?? 0) > 100 ? 'Use 100 characters or fewer.' : null,
          ),
          const Gap(16),
          AppTextField(
            label: 'Notes (optional)',
            controller: _notes,
            maxLines: 3,
            validator: (v) =>
                (v?.length ?? 0) > 500 ? 'Use 500 characters or fewer.' : null,
          ),
          const Gap(20),
          const FormSectionLabel('Reminder'),
          AppChoiceChips<int?>(
            options: _reminderOptions,
            selected: _reminder,
            labelOf: _reminderLabel,
            onSelected: (m) => setState(() => _reminder = m),
          ),
          const Gap(28),
          AppPrimaryButton(
            label: 'Save event',
            icon: Icons.check_rounded,
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
