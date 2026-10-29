/// Route path constants used by GoRouter and push/pop calls.
///
/// Never hardcode route strings in widgets — always reference these constants.
abstract final class AppRoutes {
  // ── Auth ───────────────────────────────────────────────────────
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String register = '/register';
  static const String forgotPassword = '/forgot-password';

  // ── Main shell ─────────────────────────────────────────────────
  static const String home = '/home';
  static const String finance = '/finance';
  static const String planner = '/planner';
  static const String lists = '/lists';
  static const String settings = '/settings';

  // ── Finance sub-routes (inside the Finance tab) ─────────────────
  static const String transactions = '/finance/transactions';
  static const String spendingLimits = '/finance/limits';

  // ── Full-screen routes (shown above the bottom bar) ─────────────
  static const String categories = '/categories';
  static const String newTransaction = '/transaction/new';
  static const String transactionSuccess = '/transaction/success';
  static String transactionSuccessOf(String type) =>
      '$transactionSuccess?type=$type';
  static const String transactionDetailPattern = '/transaction/:id';
  static const String editTransactionPattern = '/transaction/:id/edit';
  static const String editLimitPattern = '/limits/:period/edit';

  /// e.g. newTransactionOf('income') → '/transaction/new?type=income'
  static String newTransactionOf(String type) => '$newTransaction?type=$type';
  static String transactionDetail(String id) => '/transaction/$id';
  static String editTransaction(String id) => '/transaction/$id/edit';
  static String editLimit(String period) => '/limits/$period/edit';

  // ── Phase 4: budgets, savings, reports ─────────────────────────
  static const String budgets = '/finance/budgets';
  static const String savings = '/finance/savings';
  static const String reports = '/finance/reports';

  static const String newBudget = '/budget/new';
  static const String budgetDetailPattern = '/budget/:id';
  static String budgetDetail(String id) => '/budget/$id';
  static String editBudget(String id) => '/budget/$id/edit';

  static const String newSavingsGoal = '/savings-goal/new';
  static const String savingsGoalDetailPattern = '/savings-goal/:id';
  static String savingsGoalDetail(String id) => '/savings-goal/$id';
  static String editSavingsGoal(String id) => '/savings-goal/$id/edit';

  // ── Phase 5: planner and lists ─────────────────────────────────
  static const String newTask = '/task/new';
  static const String editTaskPattern = '/task/:id/edit';
  static String editTask(String id) => '/task/$id/edit';

  static const String newEvent = '/event/new';
  static const String editEventPattern = '/event/:id/edit';
  /// [day] pre-fills the start date, e.g. from the calendar.
  static String newEventOn(DateTime day) =>
      '$newEvent?date=${day.year}-${day.month}-${day.day}';
  static String editEvent(String id) => '/event/$id/edit';

  static const String newReminder = '/reminder/new';
  static const String editReminderPattern = '/reminder/:id/edit';
  static String newReminderOf(String kind) => '$newReminder?kind=$kind';
  static String editReminder(String id) => '/reminder/$id/edit';

  static const String shoppingListPattern = '/shopping/:id';
  static String shoppingList(String id) => '/shopping/$id';

  // ── Settings sub-routes ────────────────────────────────────────
  static const String editProfile = '/settings/profile';
  static const String changePassword = '/settings/change-password';
  static const String notificationSettings = '/settings/notifications';
  static const String privacy = '/settings/privacy';
  static const String deleteAccount = '/settings/delete-account';
}
