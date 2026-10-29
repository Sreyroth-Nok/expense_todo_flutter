import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_service.dart';
import '../models/notification_preferences.dart';
import '../services/auth_repository.dart';

/// Account-level actions used by the Settings screens.
///
/// Logging out and deleting the account also cancel this phone's scheduled
/// reminders, so the next person using the phone never sees them.
class SettingsActions {
  SettingsActions(this._ref);
  final Ref _ref;

  AuthRepository get _auth => _ref.read(authRepositoryProvider);

  String _uid() {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) throw StateError('Not signed in');
    return uid;
  }

  Future<void> logOut() async {
    await _ref.read(notificationServiceProvider).cancelScheduled();
    await _auth.logout();
  }

  /// Re-authenticates (with [password], or with Google when it is null),
  /// deletes all data and the account.
  Future<void> deleteAccount(String? password) async {
    await _auth.deleteAccount(password: password);
    await _ref.read(notificationServiceProvider).cancelScheduled();
  }

  Future<void> changePassword(String current, String next) =>
      _auth.changePassword(currentPassword: current, newPassword: next);

  Future<void> updateDisplayName(String name) => _auth.updateDisplayName(name);

  Future<void> setCurrency(String code) =>
      _auth.updatePreferences(_uid(), currency: code);

  Future<void> setNotificationPreferences(NotificationPreferences prefs) =>
      _auth.updatePreferences(_uid(), notificationPreferences: prefs);
}

final settingsActionsProvider = Provider<SettingsActions>((ref) {
  return SettingsActions(ref);
});
