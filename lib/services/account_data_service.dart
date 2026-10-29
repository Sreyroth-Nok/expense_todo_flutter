import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/app_constants.dart';

/// Deletes every document a user owns (used by "Delete account").
///
/// Firestore does NOT delete sub-collections when a parent document is
/// deleted, so each collection — and the nested ones — is removed
/// explicitly, in batches of at most [_batchSize] writes.
///
/// ⚠️  If a new collection is added in a future phase, add it to
/// [collections] (and [nested] if it has sub-collections). The unit test
/// account_data_service_test.dart helps catch a missing one.
class AccountDataService {
  AccountDataService(this._firestore);

  final FirebaseFirestore _firestore;
  static const int _batchSize = 400;

  /// Every collection under users/{uid}.
  static const collections = [
    AppConstants.colCategories,
    AppConstants.colTransactions,
    AppConstants.colSpendingLimits,
    AppConstants.colNotificationEvents,
    AppConstants.colBudgets,
    AppConstants.colSavingsGoals,
    AppConstants.colTasks,
    AppConstants.colCalendarEvents,
    AppConstants.colReminders,
    AppConstants.colShoppingLists,
  ];

  /// Sub-collections under documents of a top-level collection.
  static const nested = {
    AppConstants.colSavingsGoals: AppConstants.colContributions,
    AppConstants.colShoppingLists: AppConstants.colShoppingItems,
  };

  /// Deletes all data and finally the profile document. Returns how many
  /// documents were deleted.
  Future<int> deleteAllUserData(String uid) async {
    final userDoc = _firestore.collection(AppConstants.colUsers).doc(uid);
    var deleted = 0;

    for (final name in collections) {
      final col = userDoc.collection(name);
      while (true) {
        final page = await col.limit(_batchSize).get();
        if (page.docs.isEmpty) break;
        for (final doc in page.docs) {
          final child = nested[name];
          if (child != null) {
            deleted += await _deleteCollection(doc.reference.collection(child));
          }
        }
        deleted += await _deleteDocs(page.docs.map((d) => d.reference));
      }
    }

    await userDoc.delete();
    return deleted + 1;
  }

  Future<int> _deleteCollection(CollectionReference<Map<String, dynamic>> col) async {
    var count = 0;
    while (true) {
      final page = await col.limit(_batchSize).get();
      if (page.docs.isEmpty) return count;
      count += await _deleteDocs(page.docs.map((d) => d.reference));
    }
  }

  Future<int> _deleteDocs(Iterable<DocumentReference> refs) async {
    final batch = _firestore.batch();
    var count = 0;
    for (final ref in refs) {
      batch.delete(ref);
      count++;
    }
    if (count > 0) await batch.commit();
    return count;
  }
}
