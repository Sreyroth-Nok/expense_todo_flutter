import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/reminder.dart';

/// Firestore access for users/{userId}/reminders.
class ReminderRepository {
  ReminderRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String uid) => _firestore
      .collection(AppConstants.colUsers)
      .doc(uid)
      .collection(AppConstants.colReminders);

  /// The 300 reminders with the latest times (single-field index on
  /// remindAt). The UI sorts them itself.
  Stream<List<Reminder>> watchAll(String uid) => _col(uid)
      .orderBy('remindAt', descending: true)
      .limit(300)
      .snapshots()
      .map((s) => s.docs.map(Reminder.fromFirestore).toList());

  Stream<Reminder?> watchOne(String uid, String id) =>
      _col(uid).doc(id).snapshots().map((d) =>
          d.exists && d.data() != null ? Reminder.fromFirestore(d) : null);

  Future<void> save(String uid, Reminder r) async {
    final problem = r.validate();
    if (problem != null) throw ValidationException(problem);
    try {
      if (r.id.isEmpty) {
        await _col(uid).add({
          ...r.toFirestore(),
          AppConstants.fieldCreatedAt: FieldValue.serverTimestamp(),
          AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
        });
      } else {
        await _col(uid).doc(r.id).update({
          ...r.toFirestore(),
          AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to save reminder.');
    }
  }

  Future<void> delete(String uid, String id) async {
    try {
      await _col(uid).doc(id).delete();
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to delete reminder.');
    }
  }
}

final reminderRepositoryProvider = Provider<ReminderRepository>((ref) {
  return ReminderRepository();
});
