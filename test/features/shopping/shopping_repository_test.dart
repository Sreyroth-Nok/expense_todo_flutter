import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifemate/core/errors/app_exception.dart';
import 'package:lifemate/features/shopping/data/shopping_repository.dart';
import 'package:lifemate/features/shopping/domain/shopping.dart';

void main() {
  const uid = 'u1';
  late FakeFirebaseFirestore db;
  late ShoppingRepository repo;

  setUp(() {
    db = FakeFirebaseFirestore();
    repo = ShoppingRepository(firestore: db);
  });

  Future<List<ShoppingItem>> items(String listId) =>
      repo.watchItems(uid, listId).first;

  test('add, edit, check off and remove items', () async {
    final listId = await repo.createList(uid, 'Market');
    await repo.saveItem(uid, listId, const ShoppingItem(name: 'Rice', quantity: 2, unit: 'kg'));
    await repo.saveItem(uid, listId, const ShoppingItem(name: 'Eggs', quantity: 12));

    var list = await items(listId);
    expect(list.map((i) => i.name), containsAll(['Rice', 'Eggs']));

    final rice = list.firstWhere((i) => i.name == 'Rice');
    await repo.saveItem(uid, listId, rice.copyWith(quantity: 3));
    await repo.setPurchased(uid, listId, rice.id, true);

    list = await items(listId);
    final updated = list.firstWhere((i) => i.id == rice.id);
    expect(updated.quantity, 3);
    expect(updated.isPurchased, isTrue);
    // Unpurchased items are listed first.
    expect(list.first.name, 'Eggs');

    await repo.deleteItem(uid, listId, rice.id);
    expect((await items(listId)).map((i) => i.name), ['Eggs']);
  });

  test('clear purchased removes only purchased items', () async {
    final listId = await repo.createList(uid, 'Market');
    await repo.saveItem(uid, listId, const ShoppingItem(name: 'A', isPurchased: true));
    await repo.saveItem(uid, listId, const ShoppingItem(name: 'B'));
    expect(await repo.clearPurchased(uid, listId), 1);
    expect((await items(listId)).single.name, 'B');
  });

  test('deleting a list deletes its items', () async {
    final listId = await repo.createList(uid, 'Market');
    await repo.saveItem(uid, listId, const ShoppingItem(name: 'A'));
    await repo.deleteList(uid, listId);
    expect(await repo.watchList(uid, listId).first, isNull);
    final left = await db.collection('users/$uid/shoppingLists/$listId/items').get();
    expect(left.docs, isEmpty);
  });

  test('validation', () async {
    expect(() => repo.createList(uid, '  '), throwsA(isA<ValidationException>()));
    final listId = await repo.createList(uid, 'Market');
    expect(
      () => repo.saveItem(uid, listId, const ShoppingItem(name: 'X', quantity: 0)),
      throwsA(isA<ValidationException>()),
    );
    expect(const ShoppingItem(name: 'Rice', quantity: 2, unit: 'kg').quantityLabel, '2 kg');
    expect(const ShoppingItem(name: 'Eggs', quantity: 12).quantityLabel, '×12');
  });
}
