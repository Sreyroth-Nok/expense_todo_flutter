import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/l10n.dart';
import 'app_exception.dart';

/// Maps [FirebaseAuthException] error codes to readable [AuthException] messages.
///
/// Never expose raw Firebase error codes directly in the UI.
abstract final class FirebaseErrorMapper {
  static AuthException fromAuth(FirebaseAuthException e) {
    final l = currentL10n;
    final message = switch (e.code) {
      'user-not-found' => l.authUserNotFound,
      'wrong-password' => l.authWrongPassword,
      'invalid-credential' => l.authInvalidCredential,
      'email-already-in-use' => l.authEmailInUse,
      'weak-password' => l.authWeakPassword,
      'invalid-email' => l.authInvalidEmail,
      'user-disabled' => l.authUserDisabled,
      'too-many-requests' => l.authTooManyRequests,
      'operation-not-allowed' => l.authOperationNotAllowed,
      'requires-recent-login' => l.authRequiresRecentLogin,
      'network-request-failed' => l.authNetwork,
      'account-exists-with-different-credential' =>
        l.authAccountExistsDifferentCredential,
      _ => l.authGeneric(e.message ?? e.code),
    };
    return AuthException(message);
  }
}
