import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../data/auth_repository.dart';

// ── Auth action state ──────────────────────────────────────────────────────

/// State object for any auth action (login, register, etc.)
///
/// The UI observes this to show loading spinners and error messages.
class AuthActionState {
  const AuthActionState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  bool get hasError => errorMessage != null;

  AuthActionState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isSuccess,
  }) =>
      AuthActionState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
        isSuccess: isSuccess ?? this.isSuccess,
      );
}

// ── Login notifier ────────────────────────────────────────────────────────

class LoginNotifier extends Notifier<AuthActionState> {
  @override
  AuthActionState build() => const AuthActionState();

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).login(
            email: email,
            password: password,
          );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('AuthException: ', ''),
      );
      return false;
    }
  }
}

final loginProvider = NotifierProvider<LoginNotifier, AuthActionState>(
  LoginNotifier.new,
);

// ── Register notifier ─────────────────────────────────────────────────────

class RegisterNotifier extends Notifier<AuthActionState> {
  @override
  AuthActionState build() => const AuthActionState();

  Future<bool> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).register(
            email: email,
            password: password,
            displayName: displayName,
          );
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('AuthException: ', ''),
      );
      return false;
    }
  }
}

final registerProvider = NotifierProvider<RegisterNotifier, AuthActionState>(
  RegisterNotifier.new,
);

// ── Forgot password notifier ──────────────────────────────────────────────

class ForgotPasswordNotifier extends Notifier<AuthActionState> {
  @override
  AuthActionState build() => const AuthActionState();

  Future<bool> sendResetEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref
          .read(authRepositoryProvider)
          .sendPasswordResetEmail(email);
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceFirst('AuthException: ', ''),
      );
      return false;
    }
  }
}

final forgotPasswordProvider =
    NotifierProvider<ForgotPasswordNotifier, AuthActionState>(
  ForgotPasswordNotifier.new,
);

// ── Google sign-in notifier ───────────────────────────────────────────────

/// Signs in with Google. Closing the account picker is not treated as an
/// error. Navigation happens through GoRouter's auth redirect.
class GoogleSignInNotifier extends Notifier<AuthActionState> {
  @override
  AuthActionState build() => const AuthActionState();

  Future<bool> signIn() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      state = state.copyWith(isLoading: false, isSuccess: true);
      return true;
    } on AuthCancelledException {
      state = state.copyWith(isLoading: false);
      return false;
    } on AppException catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final googleSignInProvider =
    NotifierProvider<GoogleSignInNotifier, AuthActionState>(
  GoogleSignInNotifier.new,
);
