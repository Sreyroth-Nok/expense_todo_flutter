import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../utils/app_constants.dart';
import '../utils/app_exception.dart';
import '../models/spending_limit.dart';

/// Firestore access for spending limits and their alert state.
///
/// Paths:
///   users/{uid}/spendingLimits/{daily|monthly}
///   users/{uid}/notificationEvents/limit_{period}_{periodKey}
///
/// Alert state lives in `notificationEvents` (not in the limit document)
/// so editing a limit and recording an alert never overwrite each other.
class SpendingLimitRepository {
  SpendingLimitRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _firestore.collection(AppConstants.colUsers).doc(uid);

  CollectionReference<Map<String, dynamic>> _limits(String uid) =>
      _userDoc(uid).collection(AppConstants.colSpendingLimits);

  CollectionReference<Map<String, dynamic>> _events(String uid) =>
      _userDoc(uid).collection(AppConstants.colNotificationEvents);

  /// Live map of the user's configured limits (missing = not set).
  Stream<Map<LimitPeriod, SpendingLimit>> watchAll(String uid) {
    return _limits(uid).snapshots().map((snap) {
      final result = <LimitPeriod, SpendingLimit>{};
      for (final doc in snap.docs) {
        final limit = SpendingLimit.fromFirestore(doc);
        if (limit != null) result[limit.period] = limit;
      }
      return result;
    });
  }

  Future<Map<LimitPeriod, SpendingLimit>> fetchAll(String uid) async {
    try {
      final snap = await _limits(uid).get();
      final result = <LimitPeriod, SpendingLimit>{};
      for (final doc in snap.docs) {
        final limit = SpendingLimit.fromFirestore(doc);
        if (limit != null) result[limit.period] = limit;
      }
      return result;
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to load spending limits.');
    }
  }

  /// Creates or replaces a limit. [isNew] decides whether `createdAt` is
  /// written (security rules forbid changing it later).
  Future<void> save(
    String uid,
    SpendingLimit limit, {
    required bool isNew,
  }) async {
    try {
      final ref = _limits(uid).doc(limit.period.name);
      if (isNew) {
        await ref.set({
          ...limit.toFirestore(),
          AppConstants.fieldCreatedAt: FieldValue.serverTimestamp(),
          AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
        });
      } else {
        await ref.update({
          ...limit.toFirestore(),
          AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to save spending limit.');
    }
  }

  Future<void> delete(String uid, LimitPeriod period) async {
    try {
      await _limits(uid).doc(period.name).delete();
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to delete spending limit.');
    }
  }

  // ── Alert state (de-duplication) ───────────────────────────────

  static String alertEventId(LimitPeriod period, String periodKey) =>
      'limit_${period.name}_$periodKey';

  /// The last level the user was notified about in this period, or null.
  Future<LimitLevel?> fetchLastNotifiedLevel(
    String uid,
    LimitPeriod period,
    String periodKey,
  ) async {
    final doc = await _events(uid).doc(alertEventId(period, periodKey)).get();
    final level = doc.data()?['level'] as String?;
    return level == null ? null : LimitLevel.fromName(level);
  }

  Future<void> saveLastNotifiedLevel(
    String uid,
    LimitPeriod period,
    String periodKey,
    LimitLevel level,
  ) {
    return _events(uid).doc(alertEventId(period, periodKey)).set({
      'kind': 'spendingLimit',
      'period': period.name,
      'periodKey': periodKey,
      'level': level.name,
      AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
    });
  }
}

final spendingLimitRepositoryProvider =
    Provider<SpendingLimitRepository>((ref) {
  return SpendingLimitRepository();
});
