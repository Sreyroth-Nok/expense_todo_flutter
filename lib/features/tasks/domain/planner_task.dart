import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/date_utils.dart';

enum TaskPriority {
  low,
  medium,
  high;

  static TaskPriority fromName(String? n) =>
      values.firstWhere((p) => p.name == n, orElse: () => TaskPriority.medium);

  String get label => switch (this) {
        low => 'Low',
        medium => 'Medium',
        high => 'High',
      };
}

enum TaskStatus {
  todo,
  inProgress,
  done;

  static TaskStatus fromName(String? n) =>
      values.firstWhere((s) => s.name == n, orElse: () => TaskStatus.todo);

  String get label => switch (this) {
        todo => 'To do',
        inProgress => 'In progress',
        done => 'Done',
      };
}

enum TaskSort { dueDate, priority }

/// A to-do item. Named `PlannerTask` to avoid confusion with other "Task"
/// types.
///
/// Firestore path: users/{userId}/tasks/{taskId}
///
/// Fields:
///   title            – 1–100 chars
///   notes            – ≤ 500 chars
///   dueAt            – Timestamp or null (no due date)
///   hasDueTime       – false = due "some time that day"
///   priority         – 'low' | 'medium' | 'high'
///   status           – 'todo' | 'inProgress' | 'done'
///   reminderEnabled  – notify at the due time (09:00 for date-only tasks)
///   completedAt      – server timestamp when marked done, else null
///   createdAt / updatedAt
class PlannerTask {
  const PlannerTask({
    this.id = '',
    required this.title,
    this.notes = '',
    this.dueAt,
    this.hasDueTime = false,
    this.priority = TaskPriority.medium,
    this.status = TaskStatus.todo,
    this.reminderEnabled = false,
    this.completedAt,
    this.createdAt,
  });

  final String id;
  final String title;
  final String notes;
  final DateTime? dueAt;
  final bool hasDueTime;
  final TaskPriority priority;
  final TaskStatus status;
  final bool reminderEnabled;
  final DateTime? completedAt;
  final DateTime? createdAt;

  bool get isDone => status == TaskStatus.done;

  /// The moment after which the task counts as overdue: the due time, or
  /// the end of the due day for date-only tasks.
  DateTime? get deadline {
    final d = dueAt;
    if (d == null) return null;
    return hasDueTime ? d : AppDateUtils.dayOf(d).end;
  }

  bool isOverdueAt(DateTime now) =>
      !isDone && deadline != null && deadline!.isBefore(now);

  bool isDueOn(DateTime day) =>
      dueAt != null && AppDateUtils.isSameDay(dueAt!, day);

  /// When to notify, or null for no reminder.
  DateTime? get reminderAt {
    final d = dueAt;
    if (!reminderEnabled || d == null || isDone) return null;
    return hasDueTime ? d : DateTime(d.year, d.month, d.day, 9);
  }

  factory PlannerTask.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return PlannerTask(
      id: doc.id,
      title: d['title'] as String? ?? '',
      notes: d['notes'] as String? ?? '',
      dueAt: (d['dueAt'] as Timestamp?)?.toDate(),
      hasDueTime: d['hasDueTime'] as bool? ?? false,
      priority: TaskPriority.fromName(d['priority'] as String?),
      status: TaskStatus.fromName(d['status'] as String?),
      reminderEnabled: d['reminderEnabled'] as bool? ?? false,
      completedAt: (d['completedAt'] as Timestamp?)?.toDate(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Editable fields. `completedAt` is managed by the repository.
  Map<String, dynamic> toFirestore() => {
        'title': title,
        'notes': notes,
        'dueAt': dueAt == null ? null : Timestamp.fromDate(dueAt!),
        'hasDueTime': dueAt != null && hasDueTime,
        'priority': priority.name,
        'status': status.name,
        'reminderEnabled': dueAt != null && reminderEnabled,
      };

  String? validate() {
    if (title.trim().isEmpty || title.trim().length > 100) {
      return 'Title must be 1–100 characters.';
    }
    if (notes.length > 500) return 'Notes must be 500 characters or fewer.';
    return null;
  }

  PlannerTask copyWith({TaskStatus? status}) => PlannerTask(
        id: id,
        title: title,
        notes: notes,
        dueAt: dueAt,
        hasDueTime: hasDueTime,
        priority: priority,
        status: status ?? this.status,
        reminderEnabled: reminderEnabled,
        completedAt: completedAt,
        createdAt: createdAt,
      );
}

/// Pure list helpers for the planner views (unit-tested).
abstract final class TaskQueries {
  /// Incomplete tasks whose deadline has passed.
  static List<PlannerTask> overdue(Iterable<PlannerTask> tasks, DateTime now) =>
      sort(tasks.where((t) => t.isOverdueAt(now)), TaskSort.dueDate);

  /// Tasks due today (done ones included, so the user sees progress),
  /// excluding the overdue ones listed separately.
  static List<PlannerTask> dueToday(
          Iterable<PlannerTask> tasks, DateTime now) =>
      sort(tasks.where((t) => t.isDueOn(now) && !t.isOverdueAt(now)),
          TaskSort.dueDate);

  /// Incomplete tasks due after today.
  static List<PlannerTask> upcoming(
      Iterable<PlannerTask> tasks, DateTime now) {
    final tomorrow = AppDateUtils.dayOf(now).end;
    return sort(
      tasks.where((t) =>
          !t.isDone && t.dueAt != null && !t.dueAt!.isBefore(tomorrow)),
      TaskSort.dueDate,
    );
  }

  /// Sorts without modifying the input. Due date: earliest first, tasks
  /// without a date last. Priority: high → low, then by due date.
  /// Completed tasks always go after incomplete ones.
  static List<PlannerTask> sort(Iterable<PlannerTask> tasks, TaskSort by) {
    int byDue(PlannerTask a, PlannerTask b) {
      final da = a.deadline, db = b.deadline;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    }

    return tasks.toList()
      ..sort((a, b) {
        if (a.isDone != b.isDone) return a.isDone ? 1 : -1;
        if (by == TaskSort.priority && a.priority != b.priority) {
          return b.priority.index.compareTo(a.priority.index);
        }
        final due = byDue(a, b);
        return due != 0 ? due : a.title.compareTo(b.title);
      });
  }
}
