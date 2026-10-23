import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../core/services/scheduled_notice.dart';

enum ReminderKind {
  general,
  bill;

  static ReminderKind fromName(String? n) =>
      n == 'bill' ? ReminderKind.bill : ReminderKind.general;
}

enum ReminderStatus {
  pending,
  completed,
  dismissed;

  static ReminderStatus fromName(String? n) =>
      values.firstWhere((s) => s.name == n, orElse: () => ReminderStatus.pending);
}

/// A reminder or a bill reminder.
///
/// Firestore path: users/{userId}/reminders/{reminderId}
///
/// Fields:
///   title             – 1–100 chars
///   notes             – ≤ 300 chars
///   kind              – 'general' | 'bill'
///   remindAt          – Timestamp of the (next) occurrence
///   repeat            – 'none' | 'daily' | 'weekly' | 'monthly'
///   amountMinorUnits  – bills only, int > 0 or null
///   currency          – bills only, ISO code or null
///   status            – 'pending' | 'completed' | 'dismissed'
///   createdAt / updatedAt
class Reminder {
  const Reminder({
    this.id = '',
    required this.title,
    this.notes = '',
    this.kind = ReminderKind.general,
    required this.remindAt,
    this.repeat = NoticeRepeat.none,
    this.amountMinor,
    this.currency,
    this.status = ReminderStatus.pending,
  });

  final String id;
  final String title;
  final String notes;
  final ReminderKind kind;
  final DateTime remindAt;
  final NoticeRepeat repeat;
  final int? amountMinor;
  final String? currency;
  final ReminderStatus status;

  bool get isBill => kind == ReminderKind.bill;
  bool get isPending => status == ReminderStatus.pending;

  /// Next time this reminder fires, or null if it never will again.
  DateTime? nextAt(DateTime now) =>
      isPending ? repeat.nextOccurrence(remindAt, now) : null;

  /// One-off pending reminder whose time has passed.
  bool isOverdueAt(DateTime now) =>
      isPending && repeat == NoticeRepeat.none && remindAt.isBefore(now);

  /// "Done" / "Paid": one-off reminders become completed; repeating ones
  /// stay pending and move to the occurrence after the current one.
  Reminder completed(DateTime now) {
    if (repeat == NoticeRepeat.none) {
      return _copy(status: ReminderStatus.completed);
    }
    final after = (remindAt.isAfter(now) ? remindAt : now)
        .add(const Duration(minutes: 1));
    return _copy(remindAt: repeat.nextOccurrence(remindAt, after));
  }

  Reminder dismissed() => _copy(status: ReminderStatus.dismissed);
  Reminder reopened() => _copy(status: ReminderStatus.pending);

  factory Reminder.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return Reminder(
      id: doc.id,
      title: d['title'] as String? ?? '',
      notes: d['notes'] as String? ?? '',
      kind: ReminderKind.fromName(d['kind'] as String?),
      remindAt: (d['remindAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      repeat: NoticeRepeat.fromName(d['repeat'] as String?),
      amountMinor: (d['amountMinorUnits'] as num?)?.toInt(),
      currency: d['currency'] as String?,
      status: ReminderStatus.fromName(d['status'] as String?),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'title': title,
        'notes': notes,
        'kind': kind.name,
        'remindAt': Timestamp.fromDate(remindAt),
        'repeat': repeat.name,
        'amountMinorUnits': isBill ? amountMinor : null,
        'currency': isBill && amountMinor != null ? currency : null,
        'status': status.name,
      };

  String? validate() {
    if (title.trim().isEmpty || title.trim().length > 100) {
      return 'Title must be 1–100 characters.';
    }
    if (notes.length > 300) return 'Notes must be 300 characters or fewer.';
    if (amountMinor != null && amountMinor! <= 0) {
      return 'Bill amount must be greater than zero.';
    }
    return null;
  }

  Reminder _copy({DateTime? remindAt, ReminderStatus? status}) => Reminder(
        id: id,
        title: title,
        notes: notes,
        kind: kind,
        remindAt: remindAt ?? this.remindAt,
        repeat: repeat,
        amountMinor: amountMinor,
        currency: currency,
        status: status ?? this.status,
      );
}
