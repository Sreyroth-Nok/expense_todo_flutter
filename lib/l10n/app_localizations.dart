import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_km.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('km'),
  ];

  /// No description provided for @appName.
  ///
  /// In en, this message translates to:
  /// **'LifeMate'**
  String get appName;

  /// No description provided for @navHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get navHome;

  /// No description provided for @navFinance.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get navFinance;

  /// No description provided for @navPlanner.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get navPlanner;

  /// No description provided for @navLists.
  ///
  /// In en, this message translates to:
  /// **'Lists'**
  String get navLists;

  /// No description provided for @navSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @commonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// No description provided for @commonSomethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get commonSomethingWentWrong;

  /// No description provided for @commonSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get commonSeeAll;

  /// No description provided for @commonManage.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get commonManage;

  /// No description provided for @commonCreate.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get commonCreate;

  /// No description provided for @commonAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get commonAll;

  /// No description provided for @commonSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved.'**
  String get commonSaved;

  /// No description provided for @commonOverdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get commonOverdue;

  /// No description provided for @errorPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to access this data.'**
  String get errorPermissionDenied;

  /// No description provided for @errorIndexBuilding.
  ///
  /// In en, this message translates to:
  /// **'A database index is still being created. Try again in a few minutes.'**
  String get errorIndexBuilding;

  /// No description provided for @errorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server. Check your internet connection.'**
  String get errorNetwork;

  /// No description provided for @errorUnexpected.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error. Please try again.'**
  String get errorUnexpected;

  /// No description provided for @validationEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Email address is required.'**
  String get validationEmailRequired;

  /// No description provided for @validationEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get validationEmailInvalid;

  /// No description provided for @validationPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Password is required.'**
  String get validationPasswordRequired;

  /// No description provided for @validationPasswordLength.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get validationPasswordLength;

  /// No description provided for @validationPasswordUppercase.
  ///
  /// In en, this message translates to:
  /// **'Include at least one uppercase letter.'**
  String get validationPasswordUppercase;

  /// No description provided for @validationPasswordNumber.
  ///
  /// In en, this message translates to:
  /// **'Include at least one number.'**
  String get validationPasswordNumber;

  /// No description provided for @validationConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password.'**
  String get validationConfirmPassword;

  /// No description provided for @validationPasswordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get validationPasswordsDontMatch;

  /// No description provided for @validationNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required.'**
  String get validationNameRequired;

  /// No description provided for @validationNameTooShort.
  ///
  /// In en, this message translates to:
  /// **'Name must be at least 2 characters.'**
  String get validationNameTooShort;

  /// No description provided for @validationNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Name must be 50 characters or fewer.'**
  String get validationNameTooLong;

  /// No description provided for @validationRequired.
  ///
  /// In en, this message translates to:
  /// **'{field} is required.'**
  String validationRequired(String field);

  /// No description provided for @validationAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Amount is required.'**
  String get validationAmountRequired;

  /// No description provided for @validationAmountWhole.
  ///
  /// In en, this message translates to:
  /// **'Enter a whole number (no decimals for {currency}).'**
  String validationAmountWhole(String currency);

  /// No description provided for @validationAmountDecimals.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid amount with up to {decimals} decimals.'**
  String validationAmountDecimals(int decimals);

  /// No description provided for @validationAmountPositive.
  ///
  /// In en, this message translates to:
  /// **'Amount must be greater than zero.'**
  String get validationAmountPositive;

  /// No description provided for @authUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No account found with this email address.'**
  String get authUserNotFound;

  /// No description provided for @authWrongPassword.
  ///
  /// In en, this message translates to:
  /// **'Incorrect password. Please try again.'**
  String get authWrongPassword;

  /// No description provided for @authInvalidCredential.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password. Please try again.'**
  String get authInvalidCredential;

  /// No description provided for @authEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'An account already exists with this email address.'**
  String get authEmailInUse;

  /// No description provided for @authWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak. Use at least 8 characters.'**
  String get authWeakPassword;

  /// No description provided for @authInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'The email address is not valid.'**
  String get authInvalidEmail;

  /// No description provided for @authUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled. Contact support.'**
  String get authUserDisabled;

  /// No description provided for @authTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many failed attempts. Please wait a moment and try again.'**
  String get authTooManyRequests;

  /// No description provided for @authOperationNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Email/password sign-in is not enabled. Contact support.'**
  String get authOperationNotAllowed;

  /// No description provided for @authRequiresRecentLogin.
  ///
  /// In en, this message translates to:
  /// **'For security, please log out and log in again before this action.'**
  String get authRequiresRecentLogin;

  /// No description provided for @authNetwork.
  ///
  /// In en, this message translates to:
  /// **'Network error. Check your internet connection.'**
  String get authNetwork;

  /// No description provided for @authGeneric.
  ///
  /// In en, this message translates to:
  /// **'Authentication error: {message}'**
  String authGeneric(String message);

  /// No description provided for @onboardingTitle1.
  ///
  /// In en, this message translates to:
  /// **'Manage Your Money'**
  String get onboardingTitle1;

  /// No description provided for @onboardingBody1.
  ///
  /// In en, this message translates to:
  /// **'Track income and expenses, set spending limits, and reach your savings goals — all in one place.'**
  String get onboardingBody1;

  /// No description provided for @onboardingTitle2.
  ///
  /// In en, this message translates to:
  /// **'Plan Every Day'**
  String get onboardingTitle2;

  /// No description provided for @onboardingBody2.
  ///
  /// In en, this message translates to:
  /// **'Organise tasks, schedule events, set reminders, and never miss an important bill again.'**
  String get onboardingBody2;

  /// No description provided for @onboardingTitle3.
  ///
  /// In en, this message translates to:
  /// **'Stay Organised'**
  String get onboardingTitle3;

  /// No description provided for @onboardingBody3.
  ///
  /// In en, this message translates to:
  /// **'Create shopping lists, track your budget categories, and get clear reports on your spending habits.'**
  String get onboardingBody3;

  /// No description provided for @onboardingSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get onboardingSkip;

  /// No description provided for @onboardingNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get onboardingNext;

  /// No description provided for @onboardingGetStarted.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get onboardingGetStarted;

  /// No description provided for @authAlreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account?'**
  String get authAlreadyHaveAccount;

  /// No description provided for @authLogIn.
  ///
  /// In en, this message translates to:
  /// **'Log In'**
  String get authLogIn;

  /// No description provided for @loginTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get loginTitle;

  /// No description provided for @loginSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in to your LifeMate account.'**
  String get loginSubtitle;

  /// No description provided for @fieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email address'**
  String get fieldEmail;

  /// No description provided for @fieldEmailHint.
  ///
  /// In en, this message translates to:
  /// **'you@example.com'**
  String get fieldEmailHint;

  /// No description provided for @fieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get fieldPassword;

  /// No description provided for @loginForgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get loginForgotPassword;

  /// No description provided for @loginNoAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get loginNoAccount;

  /// No description provided for @loginCreateOne.
  ///
  /// In en, this message translates to:
  /// **'Create one'**
  String get loginCreateOne;

  /// No description provided for @loginFailed.
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get loginFailed;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get registerTitle;

  /// No description provided for @registerSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start managing your money and daily life.'**
  String get registerSubtitle;

  /// No description provided for @registerBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to login'**
  String get registerBackToLogin;

  /// No description provided for @fieldFullName.
  ///
  /// In en, this message translates to:
  /// **'Full name'**
  String get fieldFullName;

  /// No description provided for @fieldFullNameHint.
  ///
  /// In en, this message translates to:
  /// **'John Doe'**
  String get fieldFullNameHint;

  /// No description provided for @fieldPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Min. 8 characters with a number'**
  String get fieldPasswordHint;

  /// No description provided for @fieldConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get fieldConfirmPassword;

  /// No description provided for @fieldConfirmPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'Repeat your password'**
  String get fieldConfirmPasswordHint;

  /// No description provided for @registerButton.
  ///
  /// In en, this message translates to:
  /// **'Create Account'**
  String get registerButton;

  /// No description provided for @registerFailed.
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get registerFailed;

  /// No description provided for @registerPasswordRules.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters, include one uppercase letter and one number.'**
  String get registerPasswordRules;

  /// No description provided for @forgotTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get forgotTitle;

  /// No description provided for @forgotHeadline.
  ///
  /// In en, this message translates to:
  /// **'Forgot your password?'**
  String get forgotHeadline;

  /// No description provided for @forgotBody.
  ///
  /// In en, this message translates to:
  /// **'Enter the email address associated with your account and we\'ll send you a password reset link.'**
  String get forgotBody;

  /// No description provided for @forgotSendButton.
  ///
  /// In en, this message translates to:
  /// **'Send Reset Link'**
  String get forgotSendButton;

  /// No description provided for @forgotBackToLogin.
  ///
  /// In en, this message translates to:
  /// **'Back to Login'**
  String get forgotBackToLogin;

  /// No description provided for @forgotSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent. Check your inbox.'**
  String get forgotSent;

  /// No description provided for @forgotFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send reset email.'**
  String get forgotFailed;

  /// No description provided for @forgotCheckInbox.
  ///
  /// In en, this message translates to:
  /// **'Check your inbox'**
  String get forgotCheckInbox;

  /// No description provided for @forgotCheckInboxBody.
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a password reset link to your email address. Click the link to set a new password.'**
  String get forgotCheckInboxBody;

  /// No description provided for @homeGreeting.
  ///
  /// In en, this message translates to:
  /// **'Hi, {name} 👋'**
  String homeGreeting(String name);

  /// No description provided for @homeTodaysSpending.
  ///
  /// In en, this message translates to:
  /// **'Today\'s spending'**
  String get homeTodaysSpending;

  /// No description provided for @homeNoSpendingToday.
  ///
  /// In en, this message translates to:
  /// **'No spending yet today'**
  String get homeNoSpendingToday;

  /// No description provided for @homeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get homeIncome;

  /// No description provided for @homeExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get homeExpenses;

  /// No description provided for @homeNet.
  ///
  /// In en, this message translates to:
  /// **'Net (income − expenses)'**
  String get homeNet;

  /// No description provided for @homeNoTransactionsMonth.
  ///
  /// In en, this message translates to:
  /// **'No income or expenses this month yet. Use the quick actions above to add your first one.'**
  String get homeNoTransactionsMonth;

  /// No description provided for @homeSpendingLimits.
  ///
  /// In en, this message translates to:
  /// **'Spending limits'**
  String get homeSpendingLimits;

  /// No description provided for @homeRecentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get homeRecentTransactions;

  /// No description provided for @homeNothingRecorded.
  ///
  /// In en, this message translates to:
  /// **'Nothing recorded in {month}'**
  String homeNothingRecorded(String month);

  /// No description provided for @homeNothingRecordedBody.
  ///
  /// In en, this message translates to:
  /// **'Add an income or expense to start tracking your money.'**
  String get homeNothingRecordedBody;

  /// No description provided for @homeComingUp.
  ///
  /// In en, this message translates to:
  /// **'Coming up this week'**
  String get homeComingUp;

  /// No description provided for @homeNothingThisWeek.
  ///
  /// In en, this message translates to:
  /// **'No tasks, events or bills in the next 7 days.'**
  String get homeNothingThisWeek;

  /// No description provided for @homeBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get homeBudgets;

  /// No description provided for @homeNoActiveBudget.
  ///
  /// In en, this message translates to:
  /// **'No active budget. Plan this month\'s spending in Finance.'**
  String get homeNoActiveBudget;

  /// No description provided for @homeSavingsGoals.
  ///
  /// In en, this message translates to:
  /// **'Savings goals'**
  String get homeSavingsGoals;

  /// No description provided for @homeNoSavingsGoal.
  ///
  /// In en, this message translates to:
  /// **'No savings goal yet.'**
  String get homeNoSavingsGoal;

  /// No description provided for @homePreviousMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get homePreviousMonth;

  /// No description provided for @homeNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get homeNextMonth;

  /// No description provided for @quickIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get quickIncome;

  /// No description provided for @quickExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get quickExpense;

  /// No description provided for @quickTask.
  ///
  /// In en, this message translates to:
  /// **'Task'**
  String get quickTask;

  /// No description provided for @quickShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get quickShopping;

  /// No description provided for @financeTitle.
  ///
  /// In en, this message translates to:
  /// **'Finance'**
  String get financeTitle;

  /// No description provided for @financeTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get financeTransactions;

  /// No description provided for @financeTransactionsDesc.
  ///
  /// In en, this message translates to:
  /// **'Income and expense history, search and filters'**
  String get financeTransactionsDesc;

  /// No description provided for @financeLimits.
  ///
  /// In en, this message translates to:
  /// **'Spending limits'**
  String get financeLimits;

  /// No description provided for @financeLimitsDesc.
  ///
  /// In en, this message translates to:
  /// **'Daily and monthly limits with alerts'**
  String get financeLimitsDesc;

  /// No description provided for @financeCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get financeCategories;

  /// No description provided for @financeCategoriesDesc.
  ///
  /// In en, this message translates to:
  /// **'Manage your income and expense categories'**
  String get financeCategoriesDesc;

  /// No description provided for @financeBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get financeBudgets;

  /// No description provided for @financeBudgetsDesc.
  ///
  /// In en, this message translates to:
  /// **'Plan spending per category'**
  String get financeBudgetsDesc;

  /// No description provided for @financeSavings.
  ///
  /// In en, this message translates to:
  /// **'Savings goals'**
  String get financeSavings;

  /// No description provided for @financeSavingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Track progress toward your targets'**
  String get financeSavingsDesc;

  /// No description provided for @financeReports.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get financeReports;

  /// No description provided for @financeReportsDesc.
  ///
  /// In en, this message translates to:
  /// **'Spending by category, CSV export'**
  String get financeReportsDesc;

  /// No description provided for @plannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get plannerTitle;

  /// No description provided for @plannerTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get plannerTasks;

  /// No description provided for @plannerCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get plannerCalendar;

  /// No description provided for @plannerReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders'**
  String get plannerReminders;

  /// No description provided for @listsTitle.
  ///
  /// In en, this message translates to:
  /// **'Shopping lists'**
  String get listsTitle;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsEditProfile.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get settingsEditProfile;

  /// No description provided for @settingsEditProfileDesc.
  ///
  /// In en, this message translates to:
  /// **'Change your display name'**
  String get settingsEditProfileDesc;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePassword;

  /// No description provided for @settingsChangePasswordDesc.
  ///
  /// In en, this message translates to:
  /// **'Update your account password'**
  String get settingsChangePasswordDesc;

  /// No description provided for @settingsPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsPreferences;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Default currency'**
  String get settingsCurrency;

  /// No description provided for @settingsTimeZone.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get settingsTimeZone;

  /// No description provided for @settingsTimeZoneAuto.
  ///
  /// In en, this message translates to:
  /// **'{zone} · from your phone'**
  String settingsTimeZoneAuto(String zone);

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'Alerts, reminders and permissions'**
  String get settingsNotificationsDesc;

  /// No description provided for @settingsPrivacyData.
  ///
  /// In en, this message translates to:
  /// **'Privacy & data'**
  String get settingsPrivacyData;

  /// No description provided for @settingsPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy information'**
  String get settingsPrivacy;

  /// No description provided for @settingsPrivacyDesc.
  ///
  /// In en, this message translates to:
  /// **'What we store and who can see it'**
  String get settingsPrivacyDesc;

  /// No description provided for @settingsDeleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get settingsDeleteAccount;

  /// No description provided for @settingsDeleteAccountDesc.
  ///
  /// In en, this message translates to:
  /// **'Permanently delete your account and data'**
  String get settingsDeleteAccountDesc;

  /// No description provided for @settingsLogOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogOut;

  /// No description provided for @settingsLogOutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to log out of LifeMate?'**
  String get settingsLogOutConfirm;

  /// No description provided for @settingsVersion.
  ///
  /// In en, this message translates to:
  /// **'LifeMate v{version}'**
  String settingsVersion(String version);

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageKhmer.
  ///
  /// In en, this message translates to:
  /// **'ខ្មែរ (Khmer)'**
  String get languageKhmer;

  /// No description provided for @chooseLanguage.
  ///
  /// In en, this message translates to:
  /// **'Choose language'**
  String get chooseLanguage;

  /// No description provided for @chooseCurrency.
  ///
  /// In en, this message translates to:
  /// **'Default currency'**
  String get chooseCurrency;

  /// No description provided for @currencyNote.
  ///
  /// In en, this message translates to:
  /// **'Used as the default for new transactions, limits, budgets and goals. Existing records keep their own currency — LifeMate never converts between currencies.'**
  String get currencyNote;

  /// No description provided for @timeZoneTitle.
  ///
  /// In en, this message translates to:
  /// **'Time zone'**
  String get timeZoneTitle;

  /// No description provided for @timeZoneBody.
  ///
  /// In en, this message translates to:
  /// **'LifeMate uses your phone\'s time zone ({zone}) to decide when a day or month starts — for spending limits, budgets, reports and reminders.\n\nTo use a different time zone, change it in your phone\'s Date & time settings. LifeMate saves it to your profile automatically.'**
  String timeZoneBody(String zone);

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get profileTitle;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get profileName;

  /// No description provided for @profileEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileEmail;

  /// No description provided for @profileEmailNote.
  ///
  /// In en, this message translates to:
  /// **'Your email is your login and cannot be changed in the app.'**
  String get profileEmailNote;

  /// No description provided for @profileSaved.
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get profileSaved;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmNewPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirmNewPassword;

  /// No description provided for @changePasswordButton.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordButton;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed.'**
  String get passwordChanged;

  /// No description provided for @newPasswordSame.
  ///
  /// In en, this message translates to:
  /// **'The new password must be different from the current one.'**
  String get newPasswordSame;

  /// No description provided for @changePasswordInfo.
  ///
  /// In en, this message translates to:
  /// **'For your security, enter your current password first.'**
  String get changePasswordInfo;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsPermissionOn.
  ///
  /// In en, this message translates to:
  /// **'Notifications are allowed'**
  String get notificationsPermissionOn;

  /// No description provided for @notificationsPermissionOff.
  ///
  /// In en, this message translates to:
  /// **'Notifications are not allowed'**
  String get notificationsPermissionOff;

  /// No description provided for @notificationsAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow notifications'**
  String get notificationsAllow;

  /// No description provided for @notificationsBlockedHelp.
  ///
  /// In en, this message translates to:
  /// **'If nothing happens, LifeMate was blocked earlier. Open your phone\'s Settings → Apps → LifeMate → Notifications.'**
  String get notificationsBlockedHelp;

  /// No description provided for @notificationsExact.
  ///
  /// In en, this message translates to:
  /// **'Exact reminder times'**
  String get notificationsExact;

  /// No description provided for @notificationsExactDesc.
  ///
  /// In en, this message translates to:
  /// **'Android may deliver reminders a few minutes late unless you allow alarms for LifeMate.'**
  String get notificationsExactDesc;

  /// No description provided for @notificationsExactAllow.
  ///
  /// In en, this message translates to:
  /// **'Allow exact alarms'**
  String get notificationsExactAllow;

  /// No description provided for @notificationsCategories.
  ///
  /// In en, this message translates to:
  /// **'Notify me about'**
  String get notificationsCategories;

  /// No description provided for @notifySpendingLimits.
  ///
  /// In en, this message translates to:
  /// **'Spending limits'**
  String get notifySpendingLimits;

  /// No description provided for @notifySpendingLimitsDesc.
  ///
  /// In en, this message translates to:
  /// **'Warning, reached and exceeded alerts'**
  String get notifySpendingLimitsDesc;

  /// No description provided for @notifyReminders.
  ///
  /// In en, this message translates to:
  /// **'Reminders & bills'**
  String get notifyReminders;

  /// No description provided for @notifyRemindersDesc.
  ///
  /// In en, this message translates to:
  /// **'Your reminders and bill due dates'**
  String get notifyRemindersDesc;

  /// No description provided for @notifyTasks.
  ///
  /// In en, this message translates to:
  /// **'Tasks'**
  String get notifyTasks;

  /// No description provided for @notifyTasksDesc.
  ///
  /// In en, this message translates to:
  /// **'Tasks with \"Remind me\" turned on'**
  String get notifyTasksDesc;

  /// No description provided for @notifyEvents.
  ///
  /// In en, this message translates to:
  /// **'Calendar events'**
  String get notifyEvents;

  /// No description provided for @notifyEventsDesc.
  ///
  /// In en, this message translates to:
  /// **'Events with a reminder'**
  String get notifyEventsDesc;

  /// No description provided for @notifySavings.
  ///
  /// In en, this message translates to:
  /// **'Savings goals'**
  String get notifySavings;

  /// No description provided for @notifySavingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Monthly \"time to save\" reminders'**
  String get notifySavingsDesc;

  /// No description provided for @notificationsInAppNote.
  ///
  /// In en, this message translates to:
  /// **'Turning a type off only stops pop-up notifications. You still see everything inside the app.'**
  String get notificationsInAppNote;

  /// No description provided for @privacyTitle.
  ///
  /// In en, this message translates to:
  /// **'Privacy information'**
  String get privacyTitle;

  /// No description provided for @privacyWhatTitle.
  ///
  /// In en, this message translates to:
  /// **'What LifeMate stores'**
  String get privacyWhatTitle;

  /// No description provided for @privacyWhatBody.
  ///
  /// In en, this message translates to:
  /// **'Your name and email, your preferences, and the data you enter: transactions, categories, limits, budgets, savings goals, tasks, events, reminders and shopping lists. LifeMate never stores your password — Firebase Authentication handles it securely.'**
  String get privacyWhatBody;

  /// No description provided for @privacyWhereTitle.
  ///
  /// In en, this message translates to:
  /// **'Where it is stored'**
  String get privacyWhereTitle;

  /// No description provided for @privacyWhereBody.
  ///
  /// In en, this message translates to:
  /// **'In Google Firebase (Cloud Firestore), encrypted in transit and at rest. A copy is cached on this phone so the app works offline.'**
  String get privacyWhereBody;

  /// No description provided for @privacyWhoTitle.
  ///
  /// In en, this message translates to:
  /// **'Who can see it'**
  String get privacyWhoTitle;

  /// No description provided for @privacyWhoBody.
  ///
  /// In en, this message translates to:
  /// **'Only you. Security rules on the server allow each account to read and write only its own data. LifeMate has no ads and does not sell or share your data.'**
  String get privacyWhoBody;

  /// No description provided for @privacyDeviceTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get privacyDeviceTitle;

  /// No description provided for @privacyDeviceBody.
  ///
  /// In en, this message translates to:
  /// **'Reminders are scheduled on this phone by your phone\'s alarm system. Their text stays on the device.'**
  String get privacyDeviceBody;

  /// No description provided for @privacyExportTitle.
  ///
  /// In en, this message translates to:
  /// **'Your data, your copy'**
  String get privacyExportTitle;

  /// No description provided for @privacyExportBody.
  ///
  /// In en, this message translates to:
  /// **'You can export your transactions as a CSV file from Finance → Reports at any time.'**
  String get privacyExportBody;

  /// No description provided for @privacyDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Deleting your data'**
  String get privacyDeleteTitle;

  /// No description provided for @privacyDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Settings → Delete account permanently removes your account and everything you stored. This cannot be undone.'**
  String get privacyDeleteBody;

  /// No description provided for @deleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteTitle;

  /// No description provided for @deleteWarning.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes your LifeMate account and ALL of your data. It cannot be undone.'**
  String get deleteWarning;

  /// No description provided for @deleteWhatIsDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted: transactions, categories, spending limits, budgets, savings goals and their history, tasks, calendar events, reminders, shopping lists and your profile.'**
  String get deleteWhatIsDeleted;

  /// No description provided for @deleteExportHint.
  ///
  /// In en, this message translates to:
  /// **'Want a copy first? Export your transactions in Finance → Reports.'**
  String get deleteExportHint;

  /// No description provided for @deletePasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm'**
  String get deletePasswordLabel;

  /// No description provided for @deleteButton.
  ///
  /// In en, this message translates to:
  /// **'Delete my account'**
  String get deleteButton;

  /// No description provided for @deleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete everything?'**
  String get deleteConfirmTitle;

  /// No description provided for @deleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your account and all data will be removed permanently.'**
  String get deleteConfirmBody;

  /// No description provided for @deleteInProgress.
  ///
  /// In en, this message translates to:
  /// **'Deleting your data…'**
  String get deleteInProgress;

  /// No description provided for @deleteDone.
  ///
  /// In en, this message translates to:
  /// **'Your account was deleted.'**
  String get deleteDone;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'km'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'km':
      return AppLocalizationsKm();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
