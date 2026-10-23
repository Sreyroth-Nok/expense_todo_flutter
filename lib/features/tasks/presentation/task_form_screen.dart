import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/form_fields.dart';
import '../../auth/data/auth_repository.dart';
import '../data/task_repository.dart';
import '../domain/planner_task.dart';
import '../domain/task_providers.dart';

/// Create a task, or edit / delete one when [taskId] is given.
class TaskFormScreen extends ConsumerWidget {
  const TaskFormScreen({super.key, this.taskId});

  final String? taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final existing = taskId == null
        ? const AsyncValue<PlannerTask?>.data(null)
        : ref.watch(taskByIdProvider(taskId!));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(taskId == null ? 'New task' : 'Edit task'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Close',
          onPressed: () => context.pop(),
        ),
        actions: [
          if (existing.value case final t?)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded),
              tooltip: 'Delete',
              onPressed: () => _delete(context, ref, t),
            ),
        ],
      ),
      body: SafeArea(
        child: existing.when(
          loading: () => const LoadingState(),
          error: (e, _) => Center(child: ErrorState(error: e)),
          data: (task) => taskId != null && task == null
              ? const Center(
                  child: EmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'Task not found',
                    message: 'It may have been deleted.',
                  ),
                )
              : _TaskForm(existing: task),
        ),
      ),
    );
  }

  Future<void> _delete(
      BuildContext context, WidgetRef ref, PlannerTask t) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Delete task?',
      message: '"${t.title}" will be removed.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    final uid = ref.read(currentUidProvider);
    if (!ok || uid == null || !context.mounted) return;
    try {
      await ref.read(taskRepositoryProvider).delete(uid, t.id);
      if (!context.mounted) return;
      AppSnackBar.success(context, 'Task deleted.');
      context.pop();
    } catch (e) {
      if (context.mounted) AppSnackBar.error(context, readableError(e));
    }
  }
}

class _TaskForm extends ConsumerStatefulWidget {
  const _TaskForm({required this.existing});

  final PlannerTask? existing;

  @override
  ConsumerState<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends ConsumerState<_TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.existing?.title);
  late final _notes = TextEditingController(text: widget.existing?.notes);
  late DateTime? _due = widget.existing?.dueAt;
  late bool _hasTime = widget.existing?.hasDueTime ?? false;
  late TaskPriority _priority =
      widget.existing?.priority ?? TaskPriority.medium;
  late TaskStatus _status = widget.existing?.status ?? TaskStatus.todo;
  late bool _reminder = widget.existing?.reminderEnabled ?? false;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;

    final task = PlannerTask(
      id: widget.existing?.id ?? '',
      title: _title.text.trim(),
      notes: _notes.text.trim(),
      dueAt: _due == null
          ? null
          : _hasTime
              ? _due
              : DateTime(_due!.year, _due!.month, _due!.day),
      hasDueTime: _hasTime,
      priority: _priority,
      status: _status,
      reminderEnabled: _reminder,
      completedAt: widget.existing?.completedAt,
    );

    setState(() => _saving = true);
    try {
      if (task.reminderAt != null) {
        final granted =
            await ref.read(notificationServiceProvider).requestPermission();
        if (!granted && mounted) {
          AppSnackBar.info(context,
              'Notifications are blocked — the task is saved, but no reminder will pop up.');
        }
      }
      await ref.read(taskRepositoryProvider).save(uid, task);
      if (!mounted) return;
      AppSnackBar.success(context, 'Task saved.');
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
            label: 'Title',
            hint: 'e.g. Pay electricity bill',
            controller: _title,
            autofocus: widget.existing == null,
            textCapitalization: TextCapitalization.sentences,
            validator: (v) {
              final r = AppValidators.required(v, fieldName: 'Title');
              if (r != null) return r;
              return v!.trim().length > 100 ? 'Use 100 characters or fewer.' : null;
            },
          ),
          const Gap(16),
          AppTextField(
            label: 'Notes (optional)',
            controller: _notes,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            validator: (v) =>
                (v?.length ?? 0) > 500 ? 'Use 500 characters or fewer.' : null,
          ),
          const Gap(20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _due != null,
            activeThumbColor: AppColors.primary,
            title: Text('Due date', style: AppTextStyles.titleMedium),
            onChanged: (v) => setState(() {
              final now = DateTime.now();
              _due = v ? DateTime(now.year, now.month, now.day, now.hour + 1) : null;
              if (!v) _reminder = false;
            }),
          ),
          if (_due != null) ...[
            DateTimeFields(
              value: _due!,
              showTime: _hasTime,
              onChanged: (d) => setState(() => _due = d),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _hasTime,
              activeColor: AppColors.primary,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text('Set a time'),
              onChanged: (v) => setState(() => _hasTime = v ?? false),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _reminder,
              activeThumbColor: AppColors.primary,
              title: Text('Remind me', style: AppTextStyles.titleMedium),
              subtitle: Text(
                _hasTime
                    ? 'A notification at the due time.'
                    : 'A notification at 9:00 AM on the due date.',
                style: AppTextStyles.bodySmall,
              ),
              onChanged: (v) => setState(() => _reminder = v),
            ),
          ],
          const Gap(12),
          const FormSectionLabel('Priority'),
          AppChoiceChips<TaskPriority>(
            options: TaskPriority.values,
            selected: _priority,
            labelOf: (p) => p.label,
            onSelected: (p) => setState(() => _priority = p),
          ),
          const Gap(20),
          const FormSectionLabel('Status'),
          AppChoiceChips<TaskStatus>(
            options: TaskStatus.values,
            selected: _status,
            labelOf: (s) => s.label,
            onSelected: (s) => setState(() => _status = s),
          ),
          const Gap(28),
          AppPrimaryButton(
            label: 'Save task',
            icon: Icons.check_rounded,
            isLoading: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }
}
