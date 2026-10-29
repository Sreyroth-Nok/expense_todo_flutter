import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/models/notification_preferences.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../../shared/widgets/app_states.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/settings_actions.dart';

/// Permission status, exact-alarm access (Android) and per-kind switches.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen>
    with WidgetsBindingObserver {
  bool? _allowed;
  bool? _exact;

  NotificationService get _service => ref.read(notificationServiceProvider);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-check when the user comes back from the phone's settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final allowed = await _service.areNotificationsAllowed();
    final exact = await _service.canUseExactAlarms();
    if (mounted) {
      setState(() {
        _allowed = allowed;
        _exact = exact;
      });
    }
  }

  Future<void> _save(NotificationPreferences prefs) async {
    try {
      await ref.read(settingsActionsProvider).setNotificationPreferences(prefs);
    } catch (e) {
      if (mounted) AppSnackBar.error(context, readableError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final prefs =
        ref.watch(currentUserProfileProvider).value?.notificationPreferences ??
            const NotificationPreferences();

    final switches = <(IconData, String, String, bool, NotificationPreferences Function(bool))>[
      (Icons.speed_rounded, l.notifySpendingLimits, l.notifySpendingLimitsDesc, prefs.spendingLimits,
          (v) => prefs.copyWith(spendingLimits: v)),
      (Icons.receipt_long_rounded, l.notifyReminders, l.notifyRemindersDesc, prefs.reminders,
          (v) => prefs.copyWith(reminders: v)),
      (Icons.task_alt_rounded, l.notifyTasks, l.notifyTasksDesc, prefs.tasks,
          (v) => prefs.copyWith(tasks: v)),
      (Icons.event_rounded, l.notifyEvents, l.notifyEventsDesc, prefs.events,
          (v) => prefs.copyWith(events: v)),
      (Icons.savings_rounded, l.notifySavings, l.notifySavingsDesc, prefs.savings,
          (v) => prefs.copyWith(savings: v)),
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l.notificationsTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Permission ───────────────────────────────────────────
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      _allowed == true
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_off_outlined,
                      color: _allowed == true
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                    const Gap(10),
                    Expanded(
                      child: Text(
                        _allowed == null
                            ? '…'
                            : _allowed!
                                ? l.notificationsPermissionOn
                                : l.notificationsPermissionOff,
                        style: AppTextStyles.titleMedium,
                      ),
                    ),
                  ],
                ),
                if (_allowed == false) ...[
                  const Gap(12),
                  ElevatedButton(
                    onPressed: () async {
                      await _service.requestPermission();
                      await _refresh();
                    },
                    child: Text(l.notificationsAllow),
                  ),
                  const Gap(8),
                  Text(l.notificationsBlockedHelp,
                      style: AppTextStyles.bodySmall),
                ],
              ],
            ),
          ),

          // ── Exact alarms (Android 12+) ───────────────────────────
          if (_exact == false) ...[
            const Gap(12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.notificationsExact, style: AppTextStyles.titleMedium),
                  const Gap(4),
                  Text(l.notificationsExactDesc, style: AppTextStyles.bodySmall),
                  const Gap(8),
                  TextButton(
                    onPressed: _service.requestExactAlarms,
                    child: Text(l.notificationsExactAllow),
                  ),
                ],
              ),
            ),
          ],
          const Gap(24),

          // ── Per-kind switches ────────────────────────────────────
          Text(l.notificationsCategories, style: AppTextStyles.titleLarge),
          const Gap(8),
          for (final (icon, title, desc, value, update) in switches)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.honey.withAlpha(40),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.warning, size: 20),
              ),
              value: value,
              activeThumbColor: AppColors.primary,
              title: Text(title, style: AppTextStyles.titleMedium),
              subtitle: Text(desc, style: AppTextStyles.bodySmall),
              onChanged: (v) => _save(update(v)),
            ),
          const Gap(12),
          Text(l.notificationsInAppNote, style: AppTextStyles.bodySmall),
        ],
      ),
    );
  }
}
