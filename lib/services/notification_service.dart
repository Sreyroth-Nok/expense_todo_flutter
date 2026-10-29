import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:logger/logger.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/scheduled_notice.dart';

/// Shows and schedules on-device notifications with
/// `flutter_local_notifications`.
///
/// • Immediate alerts: spending limits (Phase 3).
/// • Scheduled notices: reminders, bill reminders, task due times, event
///   reminders and savings reminders (Phase 5). They are handed to the
///   operating system's alarm service, so they fire even when the app is
///   closed, and are restored after a reboot (see AndroidManifest.xml).
///
/// If the user denies permission nothing breaks: reminders and alerts
/// remain visible inside the app.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;
  final _log = Logger();
  bool _initialized = false;
  Future<void> _scheduleQueue = Future.value();

  /// iOS allows at most 64 pending notifications per app; we keep a margin.
  static const int maxScheduled = 50;

  static const _limitChannel = AndroidNotificationDetails(
    'spending_limits',
    'Spending limit alerts',
    channelDescription: 'Warns you when you approach or pass a spending limit.',
    importance: Importance.high,
    priority: Priority.high,
  );

  static const _reminderChannel = AndroidNotificationDetails(
    'reminders',
    'Reminders',
    channelDescription: 'Reminders, bills, task due times and events.',
    importance: Importance.high,
    priority: Priority.high,
  );

  /// Safe to call more than once. Never throws: notification failures must
  /// not stop the app from starting.
  Future<void> initialize() async {
    if (_initialized || kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      try {
        final info = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(info.identifier));
      } catch (e) {
        // One-off notices still fire at the right instant (we convert the
        // exact moment); only repeating notices may shift by the offset.
        _log.w('Could not read device time zone, using UTC: $e');
      }
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          // Don't ask for permission at launch — ask in context.
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _initialized = true;
    } catch (e) {
      _log.w('Notifications unavailable: $e');
    }
  }

  /// Asks the OS for notification permission (Android 13+, iOS).
  /// Returns true when notifications may be shown.
  Future<bool> requestPermission() async {
    await initialize();
    if (!_initialized) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.requestNotificationsPermission() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return await ios.requestPermissions(
              alert: true,
              badge: true,
              sound: true,
            ) ??
            false;
      }
    } catch (e) {
      _log.w('Notification permission request failed: $e');
    }
    return false;
  }

  /// Whether the OS currently allows LifeMate to show notifications.
  Future<bool> areNotificationsAllowed() async {
    await initialize();
    if (!_initialized) return false;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        return await android.areNotificationsEnabled() ?? false;
      }
      final ios = _plugin.resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin>();
      if (ios != null) {
        return (await ios.checkPermissions())?.isEnabled ?? false;
      }
    } catch (e) {
      _log.w('Could not read notification permission: $e');
    }
    return false;
  }

  /// Android 12+: whether reminders can fire at the exact minute.
  /// Returns null on platforms where this does not apply (iOS).
  Future<bool?> canUseExactAlarms() async {
    await initialize();
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return null;
    return await android.canScheduleExactNotifications() ?? false;
  }

  /// Opens the Android "Alarms & reminders" permission screen.
  Future<void> requestExactAlarms() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestExactAlarmsPermission();
  }

  /// Cancels every scheduled reminder (used on logout / account deletion).
  Future<void> cancelScheduled() => replaceScheduled(const []);

  /// Shows a spending-limit notification. [id] should be stable per limit
  /// so a newer alert replaces the older one instead of stacking.
  Future<void> showLimitAlert({
    required int id,
    required String title,
    required String body,
  }) async {
    await initialize();
    if (!_initialized) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: _limitChannel,
          iOS: DarwinNotificationDetails(),
        ),
      );
    } catch (e) {
      // e.g. permission denied — the in-app message still informs the user.
      _log.w('Could not show notification: $e');
    }
  }

  /// Replaces ALL scheduled notices with [notices].
  ///
  /// Called whenever reminders, tasks, events or goals change, from any
  /// device (the Firestore streams update), so the device schedule always
  /// matches the database. Calls are queued so they never overlap.
  Future<void> replaceScheduled(List<ScheduledNotice> notices) {
    _scheduleQueue = _scheduleQueue
        .then((_) => _replaceScheduled(notices))
        .catchError((Object e) => _log.w('Scheduling failed: $e'));
    return _scheduleQueue;
  }

  Future<void> _replaceScheduled(List<ScheduledNotice> notices) async {
    await initialize();
    if (!_initialized) return;

    // Cancel what we scheduled before (ids >= firstScheduledId only, so
    // immediate spending-limit alerts are left alone).
    final pending = await _plugin.pendingNotificationRequests();
    for (final p in pending) {
      if (p.id >= ScheduledNotice.firstScheduledId) {
        await _plugin.cancel(id: p.id);
      }
    }

    final mode = await _androidScheduleMode();
    final now = DateTime.now();
    final upcoming = notices.where((n) => n.at.isAfter(now)).toList()
      ..sort((a, b) => a.at.compareTo(b.at));

    for (final n in upcoming.take(maxScheduled)) {
      await _plugin.zonedSchedule(
        id: n.id,
        title: n.title,
        body: n.body,
        scheduledDate: tz.TZDateTime.from(n.at, tz.local),
        notificationDetails: const NotificationDetails(
          android: _reminderChannel,
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: mode,
        matchDateTimeComponents: switch (n.repeat) {
          NoticeRepeat.none => null,
          NoticeRepeat.daily => DateTimeComponents.time,
          NoticeRepeat.weekly => DateTimeComponents.dayOfWeekAndTime,
          NoticeRepeat.monthly => DateTimeComponents.dayOfMonthAndTime,
        },
      );
    }
  }

  /// Exact alarms when the user allowed them (Android 12+ setting),
  /// otherwise inexact — Android may then deliver a few minutes late.
  Future<AndroidScheduleMode> _androidScheduleMode() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return AndroidScheduleMode.exactAllowWhileIdle;
    final exact = await android.canScheduleExactNotifications() ?? false;
    return exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
