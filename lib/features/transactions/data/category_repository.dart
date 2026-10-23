import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../domain/transaction_category.dart';

/// All Firestore access for users/{userId}/categories.
class CategoryRepository {
  CategoryRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection(AppConstants.colUsers).doc(uid);

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _userDoc(uid).collection(AppConstants.colCategories);

  /// Live list of all categories, sorted by name.
  Stream<List<TransactionCategory>> watchAll(String uid) {
    return _col(uid).orderBy('name').snapshots().map(
          (snap) => snap.docs.map(TransactionCategory.fromFirestore).toList(),
        );
  }

  /// Creates the starter categories once per account.
  ///
  /// The user document stores `categoriesSeeded: true` afterwards, so a
  /// default category the user deleted is not re-created on next launch.
  /// Only missing default ids are written, so this is safe to call twice.
  Future<void> ensureDefaults(String uid) async {
    try {
      final userSnap = await _userDoc(uid).get();
      if (userSnap.data()?['categoriesSeeded'] == true) return;

      final existing = await _col(uid).get();
      final existingIds = existing.docs.map((d) => d.id).toSet();

      final batch = _firestore.batch();
      for (final category in DefaultCategories.all) {
        if (existingIds.contains(category.id)) continue;
        batch.set(_col(uid).doc(category.id), {
          ...category.toFirestore(),
          AppConstants.fieldCreatedAt: FieldValue.serverTimestamp(),
          AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
        });
      }
      // set+merge (not update) so this also works if the profile document
      // is missing for some reason.
      batch.set(
        _userDoc(uid),
        {
          'categoriesSeeded': true,
          AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
      await batch.commit();
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to create categories.');
    }
  }

  Future<void> add(String uid, TransactionCategory category) async {
    try {
      await _col(uid).add({
        ...category.toFirestore(),
        AppConstants.fieldCreatedAt: FieldValue.serverTimestamp(),
        AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to add category.');
    }
  }

  /// Renames / re-styles a category. Existing transactions keep their
  /// saved `categoryName` snapshot.
  Future<void> update(String uid, TransactionCategory category) async {
    try {
      await _col(uid).doc(category.id).update({
        ...category.toFirestore(),
        AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to update category.');
    }
  }

  /// Deletes a category. Transactions that used it are NOT deleted; they
  /// keep displaying their saved `categoryName`.
  Future<void> delete(String uid, String id) async {
    try {
      await _col(uid).doc(id).delete();
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to delete category.');
    }
  }
}

final categoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  return CategoryRepository();
});
