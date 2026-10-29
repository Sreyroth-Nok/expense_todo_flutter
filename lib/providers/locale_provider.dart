import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/auth_repository.dart';
import '../utils/app_constants.dart';
import '../l10n/l10n.dart';

/// SharedPreferences, loaded once in main() and injected with an override.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

/// The app language.
///
/// Priority: the signed-in user's profile (synced across devices) → the
/// last choice on this phone → the phone's language (Khmer or English).
/// The local copy means the login screen already uses the right language.
class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final prefs = ref.watch(sharedPreferencesProvider);

    ref.listen(currentUserProfileProvider, (_, next) {
      final code = next.value?.locale;
      if (code != null &&
          supportedLanguageCodes.contains(code) &&
          code != state.languageCode) {
        state = Locale(code);
        prefs.setString(AppConstants.prefSelectedLocale, code);
      }
    }, fireImmediately: true);

    final saved = prefs.getString(AppConstants.prefSelectedLocale);
    if (saved != null && supportedLanguageCodes.contains(saved)) {
      return Locale(saved);
    }
    final device = PlatformDispatcher.instance.locale.languageCode;
    return Locale(device == 'km' ? 'km' : 'en');
  }

  /// Changes the language now, remembers it on this phone, and saves it to
  /// the profile so other devices follow.
  Future<void> setLanguage(String code) async {
    if (!supportedLanguageCodes.contains(code)) return;
    state = Locale(code);
    await ref
        .read(sharedPreferencesProvider)
        .setString(AppConstants.prefSelectedLocale, code);
    final uid = ref.read(currentUidProvider);
    if (uid != null) {
      await ref.read(authRepositoryProvider).updatePreferences(uid, locale: code);
    }
  }
}

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);
