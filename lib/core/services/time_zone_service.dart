import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:logger/logger.dart';

import '../../features/auth/data/auth_repository.dart';

/// The phone's IANA time zone, e.g. "Asia/Phnom_Penh".
///
/// DESIGN NOTE: LifeMate uses the phone's time zone for every "day" and
/// "month" boundary (Dart's `DateTime` local time). A separate in-app
/// time-zone override would need every date in the app to be converted,
/// which is error-prone, and phones already switch zones automatically
/// when travelling. The zone is saved to the profile so trusted backend
/// code (e.g. a future scheduled Cloud Function) knows the user's zone.
final deviceTimeZoneProvider = FutureProvider<String>((ref) async {
  try {
    return (await FlutterTimezone.getLocalTimezone()).identifier;
  } catch (e) {
    Logger().w('Could not read the device time zone: $e');
    return DateTime.now().timeZoneName;
  }
});

/// Copies the phone's time zone to the profile when they differ. Watched
/// by the main shell while signed in.
final timeZoneSyncProvider = FutureProvider<void>((ref) async {
  final uid = ref.watch(currentUidProvider);
  final profile = ref.watch(currentUserProfileProvider).value;
  if (uid == null || profile == null) return;
  final zone = await ref.watch(deviceTimeZoneProvider.future);
  if (zone.isNotEmpty && zone != profile.timeZone) {
    try {
      await ref
          .read(authRepositoryProvider)
          .updatePreferences(uid, timeZone: zone);
    } catch (e) {
      Logger().w('Time zone sync failed: $e');
    }
  }
});
