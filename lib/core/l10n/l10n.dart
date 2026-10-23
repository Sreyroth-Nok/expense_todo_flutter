import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

export '../../l10n/app_localizations.dart';

/// Short access to translations inside widgets: `context.l10n.navHome`.
extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Language codes LifeMate is translated into.
const supportedLanguageCodes = ['en', 'km'];

/// The language currently used by the app ('en' or 'km').
///
/// [Intl.defaultLocale] is set by the App widget whenever the language
/// changes, so this also works where there is no BuildContext.
String currentLanguageCode() {
  final code = Intl.getCurrentLocale().split(RegExp('[_-]')).first;
  return supportedLanguageCodes.contains(code) ? code : 'en';
}

/// Translations for code without a BuildContext, such as form validators
/// and error mappers.
AppLocalizations get currentL10n =>
    lookupAppLocalizations(Locale(currentLanguageCode()));
