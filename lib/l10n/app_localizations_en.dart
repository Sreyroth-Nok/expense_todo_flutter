// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'LifeMate';

  @override
  String get navHome => 'Home';

  @override
  String get navFinance => 'Finance';

  @override
  String get navPlanner => 'Planner';

  @override
  String get navLists => 'Lists';

  @override
  String get navSettings => 'Settings';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonClose => 'Close';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get commonSomethingWentWrong => 'Something went wrong';

  @override
  String get commonSeeAll => 'See all';

  @override
  String get commonManage => 'Manage';

  @override
  String get commonCreate => 'Create';

  @override
  String get commonAll => 'All';

  @override
  String get commonSaved => 'Saved.';

  @override
  String get commonOverdue => 'Overdue';

  @override
  String get errorPermissionDenied =>
      'You do not have permission to access this data.';

  @override
  String get errorIndexBuilding =>
      'A database index is still being created. Try again in a few minutes.';

  @override
  String get errorNetwork =>
      'Cannot reach the server. Check your internet connection.';

  @override
  String get errorUnexpected => 'Unexpected error. Please try again.';

  @override
  String get validationEmailRequired => 'Email address is required.';

  @override
  String get validationEmailInvalid => 'Enter a valid email address.';

  @override
  String get validationPasswordRequired => 'Password is required.';

  @override
  String get validationPasswordLength =>
      'Password must be at least 8 characters.';

  @override
  String get validationPasswordUppercase =>
      'Include at least one uppercase letter.';

  @override
  String get validationPasswordNumber => 'Include at least one number.';

  @override
  String get validationConfirmPassword => 'Please confirm your password.';

  @override
  String get validationPasswordsDontMatch => 'Passwords do not match.';

  @override
  String get validationNameRequired => 'Name is required.';

  @override
  String get validationNameTooShort => 'Name must be at least 2 characters.';

  @override
  String get validationNameTooLong => 'Name must be 50 characters or fewer.';

  @override
  String validationRequired(String field) {
    return '$field is required.';
  }

  @override
  String get validationAmountRequired => 'Amount is required.';

  @override
  String validationAmountWhole(String currency) {
    return 'Enter a whole number (no decimals for $currency).';
  }

  @override
  String validationAmountDecimals(int decimals) {
    return 'Enter a valid amount with up to $decimals decimals.';
  }

  @override
  String get validationAmountPositive => 'Amount must be greater than zero.';

  @override
  String get authUserNotFound => 'No account found with this email address.';

  @override
  String get authWrongPassword => 'Incorrect password. Please try again.';

  @override
  String get authInvalidCredential =>
      'Incorrect email or password. Please try again.';

  @override
  String get authEmailInUse =>
      'An account already exists with this email address.';

  @override
  String get authWeakPassword =>
      'Password is too weak. Use at least 8 characters.';

  @override
  String get authInvalidEmail => 'The email address is not valid.';

  @override
  String get authUserDisabled =>
      'This account has been disabled. Contact support.';

  @override
  String get authTooManyRequests =>
      'Too many failed attempts. Please wait a moment and try again.';

  @override
  String get authOperationNotAllowed =>
      'Email/password sign-in is not enabled. Contact support.';

  @override
  String get authRequiresRecentLogin =>
      'For security, please log out and log in again before this action.';

  @override
  String get authNetwork => 'Network error. Check your internet connection.';

  @override
  String authGeneric(String message) {
    return 'Authentication error: $message';
  }

  @override
  String get onboardingTitle1 => 'Manage Your Money';

  @override
  String get onboardingBody1 =>
      'Track income and expenses, set spending limits, and reach your savings goals — all in one place.';

  @override
  String get onboardingTitle2 => 'Plan Every Day';

  @override
  String get onboardingBody2 =>
      'Organise tasks, schedule events, set reminders, and never miss an important bill again.';

  @override
  String get onboardingTitle3 => 'Stay Organised';

  @override
  String get onboardingBody3 =>
      'Create shopping lists, track your budget categories, and get clear reports on your spending habits.';

  @override
  String get onboardingSkip => 'Skip';

  @override
  String get onboardingNext => 'Next';

  @override
  String get onboardingGetStarted => 'Get Started';

  @override
  String get authAlreadyHaveAccount => 'Already have an account?';

  @override
  String get authLogIn => 'Log In';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to your LifeMate account.';

  @override
  String get fieldEmail => 'Email address';

  @override
  String get fieldEmailHint => 'you@example.com';

  @override
  String get fieldPassword => 'Password';

  @override
  String get loginForgotPassword => 'Forgot password?';

  @override
  String get loginNoAccount => 'Don\'t have an account?';

  @override
  String get loginCreateOne => 'Create one';

  @override
  String get loginFailed => 'Login failed. Please try again.';

  @override
  String get registerTitle => 'Create account';

  @override
  String get registerSubtitle => 'Start managing your money and daily life.';

  @override
  String get registerBackToLogin => 'Back to login';

  @override
  String get fieldFullName => 'Full name';

  @override
  String get fieldFullNameHint => 'John Doe';

  @override
  String get fieldPasswordHint => 'Min. 8 characters with a number';

  @override
  String get fieldConfirmPassword => 'Confirm password';

  @override
  String get fieldConfirmPasswordHint => 'Repeat your password';

  @override
  String get registerButton => 'Create Account';

  @override
  String get registerFailed => 'Registration failed. Please try again.';

  @override
  String get registerPasswordRules =>
      'Password must be at least 8 characters, include one uppercase letter and one number.';

  @override
  String get forgotTitle => 'Reset Password';

  @override
  String get forgotHeadline => 'Forgot your password?';

  @override
  String get forgotBody =>
      'Enter the email address associated with your account and we\'ll send you a password reset link.';

  @override
  String get forgotSendButton => 'Send Reset Link';

  @override
  String get forgotBackToLogin => 'Back to Login';

  @override
  String get forgotSent => 'Password reset email sent. Check your inbox.';

  @override
  String get forgotFailed => 'Failed to send reset email.';

  @override
  String get forgotCheckInbox => 'Check your inbox';

  @override
  String get forgotCheckInboxBody =>
      'We\'ve sent a password reset link to your email address. Click the link to set a new password.';

  @override
  String homeGreeting(String name) {
    return 'Hi, $name 👋';
  }

  @override
  String get homeTodaysSpending => 'Today\'s spending';

  @override
  String get homeNoSpendingToday => 'No spending yet today';

  @override
  String get homeIncome => 'Income';

  @override
  String get homeExpenses => 'Expenses';

  @override
  String get homeNet => 'Net (income − expenses)';

  @override
  String get homeNoTransactionsMonth =>
      'No income or expenses this month yet. Use the quick actions above to add your first one.';

  @override
  String get homeSpendingLimits => 'Spending limits';

  @override
  String get homeRecentTransactions => 'Recent transactions';

  @override
  String homeNothingRecorded(String month) {
    return 'Nothing recorded in $month';
  }

  @override
  String get homeNothingRecordedBody =>
      'Add an income or expense to start tracking your money.';

  @override
  String get homeComingUp => 'Coming up this week';

  @override
  String get homeNothingThisWeek =>
      'No tasks, events or bills in the next 7 days.';

  @override
  String get homeBudgets => 'Budgets';

  @override
  String get homeNoActiveBudget =>
      'No active budget. Plan this month\'s spending in Finance.';

  @override
  String get homeSavingsGoals => 'Savings goals';

  @override
  String get homeNoSavingsGoal => 'No savings goal yet.';

  @override
  String get homePreviousMonth => 'Previous month';

  @override
  String get homeNextMonth => 'Next month';

  @override
  String get quickIncome => 'Income';

  @override
  String get quickExpense => 'Expense';

  @override
  String get quickTask => 'Task';

  @override
  String get quickShopping => 'Shopping';

  @override
  String get financeTitle => 'Finance';

  @override
  String get financeTransactions => 'Transactions';

  @override
  String get financeTransactionsDesc =>
      'Income and expense history, search and filters';

  @override
  String get financeLimits => 'Spending limits';

  @override
  String get financeLimitsDesc => 'Daily and monthly limits with alerts';

  @override
  String get financeCategories => 'Categories';

  @override
  String get financeCategoriesDesc =>
      'Manage your income and expense categories';

  @override
  String get financeBudgets => 'Budgets';

  @override
  String get financeBudgetsDesc => 'Plan spending per category';

  @override
  String get financeSavings => 'Savings goals';

  @override
  String get financeSavingsDesc => 'Track progress toward your targets';

  @override
  String get financeReports => 'Reports';

  @override
  String get financeReportsDesc => 'Spending by category, CSV export';

  @override
  String get plannerTitle => 'Planner';

  @override
  String get plannerTasks => 'Tasks';

  @override
  String get plannerCalendar => 'Calendar';

  @override
  String get plannerReminders => 'Reminders';

  @override
  String get listsTitle => 'Shopping lists';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsEditProfile => 'Edit profile';

  @override
  String get settingsEditProfileDesc => 'Change your display name';

  @override
  String get settingsChangePassword => 'Change password';

  @override
  String get settingsChangePasswordDesc => 'Update your account password';

  @override
  String get settingsPreferences => 'Preferences';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsCurrency => 'Default currency';

  @override
  String get settingsTimeZone => 'Time zone';

  @override
  String settingsTimeZoneAuto(String zone) {
    return '$zone · from your phone';
  }

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsDesc => 'Alerts, reminders and permissions';

  @override
  String get settingsPrivacyData => 'Privacy & data';

  @override
  String get settingsPrivacy => 'Privacy information';

  @override
  String get settingsPrivacyDesc => 'What we store and who can see it';

  @override
  String get settingsDeleteAccount => 'Delete account';

  @override
  String get settingsDeleteAccountDesc =>
      'Permanently delete your account and data';

  @override
  String get settingsLogOut => 'Log out';

  @override
  String get settingsLogOutConfirm =>
      'Are you sure you want to log out of LifeMate?';

  @override
  String settingsVersion(String version) {
    return 'LifeMate v$version';
  }

  @override
  String get languageEnglish => 'English';

  @override
  String get languageKhmer => 'ខ្មែរ (Khmer)';

  @override
  String get chooseLanguage => 'Choose language';

  @override
  String get chooseCurrency => 'Default currency';

  @override
  String get currencyNote =>
      'Used as the default for new transactions, limits, budgets and goals. Existing records keep their own currency — LifeMate never converts between currencies.';

  @override
  String get timeZoneTitle => 'Time zone';

  @override
  String timeZoneBody(String zone) {
    return 'LifeMate uses your phone\'s time zone ($zone) to decide when a day or month starts — for spending limits, budgets, reports and reminders.\n\nTo use a different time zone, change it in your phone\'s Date & time settings. LifeMate saves it to your profile automatically.';
  }

  @override
  String get profileTitle => 'Edit profile';

  @override
  String get profileName => 'Display name';

  @override
  String get profileEmail => 'Email';

  @override
  String get profileEmailNote =>
      'Your email is your login and cannot be changed in the app.';

  @override
  String get profileSaved => 'Profile updated.';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get currentPassword => 'Current password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmNewPassword => 'Confirm new password';

  @override
  String get changePasswordButton => 'Change password';

  @override
  String get passwordChanged => 'Password changed.';

  @override
  String get newPasswordSame =>
      'The new password must be different from the current one.';

  @override
  String get changePasswordInfo =>
      'For your security, enter your current password first.';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsPermissionOn => 'Notifications are allowed';

  @override
  String get notificationsPermissionOff => 'Notifications are not allowed';

  @override
  String get notificationsAllow => 'Allow notifications';

  @override
  String get notificationsBlockedHelp =>
      'If nothing happens, LifeMate was blocked earlier. Open your phone\'s Settings → Apps → LifeMate → Notifications.';

  @override
  String get notificationsExact => 'Exact reminder times';

  @override
  String get notificationsExactDesc =>
      'Android may deliver reminders a few minutes late unless you allow alarms for LifeMate.';

  @override
  String get notificationsExactAllow => 'Allow exact alarms';

  @override
  String get notificationsCategories => 'Notify me about';

  @override
  String get notifySpendingLimits => 'Spending limits';

  @override
  String get notifySpendingLimitsDesc => 'Warning, reached and exceeded alerts';

  @override
  String get notifyReminders => 'Reminders & bills';

  @override
  String get notifyRemindersDesc => 'Your reminders and bill due dates';

  @override
  String get notifyTasks => 'Tasks';

  @override
  String get notifyTasksDesc => 'Tasks with \"Remind me\" turned on';

  @override
  String get notifyEvents => 'Calendar events';

  @override
  String get notifyEventsDesc => 'Events with a reminder';

  @override
  String get notifySavings => 'Savings goals';

  @override
  String get notifySavingsDesc => 'Monthly \"time to save\" reminders';

  @override
  String get notificationsInAppNote =>
      'Turning a type off only stops pop-up notifications. You still see everything inside the app.';

  @override
  String get privacyTitle => 'Privacy information';

  @override
  String get privacyWhatTitle => 'What LifeMate stores';

  @override
  String get privacyWhatBody =>
      'Your name and email, your preferences, and the data you enter: transactions, categories, limits, budgets, savings goals, tasks, events, reminders and shopping lists. LifeMate never stores your password — Firebase Authentication handles it securely.';

  @override
  String get privacyWhereTitle => 'Where it is stored';

  @override
  String get privacyWhereBody =>
      'In Google Firebase (Cloud Firestore), encrypted in transit and at rest. A copy is cached on this phone so the app works offline.';

  @override
  String get privacyWhoTitle => 'Who can see it';

  @override
  String get privacyWhoBody =>
      'Only you. Security rules on the server allow each account to read and write only its own data. LifeMate has no ads and does not sell or share your data.';

  @override
  String get privacyDeviceTitle => 'Notifications';

  @override
  String get privacyDeviceBody =>
      'Reminders are scheduled on this phone by your phone\'s alarm system. Their text stays on the device.';

  @override
  String get privacyExportTitle => 'Your data, your copy';

  @override
  String get privacyExportBody =>
      'You can export your transactions as a CSV file from Finance → Reports at any time.';

  @override
  String get privacyDeleteTitle => 'Deleting your data';

  @override
  String get privacyDeleteBody =>
      'Settings → Delete account permanently removes your account and everything you stored. This cannot be undone.';

  @override
  String get deleteTitle => 'Delete account';

  @override
  String get deleteWarning =>
      'This permanently deletes your LifeMate account and ALL of your data. It cannot be undone.';

  @override
  String get deleteWhatIsDeleted =>
      'Deleted: transactions, categories, spending limits, budgets, savings goals and their history, tasks, calendar events, reminders, shopping lists and your profile.';

  @override
  String get deleteExportHint =>
      'Want a copy first? Export your transactions in Finance → Reports.';

  @override
  String get deletePasswordLabel => 'Enter your password to confirm';

  @override
  String get deleteButton => 'Delete my account';

  @override
  String get deleteConfirmTitle => 'Delete everything?';

  @override
  String get deleteConfirmBody =>
      'Your account and all data will be removed permanently.';

  @override
  String get deleteInProgress => 'Deleting your data…';

  @override
  String get deleteDone => 'Your account was deleted.';
}
