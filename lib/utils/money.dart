import 'package:intl/intl.dart';

/// Describes a currency the app supports.
///
/// [decimals] is the number of minor-unit digits used for storage:
///   USD 2 → $12.34 is stored as 1234
///   KHR 0 → 12,000៛ is stored as 12000
///
/// Note: ISO 4217 lists KHR with 2 decimals, but riel sub-units are not
/// used in practice, so LifeMate stores whole riel (0 decimals).
class CurrencyInfo {
  const CurrencyInfo({
    required this.code,
    required this.symbol,
    required this.decimals,
    this.symbolAfter = false,
  });

  final String code;
  final String symbol;
  final int decimals;
  final bool symbolAfter;
}

/// The list of currencies a user can choose for a transaction or limit.
abstract final class Currencies {
  static const usd = CurrencyInfo(code: 'USD', symbol: '\$', decimals: 2);
  static const khr =
      CurrencyInfo(code: 'KHR', symbol: '៛', decimals: 0, symbolAfter: true);
  static const thb = CurrencyInfo(code: 'THB', symbol: '฿', decimals: 2);
  static const eur = CurrencyInfo(code: 'EUR', symbol: '€', decimals: 2);

  static const List<CurrencyInfo> supported = [usd, khr, thb, eur];

  /// Looks up a currency by ISO code. Unknown codes fall back to a
  /// 2-decimal currency that displays its code instead of a symbol.
  static CurrencyInfo of(String code) {
    for (final c in supported) {
      if (c.code == code) return c;
    }
    return CurrencyInfo(code: code, symbol: '$code ', decimals: 2);
  }
}

/// Decimal-safe money helpers.
///
/// LifeMate stores every monetary value as an **integer number of minor
/// units** (cents for USD, whole riel for KHR) in the Firestore field
/// `amountMinorUnits`. Integers never suffer from floating-point
/// rounding (0.1 + 0.2 != 0.3), so totals are always exact.
///
/// Never convert amounts to `double` for calculations.
abstract final class Money {
  /// Largest accepted amount in major units (e.g. $999,999,999).
  static const int maxMajorUnits = 999999999;

  /// Parses user input such as "12", "12.5", "1,234.56" into minor units.
  ///
  /// Returns null when the text is not a valid amount for [currencyCode]
  /// (e.g. too many decimals, letters, or a negative sign). Parsing is done
  /// on the string digits, never through `double`.
  static int? parseToMinor(String input, String currencyCode) {
    final decimals = Currencies.of(currencyCode).decimals;
    final text = input.trim().replaceAll(',', '');
    if (text.isEmpty) return null;

    final match = RegExp(r'^(\d+)(?:\.(\d*))?$').firstMatch(text);
    if (match == null) return null;

    final wholePart = match.group(1)!;
    final fractionPart = match.group(2) ?? '';
    if (fractionPart.length > decimals) return null;
    if (wholePart.length > maxMajorUnits.toString().length) return null;

    final whole = int.parse(wholePart);
    if (whole > maxMajorUnits) return null;

    final paddedFraction = fractionPart.padRight(decimals, '0');
    final fraction = paddedFraction.isEmpty ? 0 : int.parse(paddedFraction);
    return whole * _pow10(decimals) + fraction;
  }

  /// Formats minor units for display, e.g. 123456 USD → "$1,234.56".
  ///
  /// Set [signed] to prefix a "+" for positive values (negatives always
  /// show "-").
  static String format(int minorUnits, String currencyCode,
      {bool signed = false}) {
    final info = Currencies.of(currencyCode);
    final sign = minorUnits < 0 ? '-' : (signed && minorUnits > 0 ? '+' : '');
    final number = _formatAbs(minorUnits.abs(), info.decimals);
    return info.symbolAfter
        ? '$sign$number${info.symbol}'
        : '$sign${info.symbol}$number';
  }

  /// Converts minor units back to plain editable text, e.g. 1250 → "12.50".
  static String toInputText(int minorUnits, String currencyCode) {
    final decimals = Currencies.of(currencyCode).decimals;
    final abs = minorUnits.abs();
    final whole = abs ~/ _pow10(decimals);
    if (decimals == 0) return '$whole';
    final fraction =
        (abs % _pow10(decimals)).toString().padLeft(decimals, '0');
    return '$whole.$fraction';
  }

  static String _formatAbs(int abs, int decimals) {
    final whole = abs ~/ _pow10(decimals);
    final grouped = NumberFormat.decimalPattern('en').format(whole);
    if (decimals == 0) return grouped;
    final fraction =
        (abs % _pow10(decimals)).toString().padLeft(decimals, '0');
    return '$grouped.$fraction';
  }

  static int _pow10(int exponent) {
    var result = 1;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }
}
