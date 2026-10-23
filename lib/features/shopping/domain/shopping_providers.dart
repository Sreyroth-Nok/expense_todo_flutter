import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_repository.dart';
import '../data/shopping_repository.dart';
import 'shopping.dart';

final shoppingListsProvider = StreamProvider<List<ShoppingList>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(shoppingRepositoryProvider).watchLists(uid);
});

final shoppingListByIdProvider =
    StreamProvider.autoDispose.family<ShoppingList?, String>((ref, id) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(shoppingRepositoryProvider).watchList(uid, id);
});

final shoppingItemsProvider = StreamProvider.autoDispose
    .family<List<ShoppingItem>, String>((ref, listId) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(shoppingRepositoryProvider).watchItems(uid, listId);
});
