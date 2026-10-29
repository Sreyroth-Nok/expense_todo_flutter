import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/date_utils.dart';

/// The two independent limit periods.
enum LimitPeriod {
  daily,
  monthly;

  static LimitPeriod? tryParse(String? name) {
    for (final p in values) {
      if (p.name == name) return p;
    }
    return null;
  }

  String get label => this == daily ? 'Daily limit' : 'Monthly limit';

  /// The local calendar period containing [now].
  DateRange rangeAt(DateTime now) =>
      this == daily ? AppDateUtils.dayOf(now) : AppDateUtils.monthOf(now);

  /// Stable id of the current period, e.g. "2026-10-23" or "2026-10".
  /// Used to reset alert state when a new day / month starts.
  String periodKeyAt(DateTime now) =>
      this == daily ? AppDateUtils.dayKey(now) : AppDateUtils.monthKey(now);
}

/// A user's daily or monthly spending limit.
///
/// Firestore path: users/{userId}/spendingLimits/{period}
/// The document id IS the period ('daily' or 'monthly'), so each user can
/// have at most one limit of each kind.
///
/// Fields:
///   period                   – 'daily' | 'monthly' (must equal the doc id)
///   amountMinorUnits         – int > 0
///   currency                 – only expenses in this currency count
///   alertsEnabled            – bool
///   warningThresholdPercent  – int 1–99, or null for "no early warning"
///   createdAt / updatedAt    – server timestamps
class SpendingLimit {
  const SpendingLimit({
    required this.period,
    required this.amountMinor,
    required this.currency,
    this.alertsEnabled = true,
    this.warningThresholdPercent,
  });

  final LimitPeriod period;
  final int amountMinor;
  final String currency;
  final bool alertsEnabled;
  final int? warningThresholdPercent;

  static SpendingLimit? fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    final period = LimitPeriod.tryParse(doc.id);
    if (data == null || period == null) return null;
    return SpendingLimit(
      period: period,
      amountMinor: (data['amountMinorUnits'] as num?)?.toInt() ?? 0,
      currency: data['currency'] as String? ?? 'USD',
      alertsEnabled: data['alertsEnabled'] as bool? ?? true,
      warningThresholdPercent:
          (data['warningThresholdPercent'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'period': period.name,
        'amountMinorUnits': amountMinor,
        'currency': currency,
        'alertsEnabled': alertsEnabled,
        'warningThresholdPercent': warningThresholdPercent,
      };

  SpendingLimit copyWith({
    int? amountMinor,
    String? currency,
    bool? alertsEnabled,
    int? warningThresholdPercent,
    bool clearWarningThreshold = false,
  }) =>
      SpendingLimit(
        period: period,
        amountMinor: amountMinor ?? this.amountMinor,
        currency: currency ?? this.currency,
        alertsEnabled: alertsEnabled ?? this.alertsEnabled,
        warningThresholdPercent: clearWarningThreshold
            ? null
            : (warningThresholdPercent ?? this.warningThresholdPercent),
      );
}

/// How close spending is to a limit. Order matters: later = more severe.
enum LimitLevel {
  ok,
  warning,
  reached,
  exceeded;

  static LimitLevel fromName(String? name) =>
      values.firstWhere((l) => l.name == name, orElse: () => LimitLevel.ok);

  bool isMoreSevereThan(LimitLevel other) => index > other.index;
}
