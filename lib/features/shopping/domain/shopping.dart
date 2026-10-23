import 'package:cloud_firestore/cloud_firestore.dart';

/// A named shopping list.
///
/// Firestore path: users/{userId}/shoppingLists/{listId}
/// Fields: name (1–40), createdAt, updatedAt
///
/// Item counts are NOT stored on the list; they are counted live from the
/// items, so they can never drift out of sync.
class ShoppingList {
  const ShoppingList({this.id = '', required this.name, this.createdAt});

  final String id;
  final String name;
  final DateTime? createdAt;

  factory ShoppingList.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ShoppingList(
      id: doc.id,
      name: d['name'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

/// One item on a list.
///
/// Firestore path: users/{userId}/shoppingLists/{listId}/items/{itemId}
/// Ownership comes from the parent path; security rules also require the
/// parent list to exist.
///
/// Fields: name (1–60), quantity (int 1–9999), unit (≤ 12, e.g. "kg"),
///         isPurchased (bool), createdAt, updatedAt
class ShoppingItem {
  const ShoppingItem({
    this.id = '',
    required this.name,
    this.quantity = 1,
    this.unit = '',
    this.isPurchased = false,
    this.createdAt,
  });

  final String id;
  final String name;
  final int quantity;
  final String unit;
  final bool isPurchased;
  final DateTime? createdAt;

  String get quantityLabel => unit.isEmpty ? '×$quantity' : '$quantity $unit';

  factory ShoppingItem.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return ShoppingItem(
      id: doc.id,
      name: d['name'] as String? ?? '',
      quantity: (d['quantity'] as num?)?.toInt() ?? 1,
      unit: d['unit'] as String? ?? '',
      isPurchased: d['isPurchased'] as bool? ?? false,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'isPurchased': isPurchased,
      };

  String? validate() {
    if (name.trim().isEmpty || name.trim().length > 60) {
      return 'Item name must be 1–60 characters.';
    }
    if (quantity < 1 || quantity > 9999) {
      return 'Quantity must be between 1 and 9999.';
    }
    if (unit.length > 12) return 'Unit must be 12 characters or fewer.';
    return null;
  }

  ShoppingItem copyWith({
    String? name,
    int? quantity,
    String? unit,
    bool? isPurchased,
  }) =>
      ShoppingItem(
        id: id,
        name: name ?? this.name,
        quantity: quantity ?? this.quantity,
        unit: unit ?? this.unit,
        isPurchased: isPurchased ?? this.isPurchased,
        createdAt: createdAt,
      );

  /// Unpurchased first, then oldest first within each group.
  static List<ShoppingItem> sorted(Iterable<ShoppingItem> items) =>
      items.toList()
        ..sort((a, b) {
          if (a.isPurchased != b.isPurchased) return a.isPurchased ? 1 : -1;
          final ca = a.createdAt, cb = b.createdAt;
          if (ca == null || cb == null) return a.name.compareTo(b.name);
          return ca.compareTo(cb);
        });
}

String? validateListName(String name) =>
    name.trim().isEmpty || name.trim().length > 40
        ? 'List name must be 1–40 characters.'
        : null;
