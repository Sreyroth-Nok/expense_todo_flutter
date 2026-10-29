import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_routes.dart';
import '../services/auth_repository.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/auth/onboarding_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/forgot_password_screen.dart';
import '../screens/dashboard/finance_screen.dart';
import '../screens/dashboard/home_screen.dart';
import '../screens/dashboard/main_shell.dart';
import '../screens/dashboard/planner_screen.dart';
import '../screens/budgets/budget_detail_screen.dart';
import '../screens/budgets/budget_form_screen.dart';
import '../screens/budgets/budgets_screen.dart';
import '../screens/calendar/event_form_screen.dart';
import '../models/reminder.dart';
import '../screens/reminders/reminder_form_screen.dart';
import '../screens/reports/reports_screen.dart';
import '../screens/savings/savings_goal_detail_screen.dart';
import '../screens/savings/savings_goal_form_screen.dart';
import '../screens/savings/savings_goals_screen.dart';
import '../screens/shopping/shopping_list_screen.dart';
import '../screens/shopping/shopping_lists_screen.dart';
import '../screens/tasks/task_form_screen.dart';
import '../screens/settings/account_screens.dart';
import '../screens/settings/notification_settings_screen.dart';
import '../screens/settings/privacy_screen.dart';
import '../screens/settings/settings_screen.dart';
import '../models/spending_limit.dart';
import '../screens/spending_limits/spending_limit_form_screen.dart';
import '../screens/spending_limits/spending_limits_screen.dart';
import '../models/finance_transaction.dart';
import '../screens/transactions/categories_screen.dart';
import '../screens/transactions/transaction_detail_screen.dart';
import '../screens/transactions/transaction_form_screen.dart';
import '../screens/transactions/transaction_success_screen.dart';
import '../screens/transactions/transactions_screen.dart';

/// Creates and provides the [GoRouter] instance.
///
/// Auth guard logic:
/// - Unauthenticated users can only reach: /, /onboarding, /login,
///   /register, /forgot-password.
/// - Authenticated users are redirected away from auth screens to /home.
/// - The [authStateProvider] stream drives all redirects.
final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  // Listen to the auth state stream so the router refreshes when it changes.
  final authNotifier = _AuthRouterNotifier(ref);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final authState = ref.read(authStateProvider);

      // Still loading auth state — stay on splash.
      if (authState.isLoading) {
        return state.uri.path == AppRoutes.splash
            ? null
            : AppRoutes.splash;
      }

      final isLoggedIn = authState.value != null;
      final isOnAuthRoute = [
        AppRoutes.splash,
        AppRoutes.onboarding,
        AppRoutes.login,
        AppRoutes.register,
        AppRoutes.forgotPassword,
      ].contains(state.uri.path);

      // Authenticated user visiting an auth screen → send to home.
      if (isLoggedIn && isOnAuthRoute) return AppRoutes.home;

      // Unauthenticated user visiting a protected screen → send to login.
      if (!isLoggedIn && !isOnAuthRoute) return AppRoutes.login;

      // No redirect needed.
      return null;
    },
    routes: [
      // ── Auth routes ───────────────────────────────────────────
      GoRoute(
        path: AppRoutes.splash,
        pageBuilder: (context, state) => const NoTransitionPage(
          child: SplashScreen(),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const OnboardingScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.login,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const LoginScreen(),
          transitionsBuilder: _fadeTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.register,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const RegisterScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        pageBuilder: (context, state) => CustomTransitionPage(
          child: const ForgotPasswordScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),

      // ── Full-screen protected routes (above the bottom bar) ─────
      // Declared outside the shell so forms get the whole screen. They are
      // still protected: the redirect above sends signed-out users to login.
      GoRoute(
        path: AppRoutes.newTransaction,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => TransactionFormScreen(
          initialType: TransactionType.fromName(
            state.uri.queryParameters['type'],
          ),
        ),
      ),
      GoRoute(
        path: AppRoutes.transactionSuccess,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => TransactionSuccessScreen(
          type: TransactionType.fromName(state.uri.queryParameters['type']),
        ),
      ),
      GoRoute(
        path: AppRoutes.transactionDetailPattern,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => TransactionDetailScreen(
          transactionId: state.pathParameters['id']!,
        ),
        routes: [
          GoRoute(
            path: 'edit', // → /transaction/:id/edit
            parentNavigatorKey: _rootNavigatorKey,
            builder: (context, state) => TransactionFormScreen(
              transactionId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.categories,
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const CategoriesScreen(),
      ),
      GoRoute(
        path: AppRoutes.editLimitPattern,
        parentNavigatorKey: _rootNavigatorKey,
        redirect: (context, state) =>
            LimitPeriod.tryParse(state.pathParameters['period']) == null
                ? AppRoutes.spendingLimits
                : null,
        builder: (context, state) => SpendingLimitFormScreen(
          period: LimitPeriod.tryParse(state.pathParameters['period'])!,
        ),
      ),

      // ── Phase 4 full-screen routes ──────────────────────────────
      // "new" routes are declared before ":id" routes so they match first.
      _fullScreen(AppRoutes.newBudget, (s) => const BudgetFormScreen()),
      _fullScreen(
        AppRoutes.budgetDetailPattern,
        (s) => BudgetDetailScreen(budgetId: s.pathParameters['id']!),
        routes: [
          _fullScreen('edit',
              (s) => BudgetFormScreen(budgetId: s.pathParameters['id']!)),
        ],
      ),
      _fullScreen(
          AppRoutes.newSavingsGoal, (s) => const SavingsGoalFormScreen()),
      _fullScreen(
        AppRoutes.savingsGoalDetailPattern,
        (s) => SavingsGoalDetailScreen(goalId: s.pathParameters['id']!),
        routes: [
          _fullScreen('edit',
              (s) => SavingsGoalFormScreen(goalId: s.pathParameters['id']!)),
        ],
      ),

      // ── Phase 5 full-screen routes ──────────────────────────────
      _fullScreen(AppRoutes.newTask, (s) => const TaskFormScreen()),
      _fullScreen(AppRoutes.editTaskPattern,
          (s) => TaskFormScreen(taskId: s.pathParameters['id']!)),
      _fullScreen(
        AppRoutes.newEvent,
        (s) => EventFormScreen(
          initialDay: _parseDay(s.uri.queryParameters['date']),
        ),
      ),
      _fullScreen(AppRoutes.editEventPattern,
          (s) => EventFormScreen(eventId: s.pathParameters['id']!)),
      _fullScreen(
        AppRoutes.newReminder,
        (s) => ReminderFormScreen(
          initialKind: ReminderKind.fromName(s.uri.queryParameters['kind']),
        ),
      ),
      _fullScreen(AppRoutes.editReminderPattern,
          (s) => ReminderFormScreen(reminderId: s.pathParameters['id']!)),
      _fullScreen(AppRoutes.shoppingListPattern,
          (s) => ShoppingListScreen(listId: s.pathParameters['id']!)),

      // ── Main shell with bottom nav ─────────────────────────────
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => MainShell(navigationShell: shell),
        branches: [
          // Branch 0 — Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HomeScreen(),
                ),
              ),
            ],
          ),

          // Branch 1 — Finance
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.finance,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: FinanceScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'transactions', // → /finance/transactions
                    builder: (context, state) => const TransactionsScreen(),
                  ),
                  GoRoute(
                    path: 'limits', // → /finance/limits
                    builder: (context, state) => const SpendingLimitsScreen(),
                  ),
                  GoRoute(
                    path: 'budgets', // → /finance/budgets
                    builder: (context, state) => const BudgetsScreen(),
                  ),
                  GoRoute(
                    path: 'savings', // → /finance/savings
                    builder: (context, state) => const SavingsGoalsScreen(),
                  ),
                  GoRoute(
                    path: 'reports', // → /finance/reports
                    builder: (context, state) => const ReportsScreen(),
                  ),
                ],
              ),
            ],
          ),

          // Branch 2 — Planner
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.planner,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: PlannerScreen(),
                ),
              ),
            ],
          ),

          // Branch 3 — Lists
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.lists,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: ShoppingListsScreen(),
                ),
              ),
            ],
          ),

          // Branch 4 — Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SettingsScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'profile', // → /settings/profile
                    builder: (context, state) => const EditProfileScreen(),
                  ),
                  GoRoute(
                    path: 'change-password',
                    builder: (context, state) => const ChangePasswordScreen(),
                  ),
                  GoRoute(
                    path: 'notifications',
                    builder: (context, state) =>
                        const NotificationSettingsScreen(),
                  ),
                  GoRoute(
                    path: 'privacy',
                    builder: (context, state) => const PrivacyScreen(),
                  ),
                  GoRoute(
                    path: 'delete-account',
                    builder: (context, state) => const DeleteAccountScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],

    // Custom error page.
    errorPageBuilder: (context, state) => MaterialPage(
      child: Scaffold(
        body: Center(
          child: Text('Page not found: ${state.uri.path}'),
        ),
      ),
    ),
  );
});

// ── Helpers ───────────────────────────────────────────────────────────────

/// A protected route shown above the bottom navigation bar.
GoRoute _fullScreen(
  String path,
  Widget Function(GoRouterState state) build, {
  List<RouteBase> routes = const [],
}) {
  return GoRoute(
    path: path,
    parentNavigatorKey: _rootNavigatorKey,
    builder: (context, state) => build(state),
    routes: routes,
  );
}

/// Parses "2026-10-23" from a query parameter; null if missing / invalid.
DateTime? _parseDay(String? value) {
  final parts = value?.split('-');
  if (parts == null || parts.length != 3) return null;
  final y = int.tryParse(parts[0]);
  final m = int.tryParse(parts[1]);
  final d = int.tryParse(parts[2]);
  if (y == null || m == null || d == null) return null;
  return DateTime(y, m, d);
}

// ── Page transitions ──────────────────────────────────────────────────────

Widget _fadeTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return FadeTransition(opacity: animation, child: child);
}

Widget _slideTransition(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  return SlideTransition(
    position: Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
    child: child,
  );
}

// ── Auth router notifier ──────────────────────────────────────────────────

/// A [Listenable] that triggers GoRouter to re-evaluate redirects whenever
/// the Firebase auth state changes.
class _AuthRouterNotifier extends ChangeNotifier {
  _AuthRouterNotifier(Ref ref) {
    // Watch the auth stream and notify the router whenever it changes.
    ref.listen(authStateProvider, (previous, next) {
      notifyListeners();
    });
  }
}
