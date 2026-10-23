import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/l10n/locale_provider.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

/// Application entry point.
///
/// Before running the Flutter app:
///   1. Ensures widget binding is initialised.
///   2. Locks the app to portrait orientation.
///   3. Initialises Firebase using the generated firebase_options.dart.
///   4. Activates Firebase App Check (blocks requests from fake clients).
///   5. Loads SharedPreferences (saved language) and local notifications.
Future<void> main() async {
  // Required before any async work in main().
  WidgetsFlutterBinding.ensureInitialized();

  // Lock orientation to portrait on mobile devices.
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Configure the status bar to match the light theme.
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Initialise Firebase with the platform-specific options.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await _activateAppCheck();

  final prefs = await SharedPreferences.getInstance();

  // Create the Riverpod container up-front so services can be initialised
  // before the first frame. NotificationService.initialize never throws.
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  await container.read(notificationServiceProvider).initialize();

  runApp(
    // The provider scope is the root of the Riverpod dependency-injection tree.
    UncontrolledProviderScope(
      container: container,
      child: const App(),
    ),
  );
}

/// App Check proves requests come from the genuine LifeMate app.
///
/// • Release builds use Play Integrity (Android) and App Attest with a
///   DeviceCheck fallback (iOS).
/// • Debug builds use the debug provider: the first run prints a debug
///   token in the log, which you register in Firebase Console → App Check.
///
/// Requests are only BLOCKED once you press "Enforce" in the console, so
/// this is safe to ship before enforcement is switched on.
Future<void> _activateAppCheck() async {
  try {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: kDebugMode
          ? const AndroidDebugProvider()
          : const AndroidPlayIntegrityProvider(),
      providerApple: kDebugMode
          ? const AppleDebugProvider()
          : const AppleAppAttestWithDeviceCheckFallbackProvider(),
    );
  } catch (e) {
    // Never block app start; Firebase still works while not enforced.
    Logger().w('App Check activation failed: $e');
  }
}
