/// App-wide string constants.
///
/// Centralizes Firestore collection names, shared-preference keys,
/// and other literal values so a typo can never cause a silent data bug.
abstract final class AppConstants {
  // ── App identity ───────────────────────────────────────────────
  static const String appName = 'LifeMate';
  static const String appVersion = '1.0.0';

  // ── SharedPreferences keys ─────────────────────────────────────
  static const String prefOnboardingComplete = 'onboarding_complete';
  static const String prefSelectedCurrency = 'selected_currency';
  static const String prefSelectedLocale = 'selected_locale';

  // ── Firestore top-level collection ────────────────────────────
  static const String colUsers = 'users';

  // ── Firestore user sub-collections ────────────────────────────
  static const String colCategories = 'categories';
  static const String colTransactions = 'transactions';
  static const String colSpendingLimits = 'spendingLimits';
  static const String colBudgets = 'budgets';
  static const String colAllocations = 'allocations';
  static const String colSavingsGoals = 'savingsGoals';
  static const String colContributions = 'contributions';
  static const String colTasks = 'tasks';
  static const String colCalendarEvents = 'calendarEvents';
  static const String colReminders = 'reminders';
  static const String colShoppingLists = 'shoppingLists';
  static const String colShoppingItems = 'items';
  static const String colNotificationEvents = 'notificationEvents';

  // ── Firestore field names ──────────────────────────────────────
  static const String fieldUserId = 'userId';
  static const String fieldCreatedAt = 'createdAt';
  static const String fieldUpdatedAt = 'updatedAt';
  static const String fieldType = 'type';
  static const String fieldAmount = 'amountMinorUnits';
  static const String fieldCurrency = 'currency';
  static const String fieldDate = 'date';

  // ── Pagination ────────────────────────────────────────────────
  static const int defaultPageSize = 25;

  // ── Default currency ──────────────────────────────────────────
  static const String defaultCurrency = 'USD';
  static const String defaultLocale = 'en';

  // ── Spending limit types ───────────────────────────────────────
  static const String limitTypeDaily = 'daily';
  static const String limitTypeMonthly = 'monthly';

  // ── Transaction types ─────────────────────────────────────────
  static const String txTypeIncome = 'income';
  static const String txTypeExpense = 'expense';
}
