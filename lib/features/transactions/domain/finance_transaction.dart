import 'package:cloud_firestore/cloud_firestore.dart';

/// Whether money came in or went out.
enum TransactionType {
  income,
  expense;

  static TransactionType fromName(String? name) =>
      name == 'income' ? TransactionType.income : TransactionType.expense;

  String get label => this == income ? 'Income' : 'Expense';
}

/// One income or expense record.
///
/// Named `FinanceTransaction` to avoid clashing with Firestore's own
/// `Transaction` class.
///
/// Firestore path: users/{userId}/transactions/{transactionId}
///
/// Fields:
///   type              – 'income' | 'expense'
///   amountMinorUnits  – int > 0, amount in minor units (see Money)
///   currency          – ISO code, e.g. 'USD'
///   categoryId        – id of a doc in users/{userId}/categories
///   categoryName      – snapshot of the category name, so history still
///                       reads well if the category is renamed/deleted
///   description       – optional note, max 200 chars ('' when empty)
///   date              – Timestamp of when the money moved
///   createdAt         – server timestamp
///   updatedAt         – server timestamp
class FinanceTransaction {
  const FinanceTransaction({
    this.id = '',
    required this.type,
    required this.amountMinor,
    required this.currency,
    required this.categoryId,
    required this.categoryName,
    this.description = '',
    required this.date,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final TransactionType type;
  final int amountMinor;
  final String currency;
  final String categoryId;
  final String categoryName;
  final String description;
  final DateTime date;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isExpense => type == TransactionType.expense;
  bool get isIncome => type == TransactionType.income;

  /// Positive for income, negative for expenses — handy for net totals.
  int get signedAmountMinor => isIncome ? amountMinor : -amountMinor;

  factory FinanceTransaction.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return FinanceTransaction(
      id: doc.id,
      type: TransactionType.fromName(data['type'] as String?),
      amountMinor: (data['amountMinorUnits'] as num?)?.toInt() ?? 0,
      currency: data['currency'] as String? ?? 'USD',
      categoryId: data['categoryId'] as String? ?? '',
      categoryName: data['categoryName'] as String? ?? 'Uncategorized',
      description: data['description'] as String? ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  /// Editable fields only. Timestamps are added by the repository as
  /// server timestamps.
  Map<String, dynamic> toFirestore() => {
        'type': type.name,
        'amountMinorUnits': amountMinor,
        'currency': currency,
        'categoryId': categoryId,
        'categoryName': categoryName,
        'description': description,
        'date': Timestamp.fromDate(date),
      };

  FinanceTransaction copyWith({
    String? id,
    TransactionType? type,
    int? amountMinor,
    String? currency,
    String? categoryId,
    String? categoryName,
    String? description,
    DateTime? date,
  }) =>
      FinanceTransaction(
        id: id ?? this.id,
        type: type ?? this.type,
        amountMinor: amountMinor ?? this.amountMinor,
        currency: currency ?? this.currency,
        categoryId: categoryId ?? this.categoryId,
        categoryName: categoryName ?? this.categoryName,
        description: description ?? this.description,
        date: date ?? this.date,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
