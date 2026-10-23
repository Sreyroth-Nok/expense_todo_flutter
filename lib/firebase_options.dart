// GENERATED FILE — DO NOT EDIT MANUALLY.
//
// This file is a PLACEHOLDER.
// It will be REPLACED when you run `flutterfire configure`.
//
// How to replace this file:
//   1. Complete the Firebase Console setup (see Phase 1 plan).
//   2. Run: flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
//   3. Commit the generated firebase_options.dart to version control.
//      (It does NOT contain secret keys — it is safe to commit.)

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// ⚠️  PLACEHOLDER — Replace with real values from `flutterfire configure`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // ⚠️  Replace all placeholder values below with your real Firebase config.
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'PLACEHOLDER_API_KEY',
    appId: 'PLACEHOLDER_APP_ID',
    messagingSenderId: '704724146672',
    projectId: 'lifemate-34a2b',
    authDomain: 'lifemate-34a2b.firebaseapp.com',
    storageBucket: 'lifemate-34a2b.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCUvW6nHoID9jzUSs9fOoWCe-viQpD3iyM',
    appId: '1:704724146672:android:d7ee20e96c287840c8a535',
    messagingSenderId: '704724146672',
    projectId: 'lifemate-34a2b',
    storageBucket: 'lifemate-34a2b.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'PLACEHOLDER_IOS_API_KEY',
    appId: 'PLACEHOLDER_IOS_APP_ID',
    messagingSenderId: '704724146672',
    projectId: 'lifemate-34a2b',
    storageBucket: 'lifemate-34a2b.firebasestorage.app',
    iosBundleId: 'com.lifemate.app',
  );
}
