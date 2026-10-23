import 'package:cloud_firestore/cloud_firestore.dart';

import 'finance_transaction.dart';

/// A user-owned category for grouping transactions.
///
/// Firestore path: users/{userId}/categories/{categoryId}
///
/// Fields:
///   name        – 1–30 chars
///   type        – 'income' | 'expense' (which transactions may use it)
///   iconKey     – key into the app's fixed icon set (category_visuals.dart)
///   colorValue  – ARGB int used for the icon badge
///   isDefault   – true for the starter categories created automatically
///   createdAt   – server timestamp
///   updatedAt   – server timestamp
class TransactionCategory {
  const TransactionCategory({
    this.id = '',
    required this.name,
    required this.type,
    required this.iconKey,
    required this.colorValue,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final TransactionType type;
  final String iconKey;
  final int colorValue;
  final bool isDefault;

  factory TransactionCategory.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return TransactionCategory(
      id: doc.id,
      name: data['name'] as String? ?? '',
      type: TransactionType.fromName(data['type'] as String?),
      iconKey: data['iconKey'] as String? ?? 'other',
      colorValue: (data['colorValue'] as num?)?.toInt() ?? 0xFF0F766E,
      isDefault: data['isDefault'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'type': type.name,
        'iconKey': iconKey,
        'colorValue': colorValue,
        'isDefault': isDefault,
      };

  TransactionCategory copyWith({
    String? name,
    String? iconKey,
    int? colorValue,
  }) =>
      TransactionCategory(
        id: id,
        name: name ?? this.name,
        type: type,
        iconKey: iconKey ?? this.iconKey,
        colorValue: colorValue ?? this.colorValue,
        isDefault: isDefault,
      );
}

/// Starter categories created for every new account.
///
/// They use fixed document ids, so creating them twice cannot produce
/// duplicates.
abstract final class DefaultCategories {
  static const List<TransactionCategory> all = [
    // Expense
    TransactionCategory(id: 'food', name: 'Food & Drinks', type: TransactionType.expense, iconKey: 'food', colorValue: 0xFFD97706, isDefault: true),
    TransactionCategory(id: 'transport', name: 'Transport', type: TransactionType.expense, iconKey: 'transport', colorValue: 0xFF2563EB, isDefault: true),
    TransactionCategory(id: 'shopping', name: 'Shopping', type: TransactionType.expense, iconKey: 'shopping', colorValue: 0xFFDB2777, isDefault: true),
    TransactionCategory(id: 'bills', name: 'Bills & Utilities', type: TransactionType.expense, iconKey: 'bills', colorValue: 0xFF7C3AED, isDefault: true),
    TransactionCategory(id: 'health', name: 'Health', type: TransactionType.expense, iconKey: 'health', colorValue: 0xFFDC2626, isDefault: true),
    TransactionCategory(id: 'entertainment', name: 'Entertainment', type: TransactionType.expense, iconKey: 'entertainment', colorValue: 0xFF0891B2, isDefault: true),
    TransactionCategory(id: 'education', name: 'Education', type: TransactionType.expense, iconKey: 'education', colorValue: 0xFF4F46E5, isDefault: true),
    TransactionCategory(id: 'other_expense', name: 'Other', type: TransactionType.expense, iconKey: 'other', colorValue: 0xFF6B7280, isDefault: true),
    // Income
    TransactionCategory(id: 'salary', name: 'Salary', type: TransactionType.income, iconKey: 'salary', colorValue: 0xFF16A34A, isDefault: true),
    TransactionCategory(id: 'business', name: 'Business', type: TransactionType.income, iconKey: 'business', colorValue: 0xFF0F766E, isDefault: true),
    TransactionCategory(id: 'gift', name: 'Gift', type: TransactionType.income, iconKey: 'gift', colorValue: 0xFFF0B429, isDefault: true),
    TransactionCategory(id: 'other_income', name: 'Other', type: TransactionType.income, iconKey: 'other', colorValue: 0xFF6B7280, isDefault: true),
  ];
}
