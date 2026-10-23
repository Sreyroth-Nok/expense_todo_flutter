import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/budget.dart';

/// Firestore access for users/{userId}/budgets.
class BudgetRepository {
  BudgetRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String uid) => _firestore
      .collection(AppConstants.colUsers)
      .doc(uid)
      .collection(AppConstants.colBudgets);

  /// All budgets, newest period first (single-field index on startDate).
  Stream<List<Budget>> watchAll(String uid) {
    return _col(uid)
        .orderBy('startDate', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs.map(Budget.fromFirestore).toList());
  }

  Stream<Budget?> watchOne(String uid, String id) {
    return _col(uid).doc(id).snapshots().map(
        (d) => d.exists && d.data() != null ? Budget.fromFirestore(d) : null);
  }

  Future<void> save(String uid, Budget budget) async {
    final problem = budget.validate();
    if (problem != null) throw ValidationException(problem);
    try {
      if (budget.id.isEmpty) {
        await _col(uid).add({
          ...budget.toFirestore(),
          AppConstants.fieldCreatedAt: FieldValue.serverTimestamp(),
          AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
        });
      } else {
        await _col(uid).doc(budget.id).update({
          ...budget.toFirestore(),
          AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to save budget.');
    }
  }

  Future<void> delete(String uid, String id) async {
    try {
      await _col(uid).doc(id).delete();
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to delete budget.');
    }
  }
}

final budgetRepositoryProvider = Provider<BudgetRepository>((ref) {
  return BudgetRepository();
});
