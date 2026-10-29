import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lifemate/app.dart';
import 'package:lifemate/utils/app_constants.dart';
import 'package:lifemate/utils/app_exception.dart';
import 'package:lifemate/l10n/l10n.dart';
import 'package:lifemate/providers/locale_provider.dart';
import 'package:lifemate/services/notification_service.dart';
import 'package:lifemate/models/scheduled_notice.dart';
import 'package:lifemate/services/time_zone_service.dart';
import 'package:lifemate/providers/clock_provider.dart';
import 'package:lifemate/services/auth_repository.dart';
import 'package:lifemate/services/budget_repository.dart';
import 'package:lifemate/services/calendar_repository.dart';
import 'package:lifemate/services/reminder_repository.dart';
import 'package:lifemate/services/savings_repository.dart';
import 'package:lifemate/services/shopping_repository.dart';
import 'package:lifemate/services/spending_limit_repository.dart';
import 'package:lifemate/services/task_repository.dart';
import 'package:lifemate/services/category_repository.dart';
import 'package:lifemate/services/transaction_repository.dart';
import 'package:lifemate/models/user_profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Helpers for full-app flow tests: the real [App], router and screens,
/// backed by an in-memory Firestore and a fake sign-in.
///
/// Nothing talks to Firebase, the notification plugin or the network, so
/// the flows run with a plain `flutter test`.

// ── Fake auth ─────────────────────────────────────────────────────────────

/// Only `uid`, `email` and `displayName` are read by the app.
class FakeUser implements User {
  FakeUser({required this.uid, required this.email, this.displayName});

  @override
  final String uid;
  @override
  final String? email;
  @override
  final String? displayName;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Never called: every method that would use it is overridden below.
class _NoFirebaseAuth implements FirebaseAuth {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Email/password accounts kept in memory; profiles go to [db] exactly
/// like the real repository writes them.
class FakeAuthRepository extends AuthRepository {
  FakeAuthRepository(this.db) : super(auth: _NoFirebaseAuth(), firestore: db);

  final FakeFirebaseFirestore db;
  final _passwords = <String, String>{};
  final _users = <String, FakeUser>{};
  final _state = StreamController<User?>.broadcast();
  FakeUser? _current;
  var _nextId = 1;

  /// Creates an account without going through the register screen.
  Future<FakeUser> seedAccount({
    required String email,
    required String password,
    String displayName = 'Test User',
  }) async {
    final user = FakeUser(
      uid: 'uid-${_nextId++}',
      email: email,
      displayName: displayName,
    );
    _users[email] = user;
    _passwords[email] = password;
    final now = DateTime.now().toUtc();
    await db.collection(AppConstants.colUsers).doc(user.uid).set(UserProfile(
          uid: user.uid,
          displayName: displayName,
          email: email,
          createdAt: now,
          updatedAt: now,
        ).toFirestore());
    return user;
  }

  void _signIn(FakeUser? user) {
    _current = user;
    _state.add(user);
  }

  @override
  Stream<User?> get authStateChanges async* {
    yield _current;
    yield* _state.stream;
  }

  @override
  User? get currentUser => _current;

  @override
  bool get hasPassword => _current != null;

  @override
  Future<UserProfile> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final key = email.trim();
    if (_users.containsKey(key)) {
      throw AuthException(currentL10n.authEmailInUse);
    }
    final user = await seedAccount(
      email: key,
      password: password,
      displayName: displayName.trim(),
    );
    _signIn(user);
    final doc =
        await db.collection(AppConstants.colUsers).doc(user.uid).get();
    return UserProfile.fromFirestore(doc);
  }

  @override
  Future<User> login({required String email, required String password}) async {
    final user = _users[email.trim()];
    if (user == null || _passwords[email.trim()] != password) {
      throw AuthException(currentL10n.authInvalidCredential);
    }
    _signIn(user);
    return user;
  }

  @override
  Future<User> signInWithGoogle() async =>
      throw const AuthCancelledException();

  @override
  Future<void> logout() async => _signIn(null);

  @override
  Future<void> sendPasswordResetEmail(String email) async {}

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final email = _current!.email!;
    if (_passwords[email] != currentPassword) {
      throw AuthException(currentL10n.authWrongPassword);
    }
    _passwords[email] = newPassword;
  }

  @override
  Future<void> deleteAccount({String? password}) async {
    final user = _current!;
    if (_passwords[user.email] != password) {
      throw AuthException(currentL10n.authWrongPassword);
    }
    await db.collection(AppConstants.colUsers).doc(user.uid).delete();
    _users.remove(user.email);
    _signIn(null);
  }

  @override
  Future<UserProfile?> fetchCurrentProfile() async {
    final user = _current;
    if (user == null) return null;
    final doc = await db.collection(AppConstants.colUsers).doc(user.uid).get();
    return doc.exists ? UserProfile.fromFirestore(doc) : null;
  }

  @override
  Future<void> updateDisplayName(String name) => db
      .collection(AppConstants.colUsers)
      .doc(_current!.uid)
      .update({'displayName': name.trim()});
}

// ── Fake notifications ────────────────────────────────────────────────────

/// Records what would be scheduled instead of calling the plugin.
class FakeNotificationService extends NotificationService {
  List<ScheduledNotice> scheduled = const [];
  final limitAlerts = <String>[];

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> areNotificationsAllowed() async => true;

  @override
  Future<bool?> canUseExactAlarms() async => true;

  @override
  Future<void> requestExactAlarms() async {}

  @override
  Future<void> replaceScheduled(List<ScheduledNotice> notices) async =>
      scheduled = notices;

  @override
  Future<void> showLimitAlert({
    required int id,
    required String title,
    required String body,
  }) async =>
      limitAlerts.add(body);
}

// ── App harness ───────────────────────────────────────────────────────────

/// One running app plus handles to its fake backends.
class FlowHarness {
  FlowHarness._(this.tester, this.db, this.auth, this.notifications);

  final WidgetTester tester;
  final FakeFirebaseFirestore db;
  final FakeAuthRepository auth;
  final FakeNotificationService notifications;

  /// Pumps the real [App].
  ///
  /// [onboardingSeen] skips onboarding on first launch, like a returning
  /// user. Use [seed] to create accounts / data before the first frame.
  static Future<FlowHarness> start(
    WidgetTester tester, {
    bool onboardingSeen = false,
    Future<void> Function(FakeAuthRepository auth, FakeFirebaseFirestore db)?
        seed,
  }) async {
    GoogleFonts.config.allowRuntimeFetching = false;
    // The test font draws every glyph as a full square, so text is much
    // wider than on a phone. A wide, tall view keeps rows from overflowing
    // and long forms from needing much scrolling.
    tester.view.physicalSize = const Size(1800, 3900);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({
      AppConstants.prefSelectedLocale: 'en',
      if (onboardingSeen) 'onboarding_complete': true,
    });
    final prefs = await SharedPreferences.getInstance();

    final db = FakeFirebaseFirestore();
    final auth = FakeAuthRepository(db);
    final notifications = FakeNotificationService();
    if (seed != null) await seed(auth, db);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(auth),
        notificationServiceProvider.overrideWithValue(notifications),
        // The real clock waits until midnight, which would leave a timer
        // pending when the test ends.
        clockProvider.overrideWith((ref) => Stream.value(DateTime.now())),
        deviceTimeZoneProvider.overrideWith((ref) async => 'Asia/Phnom_Penh'),
        transactionRepositoryProvider
            .overrideWithValue(TransactionRepository(firestore: db)),
        categoryRepositoryProvider
            .overrideWithValue(CategoryRepository(firestore: db)),
        spendingLimitRepositoryProvider
            .overrideWithValue(SpendingLimitRepository(firestore: db)),
        budgetRepositoryProvider
            .overrideWithValue(BudgetRepository(firestore: db)),
        savingsRepositoryProvider
            .overrideWithValue(SavingsRepository(firestore: db)),
        taskRepositoryProvider.overrideWithValue(TaskRepository(firestore: db)),
        calendarRepositoryProvider
            .overrideWithValue(CalendarRepository(firestore: db)),
        reminderRepositoryProvider
            .overrideWithValue(ReminderRepository(firestore: db)),
        shoppingRepositoryProvider
            .overrideWithValue(ShoppingRepository(firestore: db)),
      ],
      child: const App(),
    ));

    final harness = FlowHarness._(tester, db, auth, notifications);
    // The splash screen waits 2 seconds before routing.
    await harness.settle(const Duration(seconds: 3));
    return harness;
  }

  /// Signed-in user's documents in [collection].
  Future<List<Map<String, dynamic>>> userDocs(String collection) async {
    final uid = auth.currentUser!.uid;
    final snap = await db
        .collection(AppConstants.colUsers)
        .doc(uid)
        .collection(collection)
        .get();
    return [for (final d in snap.docs) d.data()];
  }

  /// Like pumpAndSettle, but tolerant of looping animations (loading dots,
  /// shimmer): pumps frames for [duration] instead of waiting forever.
  Future<void> settle([Duration duration = const Duration(seconds: 1)]) async {
    const step = Duration(milliseconds: 100);
    for (var t = Duration.zero; t < duration; t += step) {
      await tester.pump(step);
    }
  }

  /// Scrolls [finder] into view, taps it and lets the UI settle.
  Future<void> tap(Finder finder) async {
    await tester.ensureVisible(finder.first);
    await tester.pump();
    await tester.tap(finder.first);
    await settle();
  }

  Future<void> tapText(String text) => tap(find.text(text));

  /// The text field labelled [label]: either its hint (login / register
  /// style) or the [FieldLabel] above it (form screens).
  Finder fieldFor(String label) {
    final byHint = find.byWidgetPredicate(
      (w) => w is TextField && w.decoration?.hintText == label,
    );
    if (byHint.evaluate().isNotEmpty) return byHint.first;
    final group = find
        .ancestor(of: find.text(label), matching: find.byType(Column))
        .first;
    return find.descendant(of: group, matching: find.byType(TextField)).first;
  }

  /// Types into the text field labelled [label], replacing its text.
  Future<void> enter(String label, String text) async {
    final field = fieldFor(label);
    await tester.ensureVisible(field);
    await tester.enterText(field, text);
    await tester.pump();
  }

  Future<void> enterByKey(String key, String text) async {
    final field = find.byKey(Key(key));
    await tester.ensureVisible(field);
    await tester.enterText(field, text);
    await tester.pump();
  }

  /// Taps a bottom-navigation tab by its label. Only the selected tab
  /// shows its label, so tabs are found by their tooltip.
  Future<void> openTab(String label) async {
    await tester.tap(find.byTooltip(label));
    await settle();
  }
}

/// Data written with [FieldValue.serverTimestamp] reads back as a
/// [Timestamp]; handy for assertions that only care about the date.
DateTime? asDate(Object? value) =>
    value is Timestamp ? value.toDate() : value as DateTime?;
