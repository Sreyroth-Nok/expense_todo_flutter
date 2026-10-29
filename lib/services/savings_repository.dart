import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/app_constants.dart';
import '../utils/app_exception.dart';
import '../models/savings_goal.dart';

/// Firestore access for savings goals and their contributions.
///
/// `savedAmountMinorUnits` is only changed inside a Firestore transaction
/// that also writes / deletes the matching contribution, so the history
/// and the total can never disagree and the balance can never go negative.
class SavingsRepository {
  SavingsRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _goals(String uid) => _firestore
      .collection(AppConstants.colUsers)
      .doc(uid)
      .collection(AppConstants.colSavingsGoals);

  CollectionReference<Map<String, dynamic>> _contributions(
          String uid, String goalId) =>
      _goals(uid).doc(goalId).collection(AppConstants.colContributions);

  Stream<List<SavingsGoal>> watchAll(String uid) => _goals(uid)
      .orderBy(AppConstants.fieldCreatedAt, descending: true)
      .snapshots()
      .map((s) => s.docs.map(SavingsGoal.fromFirestore).toList());

  Stream<SavingsGoal?> watchOne(String uid, String id) =>
      _goals(uid).doc(id).snapshots().map((d) =>
          d.exists && d.data() != null ? SavingsGoal.fromFirestore(d) : null);

  Stream<List<SavingsContribution>> watchContributions(
          String uid, String goalId) =>
      _contributions(uid, goalId)
          .orderBy(AppConstants.fieldDate, descending: true)
          .limit(200)
          .snapshots()
          .map((s) => s.docs.map(SavingsContribution.fromFirestore).toList());

  /// Creates a goal. A positive [startingAmountMinor] is recorded as the
  /// first contribution, in the same batch.
  Future<String> create(
    String uid,
    SavingsGoal goal, {
    int startingAmountMinor = 0,
  }) async {
    final problem = goal.validate();
    if (problem != null) throw ValidationException(problem);
    if (startingAmountMinor < 0) {
      throw const ValidationException('Starting amount cannot be negative.');
    }
    try {
      final ref = _goals(uid).doc();
      final batch = _firestore.batch();
      batch.set(ref, {
        ...goal.toFirestore(),
        'savedAmountMinorUnits': startingAmountMinor,
        AppConstants.fieldCreatedAt: FieldValue.serverTimestamp(),
        AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
      if (startingAmountMinor > 0) {
        batch.set(_contributions(uid, ref.id).doc(), {
          'amountMinorUnits': startingAmountMinor,
          'note': 'Starting amount',
          AppConstants.fieldDate: Timestamp.now(),
          AppConstants.fieldCreatedAt: FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      return ref.id;
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to create goal.');
    }
  }

  /// Updates name / target / date / reminder / completed flag.
  Future<void> update(String uid, SavingsGoal goal) async {
    final problem = goal.validate();
    if (problem != null) throw ValidationException(problem);
    try {
      await _goals(uid).doc(goal.id).update({
        ...goal.toFirestore(),
        AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to update goal.');
    }
  }

  Future<void> setCompleted(String uid, String goalId, bool completed) async {
    try {
      await _goals(uid).doc(goalId).update({
        'isCompleted': completed,
        AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to update goal.');
    }
  }

  /// Adds money (positive) or withdraws (negative).
  Future<void> addContribution(
    String uid,
    String goalId, {
    required int amountMinor,
    String note = '',
    DateTime? date,
  }) async {
    if (amountMinor == 0) {
      throw const ValidationException('Amount must not be zero.');
    }
    if (note.length > 100) {
      throw const ValidationException('Note must be 100 characters or fewer.');
    }
    final goalRef = _goals(uid).doc(goalId);
    await _runSafely(() => _firestore.runTransaction((t) async {
          final snap = await t.get(goalRef);
          if (!snap.exists) throw const DatabaseException('Goal not found.');
          final saved =
              (snap.data()!['savedAmountMinorUnits'] as num?)?.toInt() ?? 0;
          final next = saved + amountMinor;
          if (next < 0) {
            throw const ValidationException(
                'You cannot withdraw more than is saved.');
          }
          t.set(_contributions(uid, goalId).doc(), {
            'amountMinorUnits': amountMinor,
            'note': note.trim(),
            AppConstants.fieldDate: Timestamp.fromDate(date ?? DateTime.now()),
            AppConstants.fieldCreatedAt: FieldValue.serverTimestamp(),
          });
          t.update(goalRef, {
            'savedAmountMinorUnits': next,
            AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
          });
        }));
  }

  /// Removes a contribution and reverses its effect on the saved amount.
  Future<void> deleteContribution(
      String uid, String goalId, String contributionId) async {
    final goalRef = _goals(uid).doc(goalId);
    final cRef = _contributions(uid, goalId).doc(contributionId);
    await _runSafely(() => _firestore.runTransaction((t) async {
          final goal = await t.get(goalRef);
          final c = await t.get(cRef);
          if (!goal.exists || !c.exists) return;
          final saved =
              (goal.data()!['savedAmountMinorUnits'] as num?)?.toInt() ?? 0;
          final amount = (c.data()!['amountMinorUnits'] as num?)?.toInt() ?? 0;
          final next = saved - amount;
          if (next < 0) {
            throw const ValidationException(
                'Removing this deposit would make the saved amount negative.');
          }
          t.delete(cRef);
          t.update(goalRef, {
            'savedAmountMinorUnits': next,
            AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
          });
        }));
  }

  /// Deletes the goal and all its contributions.
  Future<void> delete(String uid, String goalId) async {
    try {
      final contributions = await _contributions(uid, goalId).get();
      final batch = _firestore.batch();
      for (final doc in contributions.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_goals(uid).doc(goalId));
      await batch.commit();
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to delete goal.');
    }
  }

  Future<void> _runSafely(Future<void> Function() action) async {
    try {
      await action();
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to save contribution.');
    }
  }
}

final savingsRepositoryProvider = Provider<SavingsRepository>((ref) {
  return SavingsRepository();
});
