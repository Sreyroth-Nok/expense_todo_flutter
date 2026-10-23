import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lifemate/core/l10n/l10n.dart';
import 'package:lifemate/features/settings/presentation/account_screens.dart';

Widget _app(Widget child, {String lang = 'en'}) => MaterialApp(
      locale: Locale(lang),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: child),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);
  tearDown(() => Intl.defaultLocale = null);

  testWidgets('change password: mismatch and same-password errors',
      (tester) async {
    var submitted = false;
    await tester.pumpWidget(_app(ChangePasswordForm(
      onSubmit: (_, _) async => submitted = true,
    )));

    await tester.enterText(find.byKey(const Key('currentPassword')), 'Secret123');
    await tester.enterText(find.byKey(const Key('newPassword')), 'Secret123');
    await tester.enterText(find.byKey(const Key('confirmPassword')), 'Other123');
    await tester.ensureVisible(find.text('Change password').last);
    await tester.tap(find.text('Change password').last);
    await tester.pump();

    expect(find.text('The new password must be different from the current one.'),
        findsOneWidget);
    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(submitted, isFalse);
  });

  testWidgets('change password: valid input is submitted', (tester) async {
    String? next;
    await tester.pumpWidget(_app(ChangePasswordForm(
      onSubmit: (_, n) async => next = n,
    )));
    await tester.enterText(find.byKey(const Key('currentPassword')), 'Secret123');
    await tester.enterText(find.byKey(const Key('newPassword')), 'NewSecret9');
    await tester.enterText(find.byKey(const Key('confirmPassword')), 'NewSecret9');
    await tester.ensureVisible(find.text('Change password').last);
    await tester.tap(find.text('Change password').last);
    await tester.pump();
    expect(next, 'NewSecret9');
  });

  testWidgets('the form is shown in Khmer when Khmer is selected',
      (tester) async {
    Intl.defaultLocale = 'km';
    await tester.pumpWidget(
        _app(ChangePasswordForm(onSubmit: (_, _) async {}), lang: 'km'));
    await tester.pumpAndSettle();
    expect(find.text('ពាក្យសម្ងាត់បច្ចុប្បន្ន'), findsOneWidget);
    expect(find.text('ប្តូរពាក្យសម្ងាត់'), findsWidgets);
  });
}
