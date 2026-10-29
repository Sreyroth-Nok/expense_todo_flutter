import 'package:flutter/material.dart';

import 'app_snack_bar.dart';
import '../services/limit_alert_policy.dart';
import '../models/spending_limit.dart';

/// Shows fired limit alerts inside the app as well.
///
/// This is what makes alerts work even when notification permission is
/// denied. When both limits fire at once, the most severe one is shown.
void showLimitAlerts(BuildContext context, List<LimitAlert> alerts) {
  if (alerts.isEmpty || !context.mounted) return;
  final worst = alerts.reduce(
    (a, b) => b.level.isMoreSevereThan(a.level) ? b : a,
  );
  final extra = alerts.length > 1 ? ' (+${alerts.length - 1} more)' : '';
  final message = '${worst.title}. ${worst.body}$extra';
  if (worst.level == LimitLevel.exceeded) {
    AppSnackBar.error(context, message);
  } else {
    AppSnackBar.warning(context, message);
  }
}
