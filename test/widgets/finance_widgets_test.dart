import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lifemate/features/spending_limits/domain/spending_limit_calculator.dart';
import 'package:lifemate/features/spending_limits/presentation/widgets/limit_progress_card.dart';
import 'package:lifemate/features/transactions/domain/finance_transaction.dart';
import 'package:lifemate/features/transactions/domain/transaction_category.dart';
import 'package:lifemate/features/transactions/presentation/widgets/transaction_form.dart';

import '../helpers/builders.dart';

Widget _wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  // Tests run offline: use the fallback font instead of downloading Inter.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  group('TransactionForm', () {
    testWidgets('shows validation errors and does not submit when empty',
        (tester) async {
      FinanceTransaction? submitted;
      await tester.pumpWidget(_wrap(TransactionForm(
        categories: DefaultCategories.all,
        defaultCurrency: 'USD',
        onSubmit: (tx) => submitted = tx,
      )));

      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(find.text('Amount is required.'), findsOneWidget);
      expect(find.text('Please choose a category.'), findsOneWidget);
      expect(submitted, isNull);
    });

    testWidgets('submits an exact minor-unit amount', (tester) async {
      FinanceTransaction? submitted;
      await tester.pumpWidget(_wrap(TransactionForm(
        categories: DefaultCategories.all,
        defaultCurrency: 'USD',
        onSubmit: (tx) => submitted = tx,
      )));

      await tester.enterText(find.byKey(const Key('amountField')), '4.35');
      // Categories are chosen in a bottom sheet.
      await tester.tap(find.byKey(const Key('categoryField')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transport'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save'));
      await tester.tap(find.text('Save'));
      await tester.pump();

      expect(submitted, isNotNull);
      expect(submitted!.amountMinor, 435);
      expect(submitted!.type, TransactionType.expense);
      expect(submitted!.categoryId, 'transport');
    });

    testWidgets('switching to income shows only income categories',
        (tester) async {
      await tester.pumpWidget(_wrap(TransactionForm(
        categories: DefaultCategories.all,
        defaultCurrency: 'USD',
        onSubmit: (_) {},
      )));
      await tester.tap(find.byKey(const Key('categoryField')));
      await tester.pumpAndSettle();
      expect(find.text('Transport'), findsOneWidget);
      Navigator.of(tester.element(find.text('Transport'))).pop();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Income'));
      await tester.pump();
      await tester.tap(find.byKey(const Key('categoryField')));
      await tester.pumpAndSettle();
      expect(find.text('Salary'), findsOneWidget);
      expect(find.text('Transport'), findsNothing);
    });
  });

  group('LimitProgressCard', () {
    final now = DateTime.now();

    testWidgets('shows remaining allowance', (tester) async {
      final status = SpendingLimitCalculator.evaluate(
        limit: dailyLimit(500),
        transactions: [expense(400, now)],
        now: now,
      );
      await tester.pumpWidget(_wrap(LimitProgressCard(status: status)));
      expect(find.text(r'$1.00 left'), findsOneWidget);
      expect(find.text('On track'), findsOneWidget);
    });

    testWidgets('shows how much the limit was exceeded by', (tester) async {
      final status = SpendingLimitCalculator.evaluate(
        limit: dailyLimit(500),
        transactions: [expense(400, now), expense(200, now)],
        now: now,
      );
      await tester.pumpWidget(_wrap(LimitProgressCard(status: status)));
      expect(find.text(r'Over by $1.00'), findsOneWidget);
      expect(find.text('Exceeded'), findsOneWidget);
    });
  });
}
