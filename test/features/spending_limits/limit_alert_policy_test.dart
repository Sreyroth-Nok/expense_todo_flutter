import 'package:flutter_test/flutter_test.dart';
import 'package:lifemate/services/limit_alert_policy.dart';
import 'package:lifemate/models/spending_limit.dart';

void main() {
  AlertDecision decide(LimitLevel current, LimitLevel? last,
          {bool enabled = true}) =>
      LimitAlertPolicy.decide(
        current: current,
        lastNotified: last,
        alertsEnabled: enabled,
      );

  test('notifies once when a level is first reached', () {
    final d = decide(LimitLevel.warning, null);
    expect(d.notify, isTrue);
    expect(d.levelToStore, LimitLevel.warning);
  });

  test('does not repeat for the same unchanged condition', () {
    expect(decide(LimitLevel.exceeded, LimitLevel.exceeded).notify, isFalse);
  });

  test('notifies again when the condition gets more severe', () {
    expect(decide(LimitLevel.exceeded, LimitLevel.warning).notify, isTrue);
  });

  test('a drop is stored silently so re-crossing alerts again', () {
    final drop = decide(LimitLevel.ok, LimitLevel.exceeded);
    expect(drop.notify, isFalse);
    expect(drop.levelToStore, LimitLevel.ok);
    expect(decide(LimitLevel.exceeded, drop.levelToStore).notify, isTrue);
  });

  test('ok never notifies', () {
    expect(decide(LimitLevel.ok, null).notify, isFalse);
  });

  test('notifications disabled: never notifies, state untouched', () {
    final d = decide(LimitLevel.exceeded, LimitLevel.warning, enabled: false);
    expect(d.notify, isFalse);
    expect(d.levelToStore, LimitLevel.warning);
  });
}
