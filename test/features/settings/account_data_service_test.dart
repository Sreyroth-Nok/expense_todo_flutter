import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifemate/utils/app_constants.dart';
import 'package:lifemate/services/account_data_service.dart';

void main() {
  late FakeFirebaseFirestore db;

  /// Creates one document in every collection (and nested collection) for
  /// [uid], like a real account that used every feature.
  Future<void> seed(String uid) async {
    final user = db.collection('users').doc(uid);
    await user.set({'displayName': uid});
    for (final name in AccountDataService.collections) {
      for (var i = 0; i < 3; i++) {
        final doc = user.collection(name).doc('$name$i');
        await doc.set({'n': i});
        final child = AccountDataService.nested[name];
        if (child != null) {
          await doc.collection(child).doc('c$i').set({'n': i});
        }
      }
    }
  }

  setUp(() => db = FakeFirebaseFirestore());

  test('deletes every collection, nested collection and the profile', () async {
    await seed('alice');
    final count = await AccountDataService(db).deleteAllUserData('alice');

    final user = db.collection('users').doc('alice');
    expect((await user.get()).exists, isFalse);
    for (final name in AccountDataService.collections) {
      final docs = await user.collection(name).get();
      expect(docs.docs, isEmpty, reason: name);
    }
    final contributions = await user
        .collection(AppConstants.colSavingsGoals)
        .doc('${AppConstants.colSavingsGoals}0')
        .collection(AppConstants.colContributions)
        .get();
    expect(contributions.docs, isEmpty);
    // 10 collections × 3 docs + 2 nested × 3 docs + the profile.
    expect(count, 10 * 3 + 2 * 3 + 1);
  });

  test("never touches another user's data", () async {
    await seed('alice');
    await seed('bob');
    await AccountDataService(db).deleteAllUserData('alice');

    final bob = db.collection('users').doc('bob');
    expect((await bob.get()).exists, isTrue);
    expect((await bob.collection(AppConstants.colTransactions).get()).docs,
        hasLength(3));
  });

  test('covers every user collection the app writes to', () {
    // If a new collection is added to AppConstants, it must also be
    // deleted with the account. Allocations live inside budgets (a map),
    // so they have no collection to delete.
    const expected = {
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
    };
    expect(AccountDataService.collections.toSet(), expected);
    expect(AccountDataService.nested.values.toSet(),
        {AppConstants.colContributions, AppConstants.colShoppingItems});
  });
}
