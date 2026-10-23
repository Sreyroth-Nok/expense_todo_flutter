import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_utils.dart';
import '../domain/finance_transaction.dart';
import '../domain/transaction_filter.dart';

/// All Firestore access for users/{userId}/transactions.
///
/// Queries used (see firestore.indexes.json):
///   • date range, ordered by date desc        → single-field index (automatic)
///   • type == X + date range, ordered by date → composite (type, date desc)
class TransactionRepository {
  TransactionRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  /// Safety cap for "all time" history so a huge account never downloads
  /// every transaction at once.
  static const int allTimeLimit = 500;

  CollectionReference<Map<String, dynamic>> _col(String uid) => _firestore
      .collection(AppConstants.colUsers)
      .doc(uid)
      .collection(AppConstants.colTransactions);

  Query<Map<String, dynamic>> _query(String uid, TransactionFilter filter) {
    Query<Map<String, dynamic>> q = _col(uid);
    if (filter.type != null) {
      q = q.where(AppConstants.fieldType, isEqualTo: filter.type!.name);
    }
    final range = filter.range;
    if (range != null) {
      q = q
          .where(AppConstants.fieldDate,
              isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
          .where(AppConstants.fieldDate,
              isLessThan: Timestamp.fromDate(range.end));
    }
    q = q.orderBy(AppConstants.fieldDate, descending: true);
    if (range == null) q = q.limit(allTimeLimit);
    return q;
  }

  /// Live list of transactions matching the server-side part of [filter]
  /// (date range and type), newest first.
  Stream<List<FinanceTransaction>> watch(String uid, TransactionFilter filter) {
    return _query(uid, filter).snapshots().map(
          (snap) => snap.docs.map(FinanceTransaction.fromFirestore).toList(),
        );
  }

  /// One-off read of expenses inside [range]. Used by the spending-limit
  /// checker right after a write.
  Future<List<FinanceTransaction>> fetchExpenses(
    String uid,
    DateRange range,
  ) async {
    try {
      final snap = await _query(
        uid,
        TransactionFilter(range: range, type: TransactionType.expense),
      ).get();
      return snap.docs.map(FinanceTransaction.fromFirestore).toList();
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to load expenses.');
    }
  }

  Stream<FinanceTransaction?> watchOne(String uid, String id) {
    return _col(uid).doc(id).snapshots().map(
          (doc) => doc.exists && doc.data() != null
              ? FinanceTransaction.fromFirestore(doc)
              : null,
        );
  }

  /// Creates a transaction and returns its new id.
  Future<String> add(String uid, FinanceTransaction tx) async {
    try {
      final ref = _col(uid).doc();
      await ref.set({
        ...tx.toFirestore(),
        AppConstants.fieldCreatedAt: FieldValue.serverTimestamp(),
        AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
      return ref.id;
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to save transaction.');
    }
  }

  /// Updates the editable fields. `createdAt` is never touched.
  Future<void> update(String uid, FinanceTransaction tx) async {
    if (tx.id.isEmpty) {
      throw const ValidationException('Cannot update a transaction without id.');
    }
    try {
      await _col(uid).doc(tx.id).update({
        ...tx.toFirestore(),
        AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to update transaction.');
    }
  }

  Future<void> delete(String uid, String id) async {
    try {
      await _col(uid).doc(id).delete();
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to delete transaction.');
    }
  }
}

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});
