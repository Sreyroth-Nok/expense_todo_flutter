import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'core/l10n/l10n.dart';
import 'core/l10n/locale_provider.dart';
import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';

/// Root application widget.
///
/// Reads the [routerProvider] and [localeProvider] from Riverpod and
/// configures [MaterialApp.router] with the LifeMate theme and the
/// English / Khmer translations. Riverpod's provider scope is in main.dart.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    // Lets DateFormat and code without a BuildContext (validators, error
    // messages) follow the chosen language.
    Intl.defaultLocale = locale.languageCode;

    return MaterialApp.router(
      onGenerateTitle: (context) => context.l10n.appName,

      // ── Localization ───────────────────────────────────────────
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,

      // ── Theme ──────────────────────────────────────────────────
      theme: AppTheme.light,
      // darkTheme: AppTheme.dark,  // Prepared for a later release
      themeMode: ThemeMode.light,

      // ── Routing ────────────────────────────────────────────────
      routerConfig: router,

      // ── Misc ───────────────────────────────────────────────────
      debugShowCheckedModeBanner: false,
    );
  }
}
