import '../models/spending_limit.dart';

/// What to do after re-evaluating a limit.
class AlertDecision {
  const AlertDecision({required this.notify, required this.levelToStore});

  /// True when the user should receive a notification now.
  final bool notify;

  /// The level to remember for this period (used for de-duplication).
  final LimitLevel levelToStore;
}

/// Decides when a spending-limit alert is sent, without duplicates.
///
/// For each limit and period (e.g. daily limit on 2026-10-23) we remember
/// the last level we told the user about:
///
///   • Level got MORE severe (ok → warning → reached → exceeded): notify once.
///   • Level unchanged: do nothing (no repeated alerts).
///   • Level dropped (expense edited lower or deleted): remember the lower
///     level silently, so crossing the threshold again is a new condition.
///   • A new day / month has a new period key, so state resets naturally.
///   • Alerts disabled: never notify and leave the stored level untouched.
abstract final class LimitAlertPolicy {
  static AlertDecision decide({
    required LimitLevel current,
    required LimitLevel? lastNotified,
    required bool alertsEnabled,
  }) {
    final stored = lastNotified ?? LimitLevel.ok;
    if (!alertsEnabled) {
      return AlertDecision(notify: false, levelToStore: stored);
    }
    if (current.isMoreSevereThan(stored)) {
      return AlertDecision(notify: true, levelToStore: current);
    }
    return AlertDecision(notify: false, levelToStore: current);
  }
}

/// A notification-worthy limit event, shown as a device notification and
/// as an in-app message.
class LimitAlert {
  const LimitAlert({
    required this.period,
    required this.level,
    required this.title,
    required this.body,
  });

  final LimitPeriod period;
  final LimitLevel level;
  final String title;
  final String body;
}
