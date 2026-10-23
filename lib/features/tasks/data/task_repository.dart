import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/planner_task.dart';

/// Firestore access for users/{userId}/tasks.
///
/// A personal task list is small, so we stream the latest 500 tasks and
/// filter / sort in memory. This avoids a composite index for every
/// combination of status, due date and priority.
class TaskRepository {
  TaskRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const int limit = 500;

  CollectionReference<Map<String, dynamic>> _col(String uid) => _firestore
      .collection(AppConstants.colUsers)
      .doc(uid)
      .collection(AppConstants.colTasks);

  Stream<List<PlannerTask>> watchAll(String uid) => _col(uid)
      .orderBy(AppConstants.fieldCreatedAt, descending: true)
      .limit(limit)
      .snapshots()
      .map((s) => s.docs.map(PlannerTask.fromFirestore).toList());

  Stream<PlannerTask?> watchOne(String uid, String id) =>
      _col(uid).doc(id).snapshots().map((d) =>
          d.exists && d.data() != null ? PlannerTask.fromFirestore(d) : null);

  Future<void> save(String uid, PlannerTask task) async {
    final problem = task.validate();
    if (problem != null) throw ValidationException(problem);
    final completedAt = task.isDone
        ? (task.completedAt == null
            ? FieldValue.serverTimestamp()
            : Timestamp.fromDate(task.completedAt!))
        : null;
    try {
      if (task.id.isEmpty) {
        await _col(uid).add({
          ...task.toFirestore(),
          'completedAt': completedAt,
          AppConstants.fieldCreatedAt: FieldValue.serverTimestamp(),
          AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
        });
      } else {
        await _col(uid).doc(task.id).update({
          ...task.toFirestore(),
          'completedAt': completedAt,
          AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to save task.');
    }
  }

  /// Marks done / not done. Sets or clears `completedAt`.
  Future<void> setStatus(String uid, String id, TaskStatus status) async {
    try {
      await _col(uid).doc(id).update({
        'status': status.name,
        'completedAt':
            status == TaskStatus.done ? FieldValue.serverTimestamp() : null,
        AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to update task.');
    }
  }

  Future<void> delete(String uid, String id) async {
    try {
      await _col(uid).doc(id).delete();
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to delete task.');
    }
  }
}

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository();
});
