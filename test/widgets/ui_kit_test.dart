import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lifemate/l10n/l10n.dart';
import 'package:lifemate/widgets/google_sign_in_button.dart';
import 'package:lifemate/screens/dashboard/main_shell.dart';
import 'package:lifemate/widgets/ui_kit.dart';

Widget _app(Widget child) => ProviderScope(
      child: MaterialApp(
        locale: const Locale('en'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(body: Center(child: child)),
      ),
    );

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('PillTabs reports the tapped option', (tester) async {
    String? picked;
    await tester.pumpWidget(_app(PillTabs<String>(
      options: const ['All', 'Income', 'Expenses'],
      selected: 'All',
      labelOf: (s) => s,
      onSelected: (s) => picked = s,
    )));
    await tester.tap(find.text('Expenses'));
    expect(picked, 'Expenses');
  });

  testWidgets('FloatingNavBar shows only the selected label and switches tabs',
      (tester) async {
    var index = 0;
    await tester.pumpWidget(_app(StatefulBuilder(
      builder: (context, setState) => FloatingNavBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          NavItem(Icons.home_outlined, Icons.home_rounded, 'Home'),
          NavItem(Icons.settings_outlined, Icons.settings_rounded, 'Settings'),
        ],
      ),
    )));
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Settings'), findsNothing); // icon only

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(index, 1);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('Google button and "or" divider render', (tester) async {
    await tester.pumpWidget(_app(const Column(
      mainAxisSize: MainAxisSize.min,
      children: [OrDivider(), GoogleSignInButton()],
    )));
    await tester.pump();
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('or'), findsOneWidget);
  });

  testWidgets('DonutChart draws with a centre label and no slices',
      (tester) async {
    await tester.pumpWidget(_app(const DonutChart(
      slices: [],
      center: Text('Total'),
    )));
    expect(find.text('Total'), findsOneWidget);
  });
}
