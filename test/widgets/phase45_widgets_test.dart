import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lifemate/models/savings_goal.dart';
import 'package:lifemate/widgets/savings_goal_card.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  testWidgets('SavingsGoalCard shows progress and amount to go',
      (tester) async {
    await tester.pumpWidget(_wrap(const SavingsGoalCard(
      goal: SavingsGoal(
        name: 'Laptop',
        currency: 'USD',
        targetMinor: 80000,
        savedMinor: 20000,
      ),
    )));
    expect(find.text('Laptop'), findsOneWidget);
    expect(find.text('25%'), findsOneWidget);
    expect(find.text(r'$200.00 of $800.00'), findsOneWidget);
    expect(find.text(r'$600.00 to go'), findsOneWidget);
  });

  testWidgets('SavingsGoalCard celebrates a reached / completed goal',
      (tester) async {
    await tester.pumpWidget(_wrap(const SavingsGoalCard(
      goal: SavingsGoal(
        name: 'Phone',
        currency: 'USD',
        targetMinor: 30000,
        savedMinor: 30000,
        isCompleted: true,
      ),
    )));
    expect(find.text('Completed'), findsOneWidget);
    expect(find.text('Target reached 🎉'), findsOneWidget);
  });
}
