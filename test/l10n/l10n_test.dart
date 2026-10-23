import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:lifemate/core/l10n/l10n.dart';
import 'package:lifemate/core/utils/validators.dart';

Map<String, dynamic> _arb(String code) =>
    jsonDecode(File('lib/l10n/app_$code.arb').readAsStringSync())
        as Map<String, dynamic>;

Set<String> _placeholders(String text) =>
    RegExp(r'\{(\w+)\}').allMatches(text).map((m) => m.group(1)!).toSet();

void main() {
  tearDown(() => Intl.defaultLocale = null);

  test('Khmer has a translation for every English key', () {
    final en = _arb('en');
    final km = _arb('km');
    final enKeys = en.keys.where((k) => !k.startsWith('@')).toSet();
    final kmKeys = km.keys.where((k) => !k.startsWith('@')).toSet();
    expect(kmKeys.difference(enKeys), isEmpty, reason: 'extra Khmer keys');
    expect(enKeys.difference(kmKeys), isEmpty, reason: 'missing Khmer keys');
  });

  test('translations keep the same {placeholders}', () {
    final en = _arb('en');
    final km = _arb('km');
    for (final key in en.keys.where((k) => !k.startsWith('@'))) {
      expect(_placeholders(km[key] as String), _placeholders(en[key] as String),
          reason: key);
    }
  });

  test('no Khmer value is left empty or identical to English by mistake', () {
    final en = _arb('en');
    final km = _arb('km');
    // Values that are legitimately the same in both languages.
    const same = {'@@locale', 'appName', 'fieldEmailHint'};
    for (final key in en.keys.where((k) => !k.startsWith('@'))) {
      expect((km[key] as String).trim(), isNotEmpty, reason: key);
      if (!same.contains(key)) {
        expect(km[key], isNot(en[key]), reason: '$key is not translated');
      }
    }
  });

  test('generated classes return both languages', () {
    expect(lookupAppLocalizations(const Locale('en')).navHome, 'Home');
    expect(lookupAppLocalizations(const Locale('km')).navHome, 'ទំព័រដើម');
    expect(lookupAppLocalizations(const Locale('km')).homeGreeting('Dara'),
        contains('Dara'));
  });

  test('validators follow the selected language (no BuildContext needed)', () {
    Intl.defaultLocale = 'en';
    expect(AppValidators.email(''), 'Email address is required.');
    Intl.defaultLocale = 'km';
    expect(currentLanguageCode(), 'km');
    expect(AppValidators.email(''), 'តម្រូវឱ្យបញ្ចូលអាសយដ្ឋានអ៊ីមែល។');
    expect(AppValidators.amount('KHR')('1.5'), contains('KHR'));
  });

  test('unsupported device languages fall back to English', () {
    Intl.defaultLocale = 'fr_FR';
    expect(currentLanguageCode(), 'en');
    expect(currentL10n.navHome, 'Home');
  });
}
