import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/utils/date_utils.dart';

/// A calendar event.
///
/// Firestore path: users/{userId}/calendarEvents/{eventId}
///
/// Fields:
///   title                  – 1–100 chars
///   startAt / endAt        – Timestamps; end is EXCLUSIVE. All-day events
///                            run from midnight of the first day to
///                            midnight after the last day.
///   allDay                 – bool
///   location               – ≤ 100 chars
///   notes                  – ≤ 500 chars
///   reminderMinutesBefore  – null (no reminder) or 0–10080
///   createdAt / updatedAt
///
/// Events may last at most [maxDurationDays]; this lets the month view
/// find events that started before the month with one bounded query.
class CalendarEvent {
  const CalendarEvent({
    this.id = '',
    required this.title,
    required this.startAt,
    required this.endAt,
    this.allDay = false,
    this.location = '',
    this.notes = '',
    this.reminderMinutesBefore,
  });

  final String id;
  final String title;
  final DateTime startAt;
  final DateTime endAt;
  final bool allDay;
  final String location;
  final String notes;
  final int? reminderMinutesBefore;

  static const int maxDurationDays = 31;

  /// Last day the event appears on (inclusive), for display.
  DateTime get lastDay => endAt.subtract(const Duration(milliseconds: 1));

  bool overlaps(DateRange range) =>
      startAt.isBefore(range.end) && endAt.isAfter(range.start);

  bool occursOn(DateTime day) => overlaps(AppDateUtils.dayOf(day));

  /// When to notify, or null. All-day events notify relative to 9:00 AM
  /// on their first day.
  DateTime? get reminderAt {
    final minutes = reminderMinutesBefore;
    if (minutes == null) return null;
    final base = allDay
        ? DateTime(startAt.year, startAt.month, startAt.day, 9)
        : startAt;
    return base.subtract(Duration(minutes: minutes));
  }

  factory CalendarEvent.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return CalendarEvent(
      id: doc.id,
      title: d['title'] as String? ?? '',
      startAt: (d['startAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endAt: (d['endAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      allDay: d['allDay'] as bool? ?? false,
      location: d['location'] as String? ?? '',
      notes: d['notes'] as String? ?? '',
      reminderMinutesBefore: (d['reminderMinutesBefore'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'startAt': Timestamp.fromDate(startAt),
        'endAt': Timestamp.fromDate(endAt),
        'allDay': allDay,
        'location': location,
        'notes': notes,
        'reminderMinutesBefore': reminderMinutesBefore,
      };

  String? validate() {
    if (title.trim().isEmpty || title.trim().length > 100) {
      return 'Title must be 1–100 characters.';
    }
    if (!endAt.isAfter(startAt)) return 'The end must be after the start.';
    if (endAt.difference(startAt).inHours > maxDurationDays * 24 + 1) {
      return 'An event can last at most $maxDurationDays days.';
    }
    if (location.length > 100) return 'Location must be 100 characters or fewer.';
    if (notes.length > 500) return 'Notes must be 500 characters or fewer.';
    final m = reminderMinutesBefore;
    if (m != null && (m < 0 || m > 10080)) return 'Invalid reminder time.';
    return null;
  }
}
