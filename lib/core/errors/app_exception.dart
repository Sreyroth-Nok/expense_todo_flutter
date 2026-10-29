/// Typed exception hierarchy for LifeMate.
///
/// All errors that propagate out of the data layer must be wrapped in
/// one of these concrete types so the UI can present readable messages
/// without depending on Firebase or platform-specific exception classes.
sealed class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => '$runtimeType: $message';
}

/// Authentication errors (wrong password, user not found, etc.)
final class AuthException extends AppException {
  const AuthException(super.message);
}

/// Firestore read / write errors.
final class DatabaseException extends AppException {
  const DatabaseException(super.message);
}

/// Validation errors raised before hitting the backend.
final class ValidationException extends AppException {
  const ValidationException(super.message);
}

/// Network / connectivity errors.
final class NetworkException extends AppException {
  const NetworkException(super.message);
}

/// The user closed a sign-in dialog (e.g. Google account picker). Not an
/// error to show — the UI simply stays where it is.
final class AuthCancelledException extends AppException {
  const AuthCancelledException() : super('Sign-in cancelled.');
}

/// Catch-all for unexpected errors.
final class UnknownException extends AppException {
  const UnknownException(super.message);
}
