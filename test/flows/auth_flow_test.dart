import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifemate/screens/auth/login_screen.dart';
import 'package:lifemate/screens/auth/onboarding_screen.dart';
import 'package:lifemate/screens/dashboard/home_screen.dart';

import 'flow_harness.dart';

/// User journeys through sign-up, login and logout on the real app.
void main() {
  testWidgets('first launch: onboarding → register → home', (tester) async {
    final app = await FlowHarness.start(tester);

    expect(find.byType(OnboardingScreen), findsOneWidget);
    await app.tapText('Next');
    await app.tapText('Next');
    await app.tapText('Get Started');
    expect(find.byType(LoginScreen), findsOneWidget);

    await app.tapText('Sign Up');
    expect(find.text('Create your account'), findsOneWidget);

    // Invalid input is rejected before anything is sent.
    await app.tapText('Create Account');
    expect(find.text('Name is required.'), findsOneWidget);
    expect(find.text('Email address is required.'), findsOneWidget);
    expect(app.auth.currentUser, isNull);

    await app.enter('Full name', 'Dara Sok');
    await app.enter('Email address', 'dara@example.com');
    await app.enter('Password', 'Secret123');
    await app.enter('Confirm password', 'Secret123');
    await app.tapText('Create Account');

    expect(find.byType(HomeScreen), findsOneWidget);
    // The greeting uses the first name only.
    expect(find.text('Hi, Dara 👋'), findsOneWidget);
    expect(app.auth.currentUser?.email, 'dara@example.com');

    // The phone's time zone is copied to the new profile.
    final profile = await app.db
        .collection('users')
        .doc(app.auth.currentUser!.uid)
        .get();
    expect(profile.data()?['timeZone'], 'Asia/Phnom_Penh');
  });

  testWidgets('register: mismatched passwords are rejected', (tester) async {
    final app = await FlowHarness.start(tester, onboardingSeen: true);
    await app.tapText('Sign Up');

    await app.enter('Full name', 'Dara Sok');
    await app.enter('Email address', 'dara@example.com');
    await app.enter('Password', 'Secret123');
    await app.enter('Confirm password', 'Secret999');
    await app.tapText('Create Account');

    expect(find.text('Passwords do not match.'), findsOneWidget);
    expect(app.auth.currentUser, isNull);
  });

  testWidgets('returning user: wrong password, then log in, then log out',
      (tester) async {
    final app = await FlowHarness.start(
      tester,
      onboardingSeen: true,
      seed: (auth, _) => auth.seedAccount(
        email: 'vanna@example.com',
        password: 'Secret123',
        displayName: 'Vanna',
      ),
    );
    expect(find.byType(LoginScreen), findsOneWidget);

    await app.enter('Email address', 'vanna@example.com');
    await app.enter('Password', 'wrong-pass');
    await app.tapText('Log In');
    expect(find.text('Incorrect email or password. Please try again.'),
        findsOneWidget);
    expect(find.byType(LoginScreen), findsOneWidget);

    await app.enter('Password', 'Secret123');
    await app.tapText('Log In');
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Hi, Vanna 👋'), findsOneWidget);

    await app.openTab('Settings');
    await app.tapText('Log out');
    // Confirm in the dialog (its title is also "Log out").
    await app.tap(find.widgetWithText(TextButton, 'Log out'));

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(app.auth.currentUser, isNull);
  });

  testWidgets('signed-in user skips login on app start', (tester) async {
    final app = await FlowHarness.start(
      tester,
      seed: (auth, _) async {
        final user = await auth.seedAccount(
          email: 'vanna@example.com',
          password: 'Secret123',
          displayName: 'Vanna',
        );
        await auth.login(email: user.email!, password: 'Secret123');
      },
    );
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(app.notifications.scheduled, isEmpty);
  });
}
