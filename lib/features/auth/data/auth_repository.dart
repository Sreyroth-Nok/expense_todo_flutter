import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/firebase_error_mapper.dart';
import '../../../core/l10n/l10n.dart';
import '../../../shared/models/notification_preferences.dart';
import '../../../shared/models/user_profile.dart';
import '../../settings/data/account_data_service.dart';

/// Abstracts all Firebase Authentication and user-profile operations.
///
/// The UI layer must never import [FirebaseAuth] or [FirebaseFirestore]
/// directly. All auth calls go through this repository.
class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  // ── Auth state stream ──────────────────────────────────────────
  /// Emits [User] objects as the auth state changes (login / logout).
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// The currently authenticated [User], or null if signed out.
  User? get currentUser => _auth.currentUser;

  // ── Registration ───────────────────────────────────────────────
  /// Creates a new account and writes the user profile to Firestore.
  ///
  /// Throws [AuthException] for auth errors, [DatabaseException] for
  /// Firestore errors.
  Future<UserProfile> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update Firebase Auth display name immediately.
      await credential.user!.updateDisplayName(displayName.trim());

      final profile = await _createUserProfile(
        uid: credential.user!.uid,
        email: email.trim(),
        displayName: displayName.trim(),
        locale: currentLanguageCode(),
      );

      return profile;
    } on FirebaseAuthException catch (e) {
      throw FirebaseErrorMapper.fromAuth(e);
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to save user profile.');
    }
  }

  // ── Login ──────────────────────────────────────────────────────
  /// Signs in with email and password.
  ///
  /// Throws [AuthException] on failure.
  Future<User> login({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      return credential.user!;
    } on FirebaseAuthException catch (e) {
      throw FirebaseErrorMapper.fromAuth(e);
    }
  }

  // ── Google sign-in ─────────────────────────────────────────────
  /// Optional override: `flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=...`
  /// Normally not needed — on Android the web client ID is read from
  /// google-services.json (`default_web_client_id`), on iOS from
  /// GoogleService-Info.plist.
  static const _serverClientIdOverride =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
  static bool _googleInitialized = false;

  Future<void> _initGoogle() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId:
          _serverClientIdOverride.isEmpty ? null : _serverClientIdOverride,
    );
    _googleInitialized = true;
  }

  /// Shows the Google account picker and returns a Firebase credential.
  ///
  /// Throws [AuthCancelledException] when the user closes the picker.
  Future<OAuthCredential> _googleCredential() async {
    final l = currentL10n;
    final GoogleSignInAccount account;
    try {
      await _initGoogle();
      account = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled ||
          e.code == GoogleSignInExceptionCode.interrupted) {
        throw const AuthCancelledException();
      }
      Logger().w('Google sign-in error: ${e.code} ${e.description}');
      if (e.code == GoogleSignInExceptionCode.clientConfigurationError ||
          e.code == GoogleSignInExceptionCode.providerConfigurationError) {
        throw AuthException(l.authGoogleNotConfigured);
      }
      throw AuthException(l.authGoogleFailed);
    } catch (e) {
      // e.g. "CredentialManager requires a serverClientId" when Google
      // sign-in has not been enabled in Firebase yet.
      Logger().w('Google sign-in setup error: $e');
      throw AuthException(l.authGoogleNotConfigured);
    }
    final idToken = account.authentication.idToken;
    if (idToken == null) throw AuthException(l.authGoogleNotConfigured);
    return GoogleAuthProvider.credential(idToken: idToken);
  }

  /// Signs in (or signs up) with a Google account. Creates the Firestore
  /// profile on the first sign-in.
  Future<User> signInWithGoogle() async {
    final credential = await _googleCredential();
    try {
      final result = await _auth.signInWithCredential(credential);
      final user = result.user!;
      await _ensureProfile(user);
      return user;
    } on FirebaseAuthException catch (e) {
      throw FirebaseErrorMapper.fromAuth(e);
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to save user profile.');
    }
  }

  /// True when the account has an email + password (false for Google-only
  /// accounts, which have no LifeMate password to change).
  bool get hasPassword =>
      _auth.currentUser?.providerData.any((p) => p.providerId == 'password') ??
      false;

  Future<void> _ensureProfile(User user) async {
    final doc =
        await _firestore.collection(AppConstants.colUsers).doc(user.uid).get();
    if (doc.exists) return;
    final email = user.email ?? '';
    var name = (user.displayName?.trim().isNotEmpty ?? false)
        ? user.displayName!.trim()
        : email.split('@').first;
    if (name.length > 50) name = name.substring(0, 50);
    await _createUserProfile(
      uid: user.uid,
      email: email,
      displayName: name,
      locale: currentLanguageCode(),
    );
  }

  // ── Logout ─────────────────────────────────────────────────────
  Future<void> logout() async {
    await _auth.signOut();
    // Also forget the Google account, so the picker appears next time.
    if (_googleInitialized) {
      try {
        await GoogleSignIn.instance.signOut();
      } catch (_) {}
    }
  }

  // ── Forgot password ────────────────────────────────────────────
  /// Sends a password-reset email to [email].
  ///
  /// Does not throw if the email is not registered (Firebase behaviour),
  /// so this is safe to call without revealing whether an address exists.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
    } on FirebaseAuthException catch (e) {
      throw FirebaseErrorMapper.fromAuth(e);
    }
  }

  // ── Change password ────────────────────────────────────────────
  /// Re-authenticates the user and sets a new password.
  ///
  /// Requires the current password to satisfy Firebase's recent-login rule.
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw const AuthException('You must be logged in to change your password.');
    }

    try {
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      throw FirebaseErrorMapper.fromAuth(e);
    }
  }

  // ── Delete account ─────────────────────────────────────────────
  /// Re-authenticates, deletes ALL of the user's Firestore data (every
  /// collection and sub-collection), then deletes the Firebase Auth account.
  ///
  /// Order matters: re-authentication happens first so a wrong password
  /// never deletes anything. If deleting the Auth account itself fails
  /// afterwards (very rare), the data is already gone and the user can
  /// simply try again.
  ///
  /// Pass [password] for email accounts; for Google-only accounts leave it
  /// null and the Google account picker confirms the user's identity.
  Future<void> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) {
      throw AuthException(currentL10n.authRequiresRecentLogin);
    }

    try {
      final AuthCredential credential = password != null
          ? EmailAuthProvider.credential(email: user.email!, password: password)
          : await _googleCredential();
      await user.reauthenticateWithCredential(credential);

      await AccountDataService(_firestore).deleteAllUserData(user.uid);
      await user.delete();
      if (_googleInitialized) {
        try {
          await GoogleSignIn.instance.disconnect();
        } catch (_) {}
      }
    } on FirebaseAuthException catch (e) {
      throw FirebaseErrorMapper.fromAuth(e);
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to delete account data.');
    }
  }

  // ── Profile ────────────────────────────────────────────────────
  /// Fetches the [UserProfile] for the currently authenticated user.
  Future<UserProfile?> fetchCurrentProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    try {
      final doc = await _firestore
          .collection(AppConstants.colUsers)
          .doc(user.uid)
          .get();

      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromFirestore(doc);
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to load profile.');
    }
  }

  /// Updates the display name in Firestore and in Firebase Auth.
  Future<void> updateDisplayName(String name) async {
    final user = _auth.currentUser;
    if (user == null) throw AuthException(currentL10n.authRequiresRecentLogin);
    try {
      await user.updateDisplayName(name.trim());
      await _updateProfileFields(user.uid, {'displayName': name.trim()});
    } on FirebaseAuthException catch (e) {
      throw FirebaseErrorMapper.fromAuth(e);
    }
  }

  /// Saves preference fields (locale, currency, timeZone, ...).
  Future<void> updatePreferences(
    String uid, {
    String? locale,
    String? currency,
    String? timeZone,
    NotificationPreferences? notificationPreferences,
  }) {
    return _updateProfileFields(uid, {
      'locale': ?locale,
      'currency': ?currency,
      'timeZone': ?timeZone,
      if (notificationPreferences != null)
        'notificationPreferences': notificationPreferences.toMap(),
    });
  }

  Future<void> _updateProfileFields(String uid, Map<String, Object> fields) async {
    if (fields.isEmpty) return;
    try {
      await _firestore.collection(AppConstants.colUsers).doc(uid).update({
        ...fields,
        AppConstants.fieldUpdatedAt: FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      throw DatabaseException(e.message ?? 'Failed to save settings.');
    }
  }

  /// Streams the [UserProfile] document so the UI reacts to changes in real time.
  Stream<UserProfile?> profileStream(String uid) {
    return _firestore
        .collection(AppConstants.colUsers)
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return UserProfile.fromFirestore(doc);
    });
  }

  // ── Helpers ────────────────────────────────────────────────────
  Future<UserProfile> _createUserProfile({
    required String uid,
    required String email,
    required String displayName,
    String locale = 'en',
  }) async {
    final now = DateTime.now().toUtc();
    final profile = UserProfile(
      uid: uid,
      displayName: displayName,
      email: email,
      locale: locale,
      createdAt: now,
      updatedAt: now,
    );

    await _firestore
        .collection(AppConstants.colUsers)
        .doc(uid)
        .set({
      ...profile.toFirestore(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return profile;
  }
}

// ── Riverpod providers ────────────────────────────────────────────

/// Singleton [AuthRepository] accessible anywhere in the widget tree.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

/// Streams the raw Firebase [User] auth state.
///
/// [AsyncValue.loading] = still determining session
/// [AsyncValue.data(null)] = signed out
/// [AsyncValue.data(user)] = signed in
final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// Whether the signed-in account has an email + password (false for
/// Google-only accounts).
final hasPasswordProvider = Provider<bool>((ref) {
  ref.watch(authStateProvider);
  return ref.watch(authRepositoryProvider).hasPassword;
});

/// The signed-in user's uid, or null when signed out.
///
/// Every user-scoped Firestore provider watches this, so all data streams
/// restart (or stop) automatically on login / logout.
final currentUidProvider = Provider<String?>((ref) {
  return ref.watch(authStateProvider).value?.uid;
});

/// Live [UserProfile] of the signed-in user (null when signed out or the
/// profile document does not exist yet).
final currentUserProfileProvider = StreamProvider<UserProfile?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(authRepositoryProvider).profileStream(uid);
});
