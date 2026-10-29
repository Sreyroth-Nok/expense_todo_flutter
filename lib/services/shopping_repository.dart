import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/app_constants.dart';
import '../utils/app_exception.dart';
import '../models/shopping.dart';

/// Firestore access for shopping lists and their items.
class ShoppingRepository {
  ShoppingRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _lists(String uid) => _firestore
      .collection(AppConstants.colUsers)
      .doc(uid)
      .collection(AppConstants.colShoppingLists);

  CollectionReference<Map<String, dynamic>> _items(String uid, String listId) =>
      _lists(uid).doc(listId).collection(AppConstants.colShoppingItems);

  Stream<List<ShoppingList>> watchLists(String uid) => _lists(uid)
      .orderBy(AppConstants.fieldCreatedAt, descending: true)
      .snapshots()
      .map((s) => s.docs.map(ShoppingList.fromFirestore).toList());

  Stream<ShoppingList?> watchList(String uid, String id) =>
      _lists(uid).doc(id).snapshots().map((d) =>
          d.exists && d.data() != null ? ShoppingList.fromFirestore(d) : null);

  Stream<List<ShoppingItem>> watchItems(String uid, String listId) =>
      _items(uid, listId)
          .orderBy(AppConstants.fieldCreatedAt)
          .limit(300)
          .snapshots()
          .map((s) =>
              ShoppingItem.sorted(s.docs.map(ShoppingItem.fromFirestore)));

  Future<String> createList(String uid, String name) async {
    final problem = validateListName(name);
    if (problem != null) throw ValidationException(problem);
    return _guard('create list', () async {
      final ref = await _lists(uid).add({
        'name': name.trim(),
        AppConstants.fieldCreatedAt: FieldValue.serverTimestamp(),
        AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
      return ref.id;
    });
  }

  Future<void> renameList(String uid, String listId, String name) async {
    final problem = validateListName(name);
    if (problem != null) throw ValidationException(problem);
    await _guard('rename list', () => _lists(uid).doc(listId).update({
          'name': name.trim(),
          AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
        }));
  }

  /// Deletes every item, then the list (a batch holds up to 500 writes,
  /// and lists are limited to 300 items).
  Future<void> deleteList(String uid, String listId) async {
    await _guard('delete list', () async {
      final items = await _items(uid, listId).get();
      final batch = _firestore.batch();
      for (final doc in items.docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_lists(uid).doc(listId));
      await batch.commit();
    });
  }

  Future<void> saveItem(String uid, String listId, ShoppingItem item) async {
    final problem = item.validate();
    if (problem != null) throw ValidationException(problem);
    final data = {
      ...item.toFirestore(),
      'name': item.name.trim(),
      'unit': item.unit.trim(),
    };
    await _guard('save item', () async {
      if (item.id.isEmpty) {
        await _items(uid, listId).add({
          ...data,
          AppConstants.fieldCreatedAt: FieldValue.serverTimestamp(),
          AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
        });
      } else {
        await _items(uid, listId).doc(item.id).update({
          ...data,
          AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> setPurchased(
      String uid, String listId, String itemId, bool purchased) {
    return _guard('update item', () => _items(uid, listId).doc(itemId).update({
          'isPurchased': purchased,
          AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
        }));
  }

  Future<void> deleteItem(String uid, String listId, String itemId) {
    return _guard(
        'delete item', () => _items(uid, listId).doc(itemId).delete());
  }

  /// Removes all purchased items in one batch.
  Future<int> clearPurchased(String uid, String listId) {
    return _guard('clear items', () async {
      final done =
          await _items(uid, listId).where('isPurchased', isEqualTo: true).get();
      final batch = _firestore.batch();
      for (final doc in done.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      return done.docs.length;
    });
  }

  Future<T> _guard<T>(String action, Future<T> Function() body) async {
    try {
      return await body();
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to $action.');
    }
  }
}

final shoppingRepositoryProvider = Provider<ShoppingRepository>((ref) {
  return ShoppingRepository();
});
