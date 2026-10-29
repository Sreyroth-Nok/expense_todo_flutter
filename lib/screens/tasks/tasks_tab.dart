import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../routing/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/clock_provider.dart';
import '../../widgets/app_states.dart';
import '../../utils/date_utils.dart';
import '../../widgets/form_fields.dart';
import '../../widgets/ui_kit.dart';
import '../../models/planner_task.dart';
import '../../providers/task_providers.dart';
import '../../widgets/task_tile.dart';

enum _TaskView { today, upcoming, all }

/// Planner → Tasks: Today, Upcoming and All views, with status filter
/// and sorting.
class TasksTab extends ConsumerStatefulWidget {
  const TasksTab({super.key});

  @override
  ConsumerState<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends ConsumerState<TasksTab> {
  _TaskView _view = _TaskView.today;
  TaskStatus? _status; // null = all statuses (All view only)
  TaskSort _sort = TaskSort.dueDate;

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);
    final now = ref.watch(clockProvider).value ?? DateTime.now();

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab-task',
        onPressed: () => context.push(AppRoutes.newTask),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Task'),
      ),
      body: tasksAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => Center(child: ErrorState(error: e)),
        data: (tasks) {
          final sections = switch (_view) {
            _TaskView.today => [
                ('Overdue', TaskQueries.overdue(tasks, now)),
                ('Today', TaskQueries.dueToday(tasks, now)),
              ],
            _TaskView.upcoming => [
                ('Upcoming', TaskQueries.upcoming(tasks, now)),
              ],
            _TaskView.all => [
                (
                  '',
                  TaskQueries.sort(
                    tasks.where((t) => _status == null || t.status == _status),
                    _sort,
                  ),
                ),
              ],
          };
          final isEmpty = sections.every((s) => s.$2.isEmpty);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
            children: [
              if (_view == _TaskView.today) ...[
                Text("Today's Tasks", style: AppTextStyles.headlineSmall),
                Text(AppDateUtils.formatDay(now), style: AppTextStyles.bodySmall),
                const Gap(12),
              ],
              PillTabs<_TaskView>(
                options: _TaskView.values,
                selected: _view,
                labelOf: (v) => switch (v) {
                  _TaskView.today => 'Today',
                  _TaskView.upcoming => 'Upcoming',
                  _TaskView.all => 'All',
                },
                onSelected: (v) => setState(() => _view = v),
              ),
              if (_view == _TaskView.all) ...[
                const Gap(8),
                Row(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: AppChoiceChips<TaskStatus?>(
                          options: const [null, ...TaskStatus.values],
                          selected: _status,
                          labelOf: (s) => s?.label ?? 'Any status',
                          onSelected: (s) => setState(() => _status = s),
                        ),
                      ),
                    ),
                    PopupMenuButton<TaskSort>(
                      tooltip: 'Sort',
                      icon: const Icon(Icons.sort_rounded),
                      initialValue: _sort,
                      onSelected: (s) => setState(() => _sort = s),
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                            value: TaskSort.dueDate, child: Text('By due date')),
                        PopupMenuItem(
                            value: TaskSort.priority,
                            child: Text('By priority')),
                      ],
                    ),
                  ],
                ),
              ],
              const Gap(8),
              if (isEmpty)
                EmptyState(
                  icon: Icons.task_alt_rounded,
                  title: switch (_view) {
                    _TaskView.today => 'Nothing due today',
                    _TaskView.upcoming => 'No upcoming tasks',
                    _TaskView.all => 'No tasks',
                  },
                  message: 'Tap "Task" to add something to do.',
                ),
              for (final (title, list) in sections)
                if (list.isNotEmpty) ...[
                  if (title.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 12, bottom: 4),
                      child: Text(
                        title,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: title == 'Overdue'
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  for (final t in list) TaskTile(task: t),
                ],
              const Gap(4),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: () => context.push(AppRoutes.newTask),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Task'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
