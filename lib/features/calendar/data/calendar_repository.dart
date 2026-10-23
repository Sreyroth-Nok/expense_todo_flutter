import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/utils/date_utils.dart';
import '../domain/calendar_event.dart';

/// Firestore access for users/{userId}/calendarEvents.
class CalendarRepository {
  CalendarRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _col(String uid) => _firestore
      .collection(AppConstants.colUsers)
      .doc(uid)
      .collection(AppConstants.colCalendarEvents);

  /// Events overlapping [range].
  ///
  /// Firestore cannot filter "start < rangeEnd AND end > rangeStart" with
  /// a single-field index, so we query by start time only, reaching back
  /// [CalendarEvent.maxDurationDays] (the longest allowed event), then
  /// keep the overlapping ones in memory.
  Stream<List<CalendarEvent>> watchRange(String uid, DateRange range) {
    final from = range.start
        .subtract(const Duration(days: CalendarEvent.maxDurationDays));
    return _col(uid)
        .where('startAt', isGreaterThanOrEqualTo: Timestamp.fromDate(from))
        .where('startAt', isLessThan: Timestamp.fromDate(range.end))
        .orderBy('startAt')
        .snapshots()
        .map((s) => s.docs
            .map(CalendarEvent.fromFirestore)
            .where((e) => e.overlaps(range))
            .toList());
  }

  Stream<CalendarEvent?> watchOne(String uid, String id) =>
      _col(uid).doc(id).snapshots().map((d) =>
          d.exists && d.data() != null ? CalendarEvent.fromFirestore(d) : null);

  Future<void> save(String uid, CalendarEvent e) async {
    final problem = e.validate();
    if (problem != null) throw ValidationException(problem);
    try {
      if (e.id.isEmpty) {
        await _col(uid).add({
          ...e.toFirestore(),
          AppConstants.fieldCreatedAt: FieldValue.serverTimestamp(),
          AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
        });
      } else {
        await _col(uid).doc(e.id).update({
          ...e.toFirestore(),
          AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
        });
      }
    } on FirebaseException catch (err) {
      throw DatabaseException(err.message ?? 'Failed to save event.');
    }
  }

  Future<void> delete(String uid, String id) async {
    try {
      await _col(uid).doc(id).delete();
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to delete event.');
    }
  }
}

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository();
});
