import '../l10n/l10n.dart';
import 'money.dart';

/// Input validation helpers used across all forms.
///
/// Each function returns null when the value is valid or a descriptive
/// error string when it is not. This matches Flutter's [FormField.validator]
/// signature directly.
abstract final class AppValidators {
  // ── Email ──────────────────────────────────────────────────────
  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) {
      return currentL10n.validationEmailRequired;
    }
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$',
    );
    if (!emailRegex.hasMatch(value.trim())) {
      return currentL10n.validationEmailInvalid;
    }
    return null;
  }

  // ── Password ───────────────────────────────────────────────────
  static String? password(String? value) {
    if (value == null || value.isEmpty) {
      return currentL10n.validationPasswordRequired;
    }
    if (value.length < 8) {
      return currentL10n.validationPasswordLength;
    }
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return currentL10n.validationPasswordUppercase;
    }
    if (!RegExp(r'[0-9]').hasMatch(value)) {
      return currentL10n.validationPasswordNumber;
    }
    return null;
  }

  /// Validates that a [confirmPassword] matches [original].
  static String? Function(String?) confirmPassword(String original) {
    return (String? value) {
      if (value == null || value.isEmpty) {
        return currentL10n.validationConfirmPassword;
      }
      if (value != original) return currentL10n.validationPasswordsDontMatch;
      return null;
    };
  }

  // ── Display name ───────────────────────────────────────────────
  static String? displayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return currentL10n.validationNameRequired;
    }
    if (value.trim().length < 2) {
      return currentL10n.validationNameTooShort;
    }
    if (value.trim().length > 50) {
      return currentL10n.validationNameTooLong;
    }
    return null;
  }

  // ── Required generic ───────────────────────────────────────────
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return currentL10n.validationRequired(fieldName);
    }
    return null;
  }

  // ── Positive amount ────────────────────────────────────────────
  /// Validates a money amount for [currencyCode] without using `double`,
  /// so no rounding can happen (see [Money.parseToMinor]).
  static String? Function(String?) amount(String currencyCode) {
    return (String? value) {
      if (value == null || value.trim().isEmpty) {
        return currentL10n.validationAmountRequired;
      }
      final minor = Money.parseToMinor(value, currencyCode);
      if (minor == null) {
        final decimals = Currencies.of(currencyCode).decimals;
        return decimals == 0
            ? currentL10n.validationAmountWhole(currencyCode)
            : currentL10n.validationAmountDecimals(decimals);
      }
      if (minor <= 0) return currentL10n.validationAmountPositive;
      return null;
    };
  }
}
