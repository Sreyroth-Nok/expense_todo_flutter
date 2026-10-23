import 'package:cloud_firestore/cloud_firestore.dart';

/// A savings target, e.g. "New laptop — $800 by March".
///
/// Firestore path: users/{userId}/savingsGoals/{goalId}
///
/// Fields:
///   name                    – 1–40 chars
///   currency                – ISO code
///   targetAmountMinorUnits  – int > 0
///   savedAmountMinorUnits   – int ≥ 0; changed ONLY together with a
///                             contribution document (see repository)
///   targetDate              – Timestamp or null
///   isCompleted             – bool, set by the user
///   reminderDayOfMonth      – null or 1–28: monthly "time to save" reminder
///                             at 09:00 on that day
///   createdAt / updatedAt   – server timestamps
///
/// Ordinary income is never treated as savings automatically; the user
/// records each contribution explicitly.
class SavingsGoal {
  const SavingsGoal({
    this.id = '',
    required this.name,
    required this.currency,
    required this.targetMinor,
    this.savedMinor = 0,
    this.targetDate,
    this.isCompleted = false,
    this.reminderDayOfMonth,
  });

  final String id;
  final String name;
  final String currency;
  final int targetMinor;
  final int savedMinor;
  final DateTime? targetDate;
  final bool isCompleted;
  final int? reminderDayOfMonth;

  int get remainingMinor =>
      savedMinor >= targetMinor ? 0 : targetMinor - savedMinor;
  bool get isTargetReached => savedMinor >= targetMinor;

  /// For progress bars only.
  double get progress => targetMinor == 0 ? 0 : savedMinor / targetMinor;

  /// Whole percent, rounded down using integer maths (never shows 100%
  /// before the target is really reached).
  int get percent => targetMinor == 0 ? 0 : (savedMinor * 100) ~/ targetMinor;

  /// Days until the target date (negative when overdue), or null.
  int? daysLeft(DateTime now) {
    final t = targetDate;
    if (t == null) return null;
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(t.year, t.month, t.day).difference(today).inDays;
  }

  factory SavingsGoal.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return SavingsGoal(
      id: doc.id,
      name: d['name'] as String? ?? '',
      currency: d['currency'] as String? ?? 'USD',
      targetMinor: (d['targetAmountMinorUnits'] as num?)?.toInt() ?? 0,
      savedMinor: (d['savedAmountMinorUnits'] as num?)?.toInt() ?? 0,
      targetDate: (d['targetDate'] as Timestamp?)?.toDate(),
      isCompleted: d['isCompleted'] as bool? ?? false,
      reminderDayOfMonth: (d['reminderDayOfMonth'] as num?)?.toInt(),
    );
  }

  /// Editable fields (savedAmount is handled by the repository).
  Map<String, dynamic> toFirestore() => {
        'name': name,
        'currency': currency,
        'targetAmountMinorUnits': targetMinor,
        'targetDate': targetDate == null ? null : Timestamp.fromDate(targetDate!),
        'isCompleted': isCompleted,
        'reminderDayOfMonth': reminderDayOfMonth,
      };

  String? validate() {
    if (name.trim().isEmpty || name.trim().length > 40) {
      return 'Name must be 1–40 characters.';
    }
    if (targetMinor <= 0) return 'Target must be greater than zero.';
    final day = reminderDayOfMonth;
    if (day != null && (day < 1 || day > 28)) {
      return 'Reminder day must be between 1 and 28.';
    }
    return null;
  }
}

/// Money added to (positive) or taken from (negative) a goal.
///
/// Firestore path: users/{uid}/savingsGoals/{goalId}/contributions/{id}
/// Fields: amountMinorUnits (int ≠ 0), note (≤100), date, createdAt
class SavingsContribution {
  const SavingsContribution({
    this.id = '',
    required this.amountMinor,
    this.note = '',
    required this.date,
  });

  final String id;
  final int amountMinor;
  final String note;
  final DateTime date;

  bool get isWithdrawal => amountMinor < 0;

  factory SavingsContribution.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data()!;
    return SavingsContribution(
      id: doc.id,
      amountMinor: (d['amountMinorUnits'] as num?)?.toInt() ?? 0,
      note: d['note'] as String? ?? '',
      date: (d['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
