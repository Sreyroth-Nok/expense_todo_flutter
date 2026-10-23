// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Khmer Central Khmer (`km`).
class AppLocalizationsKm extends AppLocalizations {
  AppLocalizationsKm([String locale = 'km']) : super(locale);

  @override
  String get appName => 'LifeMate';

  @override
  String get navHome => 'ទំព័រដើម';

  @override
  String get navFinance => 'ហិរញ្ញវត្ថុ';

  @override
  String get navPlanner => 'ផែនការ';

  @override
  String get navLists => 'បញ្ជី';

  @override
  String get navSettings => 'ការកំណត់';

  @override
  String get commonCancel => 'បោះបង់';

  @override
  String get commonSave => 'រក្សាទុក';

  @override
  String get commonDelete => 'លុប';

  @override
  String get commonClose => 'បិទ';

  @override
  String get commonTryAgain => 'ព្យាយាមម្តងទៀត';

  @override
  String get commonSomethingWentWrong => 'មានបញ្ហាកើតឡើង';

  @override
  String get commonSeeAll => 'មើលទាំងអស់';

  @override
  String get commonManage => 'គ្រប់គ្រង';

  @override
  String get commonCreate => 'បង្កើត';

  @override
  String get commonAll => 'ទាំងអស់';

  @override
  String get commonSaved => 'បានរក្សាទុក។';

  @override
  String get commonOverdue => 'ហួសកំណត់';

  @override
  String get errorPermissionDenied => 'អ្នកគ្មានសិទ្ធិចូលប្រើទិន្នន័យនេះទេ។';

  @override
  String get errorIndexBuilding =>
      'កំពុងរៀបចំមូលដ្ឋានទិន្នន័យ។ សូមព្យាយាមម្តងទៀតក្នុងរយៈពេលប៉ុន្មាននាទីទៀត។';

  @override
  String get errorNetwork =>
      'មិនអាចភ្ជាប់ទៅម៉ាស៊ីនមេបានទេ។ សូមពិនិត្យការតភ្ជាប់អ៊ីនធឺណិត។';

  @override
  String get errorUnexpected => 'មានកំហុសដែលមិនបានរំពឹងទុក។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get validationEmailRequired => 'តម្រូវឱ្យបញ្ចូលអាសយដ្ឋានអ៊ីមែល។';

  @override
  String get validationEmailInvalid =>
      'សូមបញ្ចូលអាសយដ្ឋានអ៊ីមែលឱ្យបានត្រឹមត្រូវ។';

  @override
  String get validationPasswordRequired => 'តម្រូវឱ្យបញ្ចូលពាក្យសម្ងាត់។';

  @override
  String get validationPasswordLength =>
      'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងហោចណាស់ ៨ តួអក្សរ។';

  @override
  String get validationPasswordUppercase => 'សូមដាក់អក្សរធំយ៉ាងហោចណាស់មួយ។';

  @override
  String get validationPasswordNumber => 'សូមដាក់លេខយ៉ាងហោចណាស់មួយ។';

  @override
  String get validationConfirmPassword => 'សូមបញ្ជាក់ពាក្យសម្ងាត់របស់អ្នក។';

  @override
  String get validationPasswordsDontMatch => 'ពាក្យសម្ងាត់មិនដូចគ្នាទេ។';

  @override
  String get validationNameRequired => 'តម្រូវឱ្យបញ្ចូលឈ្មោះ។';

  @override
  String get validationNameTooShort => 'ឈ្មោះត្រូវមានយ៉ាងហោចណាស់ ២ តួអក្សរ។';

  @override
  String get validationNameTooLong => 'ឈ្មោះមិនត្រូវលើសពី ៥០ តួអក្សរទេ។';

  @override
  String validationRequired(String field) {
    return 'តម្រូវឱ្យបញ្ចូល$field។';
  }

  @override
  String get validationAmountRequired => 'តម្រូវឱ្យបញ្ចូលចំនួនទឹកប្រាក់។';

  @override
  String validationAmountWhole(String currency) {
    return 'សូមបញ្ចូលចំនួនគត់ (គ្មានខ្ទង់ទសភាគសម្រាប់ $currency)។';
  }

  @override
  String validationAmountDecimals(int decimals) {
    return 'សូមបញ្ចូលចំនួនទឹកប្រាក់ត្រឹមត្រូវ ដែលមានខ្ទង់ទសភាគមិនលើសពី $decimals។';
  }

  @override
  String get validationAmountPositive => 'ចំនួនទឹកប្រាក់ត្រូវធំជាងសូន្យ។';

  @override
  String get authUserNotFound => 'រកមិនឃើញគណនីដែលប្រើអ៊ីមែលនេះទេ។';

  @override
  String get authWrongPassword =>
      'ពាក្យសម្ងាត់មិនត្រឹមត្រូវ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get authInvalidCredential =>
      'អ៊ីមែល ឬពាក្យសម្ងាត់មិនត្រឹមត្រូវ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get authEmailInUse => 'មានគណនីប្រើអ៊ីមែលនេះរួចហើយ។';

  @override
  String get authWeakPassword =>
      'ពាក្យសម្ងាត់ខ្សោយពេក។ សូមប្រើយ៉ាងហោចណាស់ ៨ តួអក្សរ។';

  @override
  String get authInvalidEmail => 'អាសយដ្ឋានអ៊ីមែលមិនត្រឹមត្រូវ។';

  @override
  String get authUserDisabled => 'គណនីនេះត្រូវបានបិទ។ សូមទាក់ទងផ្នែកជំនួយ។';

  @override
  String get authTooManyRequests =>
      'ព្យាយាមខុសច្រើនដងពេក។ សូមរង់ចាំបន្តិច រួចព្យាយាមម្តងទៀត។';

  @override
  String get authOperationNotAllowed =>
      'ការចូលដោយអ៊ីមែល/ពាក្យសម្ងាត់មិនត្រូវបានបើកទេ។ សូមទាក់ទងផ្នែកជំនួយ។';

  @override
  String get authRequiresRecentLogin =>
      'ដើម្បីសុវត្ថិភាព សូមចាកចេញ ហើយចូលម្តងទៀត មុនពេលធ្វើសកម្មភាពនេះ។';

  @override
  String get authNetwork => 'បញ្ហាបណ្តាញ។ សូមពិនិត្យការតភ្ជាប់អ៊ីនធឺណិត។';

  @override
  String authGeneric(String message) {
    return 'កំហុសក្នុងការផ្ទៀងផ្ទាត់៖ $message';
  }

  @override
  String get onboardingTitle1 => 'គ្រប់គ្រងប្រាក់របស់អ្នក';

  @override
  String get onboardingBody1 =>
      'តាមដានចំណូល និងចំណាយ កំណត់ដែនកំណត់ចំណាយ និងសម្រេចគោលដៅសន្សំ — ទាំងអស់នៅកន្លែងតែមួយ។';

  @override
  String get onboardingTitle2 => 'រៀបចំផែនការរាល់ថ្ងៃ';

  @override
  String get onboardingBody2 =>
      'រៀបចំកិច្ចការ កំណត់ពេលព្រឹត្តិការណ៍ កំណត់ការរំលឹក ហើយកុំភ្លេចបង់វិក្កយបត្រសំខាន់ៗទៀត។';

  @override
  String get onboardingTitle3 => 'រៀបចំឱ្យមានសណ្តាប់ធ្នាប់';

  @override
  String get onboardingBody3 =>
      'បង្កើតបញ្ជីទិញឥវ៉ាន់ តាមដានប្រភេទថវិកា និងទទួលបានរបាយការណ៍ច្បាស់លាស់អំពីការចំណាយរបស់អ្នក។';

  @override
  String get onboardingSkip => 'រំលង';

  @override
  String get onboardingNext => 'បន្ទាប់';

  @override
  String get onboardingGetStarted => 'ចាប់ផ្តើម';

  @override
  String get authAlreadyHaveAccount => 'មានគណនីរួចហើយមែនទេ?';

  @override
  String get authLogIn => 'ចូល';

  @override
  String get loginTitle => 'សូមស្វាគមន៍ការត្រឡប់មកវិញ';

  @override
  String get loginSubtitle => 'ចូលទៅក្នុងគណនី LifeMate របស់អ្នក។';

  @override
  String get fieldEmail => 'អាសយដ្ឋានអ៊ីមែល';

  @override
  String get fieldEmailHint => 'you@example.com';

  @override
  String get fieldPassword => 'ពាក្យសម្ងាត់';

  @override
  String get loginForgotPassword => 'ភ្លេចពាក្យសម្ងាត់?';

  @override
  String get loginNoAccount => 'មិនទាន់មានគណនី?';

  @override
  String get loginCreateOne => 'បង្កើតគណនី';

  @override
  String get loginFailed => 'ការចូលបរាជ័យ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get registerTitle => 'បង្កើតគណនី';

  @override
  String get registerSubtitle =>
      'ចាប់ផ្តើមគ្រប់គ្រងប្រាក់ និងជីវិតប្រចាំថ្ងៃរបស់អ្នក។';

  @override
  String get registerBackToLogin => 'ត្រឡប់ទៅទំព័រចូល';

  @override
  String get fieldFullName => 'ឈ្មោះពេញ';

  @override
  String get fieldFullNameHint => 'សុខ ដារ៉ា';

  @override
  String get fieldPasswordHint => 'យ៉ាងហោចណាស់ ៨ តួអក្សរ និងមានលេខ';

  @override
  String get fieldConfirmPassword => 'បញ្ជាក់ពាក្យសម្ងាត់';

  @override
  String get fieldConfirmPasswordHint => 'វាយពាក្យសម្ងាត់ម្តងទៀត';

  @override
  String get registerButton => 'បង្កើតគណនី';

  @override
  String get registerFailed => 'ការចុះឈ្មោះបរាជ័យ។ សូមព្យាយាមម្តងទៀត។';

  @override
  String get registerPasswordRules =>
      'ពាក្យសម្ងាត់ត្រូវមានយ៉ាងហោចណាស់ ៨ តួអក្សរ មានអក្សរធំមួយ និងលេខមួយ។';

  @override
  String get forgotTitle => 'កំណត់ពាក្យសម្ងាត់ឡើងវិញ';

  @override
  String get forgotHeadline => 'ភ្លេចពាក្យសម្ងាត់?';

  @override
  String get forgotBody =>
      'បញ្ចូលអាសយដ្ឋានអ៊ីមែលនៃគណនីរបស់អ្នក យើងនឹងផ្ញើតំណសម្រាប់កំណត់ពាក្យសម្ងាត់ឡើងវិញ។';

  @override
  String get forgotSendButton => 'ផ្ញើតំណ';

  @override
  String get forgotBackToLogin => 'ត្រឡប់ទៅទំព័រចូល';

  @override
  String get forgotSent =>
      'បានផ្ញើអ៊ីមែលកំណត់ពាក្យសម្ងាត់ឡើងវិញ។ សូមពិនិត្យប្រអប់សំបុត្ររបស់អ្នក។';

  @override
  String get forgotFailed => 'មិនអាចផ្ញើអ៊ីមែលកំណត់ពាក្យសម្ងាត់ឡើងវិញបានទេ។';

  @override
  String get forgotCheckInbox => 'ពិនិត្យប្រអប់សំបុត្ររបស់អ្នក';

  @override
  String get forgotCheckInboxBody =>
      'យើងបានផ្ញើតំណកំណត់ពាក្យសម្ងាត់ឡើងវិញទៅអ៊ីមែលរបស់អ្នក។ សូមចុចតំណនោះដើម្បីកំណត់ពាក្យសម្ងាត់ថ្មី។';

  @override
  String homeGreeting(String name) {
    return 'សួស្តី $name 👋';
  }

  @override
  String get homeTodaysSpending => 'ចំណាយថ្ងៃនេះ';

  @override
  String get homeNoSpendingToday => 'មិនទាន់មានការចំណាយថ្ងៃនេះទេ';

  @override
  String get homeIncome => 'ចំណូល';

  @override
  String get homeExpenses => 'ចំណាយ';

  @override
  String get homeNet => 'សមតុល្យ (ចំណូល − ចំណាយ)';

  @override
  String get homeNoTransactionsMonth =>
      'ខែនេះមិនទាន់មានចំណូល ឬចំណាយនៅឡើយទេ។ ប្រើប៊ូតុងខាងលើដើម្បីបញ្ចូលលើកដំបូង។';

  @override
  String get homeSpendingLimits => 'ដែនកំណត់ចំណាយ';

  @override
  String get homeRecentTransactions => 'ប្រតិបត្តិការថ្មីៗ';

  @override
  String homeNothingRecorded(String month) {
    return 'មិនមានកំណត់ត្រាក្នុង $month';
  }

  @override
  String get homeNothingRecordedBody =>
      'បញ្ចូលចំណូល ឬចំណាយ ដើម្បីចាប់ផ្តើមតាមដានប្រាក់របស់អ្នក។';

  @override
  String get homeComingUp => 'សប្តាហ៍នេះ';

  @override
  String get homeNothingThisWeek =>
      'មិនមានកិច្ចការ ព្រឹត្តិការណ៍ ឬវិក្កយបត្រក្នុង ៧ ថ្ងៃខាងមុខទេ។';

  @override
  String get homeBudgets => 'ថវិកា';

  @override
  String get homeNoActiveBudget =>
      'មិនមានថវិកាសកម្មទេ។ រៀបចំផែនការចំណាយខែនេះនៅក្នុងផ្នែកហិរញ្ញវត្ថុ។';

  @override
  String get homeSavingsGoals => 'គោលដៅសន្សំ';

  @override
  String get homeNoSavingsGoal => 'មិនទាន់មានគោលដៅសន្សំទេ។';

  @override
  String get homePreviousMonth => 'ខែមុន';

  @override
  String get homeNextMonth => 'ខែបន្ទាប់';

  @override
  String get quickIncome => 'ចំណូល';

  @override
  String get quickExpense => 'ចំណាយ';

  @override
  String get quickTask => 'កិច្ចការ';

  @override
  String get quickShopping => 'ទិញឥវ៉ាន់';

  @override
  String get financeTitle => 'ហិរញ្ញវត្ថុ';

  @override
  String get financeTransactions => 'ប្រតិបត្តិការ';

  @override
  String get financeTransactionsDesc =>
      'ប្រវត្តិចំណូល និងចំណាយ ការស្វែងរក និងតម្រង';

  @override
  String get financeLimits => 'ដែនកំណត់ចំណាយ';

  @override
  String get financeLimitsDesc =>
      'ដែនកំណត់ប្រចាំថ្ងៃ និងប្រចាំខែ ជាមួយការជូនដំណឹង';

  @override
  String get financeCategories => 'ប្រភេទ';

  @override
  String get financeCategoriesDesc => 'គ្រប់គ្រងប្រភេទចំណូល និងចំណាយ';

  @override
  String get financeBudgets => 'ថវិកា';

  @override
  String get financeBudgetsDesc => 'រៀបចំផែនការចំណាយតាមប្រភេទ';

  @override
  String get financeSavings => 'គោលដៅសន្សំ';

  @override
  String get financeSavingsDesc => 'តាមដានវឌ្ឍនភាពឆ្ពោះទៅគោលដៅ';

  @override
  String get financeReports => 'របាយការណ៍';

  @override
  String get financeReportsDesc => 'ចំណាយតាមប្រភេទ និងនាំចេញជា CSV';

  @override
  String get plannerTitle => 'ផែនការ';

  @override
  String get plannerTasks => 'កិច្ចការ';

  @override
  String get plannerCalendar => 'ប្រតិទិន';

  @override
  String get plannerReminders => 'ការរំលឹក';

  @override
  String get listsTitle => 'បញ្ជីទិញឥវ៉ាន់';

  @override
  String get settingsTitle => 'ការកំណត់';

  @override
  String get settingsAccount => 'គណនី';

  @override
  String get settingsEditProfile => 'កែប្រែប្រវត្តិរូប';

  @override
  String get settingsEditProfileDesc => 'ប្តូរឈ្មោះបង្ហាញរបស់អ្នក';

  @override
  String get settingsChangePassword => 'ប្តូរពាក្យសម្ងាត់';

  @override
  String get settingsChangePasswordDesc => 'ធ្វើបច្ចុប្បន្នភាពពាក្យសម្ងាត់គណនី';

  @override
  String get settingsPreferences => 'ចំណូលចិត្ត';

  @override
  String get settingsLanguage => 'ភាសា';

  @override
  String get settingsCurrency => 'រូបិយប័ណ្ណលំនាំដើម';

  @override
  String get settingsTimeZone => 'តំបន់ពេលវេលា';

  @override
  String settingsTimeZoneAuto(String zone) {
    return '$zone · តាមទូរស័ព្ទរបស់អ្នក';
  }

  @override
  String get settingsNotifications => 'ការជូនដំណឹង';

  @override
  String get settingsNotificationsDesc => 'ការជូនដំណឹង ការរំលឹក និងការអនុញ្ញាត';

  @override
  String get settingsPrivacyData => 'ឯកជនភាព និងទិន្នន័យ';

  @override
  String get settingsPrivacy => 'ព័ត៌មានឯកជនភាព';

  @override
  String get settingsPrivacyDesc => 'អ្វីដែលយើងរក្សាទុក និងអ្នកណាអាចមើលឃើញ';

  @override
  String get settingsDeleteAccount => 'លុបគណនី';

  @override
  String get settingsDeleteAccountDesc =>
      'លុបគណនី និងទិន្នន័យរបស់អ្នកជាអចិន្ត្រៃយ៍';

  @override
  String get settingsLogOut => 'ចាកចេញ';

  @override
  String get settingsLogOutConfirm =>
      'តើអ្នកប្រាកដជាចង់ចាកចេញពី LifeMate មែនទេ?';

  @override
  String settingsVersion(String version) {
    return 'LifeMate កំណែ $version';
  }

  @override
  String get languageEnglish => 'English (អង់គ្លេស)';

  @override
  String get languageKhmer => 'ខ្មែរ';

  @override
  String get chooseLanguage => 'ជ្រើសរើសភាសា';

  @override
  String get chooseCurrency => 'រូបិយប័ណ្ណលំនាំដើម';

  @override
  String get currencyNote =>
      'ប្រើជាលំនាំដើមសម្រាប់ប្រតិបត្តិការ ដែនកំណត់ ថវិកា និងគោលដៅថ្មីៗ។ កំណត់ត្រាដែលមានស្រាប់រក្សារូបិយប័ណ្ណរបស់វាដដែល — LifeMate មិនដែលប្តូររូបិយប័ណ្ណទេ។';

  @override
  String get timeZoneTitle => 'តំបន់ពេលវេលា';

  @override
  String timeZoneBody(String zone) {
    return 'LifeMate ប្រើតំបន់ពេលវេលារបស់ទូរស័ព្ទអ្នក ($zone) ដើម្បីកំណត់ពេលចាប់ផ្តើមថ្ងៃ ឬខែ — សម្រាប់ដែនកំណត់ចំណាយ ថវិកា របាយការណ៍ និងការរំលឹក។\n\nដើម្បីប្រើតំបន់ពេលវេលាផ្សេង សូមប្តូរនៅក្នុងការកំណត់ កាលបរិច្ឆេទ និងម៉ោង របស់ទូរស័ព្ទ។ LifeMate នឹងរក្សាទុកវាទៅក្នុងប្រវត្តិរូបរបស់អ្នកដោយស្វ័យប្រវត្តិ។';
  }

  @override
  String get profileTitle => 'កែប្រែប្រវត្តិរូប';

  @override
  String get profileName => 'ឈ្មោះបង្ហាញ';

  @override
  String get profileEmail => 'អ៊ីមែល';

  @override
  String get profileEmailNote =>
      'អ៊ីមែលរបស់អ្នកប្រើសម្រាប់ចូលគណនី ហើយមិនអាចប្តូរក្នុងកម្មវិធីបានទេ។';

  @override
  String get profileSaved => 'បានធ្វើបច្ចុប្បន្នភាពប្រវត្តិរូប។';

  @override
  String get changePasswordTitle => 'ប្តូរពាក្យសម្ងាត់';

  @override
  String get currentPassword => 'ពាក្យសម្ងាត់បច្ចុប្បន្ន';

  @override
  String get newPassword => 'ពាក្យសម្ងាត់ថ្មី';

  @override
  String get confirmNewPassword => 'បញ្ជាក់ពាក្យសម្ងាត់ថ្មី';

  @override
  String get changePasswordButton => 'ប្តូរពាក្យសម្ងាត់';

  @override
  String get passwordChanged => 'បានប្តូរពាក្យសម្ងាត់។';

  @override
  String get newPasswordSame =>
      'ពាក្យសម្ងាត់ថ្មីត្រូវខុសពីពាក្យសម្ងាត់បច្ចុប្បន្ន។';

  @override
  String get changePasswordInfo =>
      'ដើម្បីសុវត្ថិភាព សូមបញ្ចូលពាក្យសម្ងាត់បច្ចុប្បន្នជាមុនសិន។';

  @override
  String get notificationsTitle => 'ការជូនដំណឹង';

  @override
  String get notificationsPermissionOn => 'បានអនុញ្ញាតការជូនដំណឹង';

  @override
  String get notificationsPermissionOff => 'មិនទាន់អនុញ្ញាតការជូនដំណឹងទេ';

  @override
  String get notificationsAllow => 'អនុញ្ញាតការជូនដំណឹង';

  @override
  String get notificationsBlockedHelp =>
      'ប្រសិនបើគ្មានអ្វីកើតឡើង មានន័យថា LifeMate ត្រូវបានរារាំងពីមុន។ សូមបើក ការកំណត់ → កម្មវិធី → LifeMate → ការជូនដំណឹង នៅក្នុងទូរស័ព្ទ។';

  @override
  String get notificationsExact => 'ម៉ោងរំលឹកត្រឹមត្រូវ';

  @override
  String get notificationsExactDesc =>
      'Android អាចនឹងរំលឹកយឺតប៉ុន្មាននាទី ប្រសិនបើអ្នកមិនអនុញ្ញាតឱ្យ LifeMate ប្រើម៉ោងរោទ៍។';

  @override
  String get notificationsExactAllow => 'អនុញ្ញាតម៉ោងរោទ៍ត្រឹមត្រូវ';

  @override
  String get notificationsCategories => 'ជូនដំណឹងខ្ញុំអំពី';

  @override
  String get notifySpendingLimits => 'ដែនកំណត់ចំណាយ';

  @override
  String get notifySpendingLimitsDesc => 'ការព្រមាន ពេលដល់ និងពេលលើសដែនកំណត់';

  @override
  String get notifyReminders => 'ការរំលឹក និងវិក្កយបត្រ';

  @override
  String get notifyRemindersDesc => 'ការរំលឹក និងថ្ងៃផុតកំណត់បង់វិក្កយបត្រ';

  @override
  String get notifyTasks => 'កិច្ចការ';

  @override
  String get notifyTasksDesc => 'កិច្ចការដែលបានបើក \"រំលឹកខ្ញុំ\"';

  @override
  String get notifyEvents => 'ព្រឹត្តិការណ៍ប្រតិទិន';

  @override
  String get notifyEventsDesc => 'ព្រឹត្តិការណ៍ដែលមានការរំលឹក';

  @override
  String get notifySavings => 'គោលដៅសន្សំ';

  @override
  String get notifySavingsDesc => 'ការរំលឹកប្រចាំខែ \"ដល់ពេលសន្សំហើយ\"';

  @override
  String get notificationsInAppNote =>
      'ការបិទប្រភេទណាមួយ គ្រាន់តែបញ្ឈប់ការជូនដំណឹងលេចឡើងប៉ុណ្ណោះ។ អ្នកនៅតែឃើញអ្វីៗទាំងអស់នៅក្នុងកម្មវិធី។';

  @override
  String get privacyTitle => 'ព័ត៌មានឯកជនភាព';

  @override
  String get privacyWhatTitle => 'អ្វីដែល LifeMate រក្សាទុក';

  @override
  String get privacyWhatBody =>
      'ឈ្មោះ និងអ៊ីមែលរបស់អ្នក ចំណូលចិត្ត និងទិន្នន័យដែលអ្នកបញ្ចូល៖ ប្រតិបត្តិការ ប្រភេទ ដែនកំណត់ ថវិកា គោលដៅសន្សំ កិច្ចការ ព្រឹត្តិការណ៍ ការរំលឹក និងបញ្ជីទិញឥវ៉ាន់។ LifeMate មិនដែលរក្សាទុកពាក្យសម្ងាត់របស់អ្នកទេ — Firebase Authentication គ្រប់គ្រងវាដោយសុវត្ថិភាព។';

  @override
  String get privacyWhereTitle => 'កន្លែងរក្សាទុក';

  @override
  String get privacyWhereBody =>
      'នៅក្នុង Google Firebase (Cloud Firestore) ដែលត្រូវបានអ៊ិនគ្រីបទាំងពេលបញ្ជូន និងពេលរក្សាទុក។ ច្បាប់ចម្លងមួយត្រូវបានរក្សាទុកនៅលើទូរស័ព្ទនេះ ដើម្បីឱ្យកម្មវិធីដំណើរការពេលគ្មានអ៊ីនធឺណិត។';

  @override
  String get privacyWhoTitle => 'អ្នកណាអាចមើលឃើញ';

  @override
  String get privacyWhoBody =>
      'មានតែអ្នកប៉ុណ្ណោះ។ ច្បាប់សុវត្ថិភាពនៅលើម៉ាស៊ីនមេ អនុញ្ញាតឱ្យគណនីនីមួយៗអាន និងសរសេរតែទិន្នន័យរបស់ខ្លួនប៉ុណ្ណោះ។ LifeMate គ្មានការផ្សាយពាណិជ្ជកម្ម ហើយមិនលក់ ឬចែករំលែកទិន្នន័យរបស់អ្នកទេ។';

  @override
  String get privacyDeviceTitle => 'ការជូនដំណឹង';

  @override
  String get privacyDeviceBody =>
      'ការរំលឹកត្រូវបានកំណត់ពេលនៅលើទូរស័ព្ទនេះ ដោយប្រព័ន្ធម៉ោងរោទ៍របស់ទូរស័ព្ទ។ អត្ថបទរបស់វានៅលើឧបករណ៍ប៉ុណ្ណោះ។';

  @override
  String get privacyExportTitle => 'ទិន្នន័យរបស់អ្នក ច្បាប់ចម្លងរបស់អ្នក';

  @override
  String get privacyExportBody =>
      'អ្នកអាចនាំចេញប្រតិបត្តិការជាឯកសារ CSV ពី ហិរញ្ញវត្ថុ → របាយការណ៍ បានគ្រប់ពេល។';

  @override
  String get privacyDeleteTitle => 'ការលុបទិន្នន័យ';

  @override
  String get privacyDeleteBody =>
      'ការកំណត់ → លុបគណនី នឹងលុបគណនី និងអ្វីៗទាំងអស់ដែលអ្នកបានរក្សាទុកជាអចិន្ត្រៃយ៍។ មិនអាចត្រឡប់វិញបានទេ។';

  @override
  String get deleteTitle => 'លុបគណនី';

  @override
  String get deleteWarning =>
      'សកម្មភាពនេះនឹងលុបគណនី LifeMate និងទិន្នន័យទាំងអស់របស់អ្នកជាអចិន្ត្រៃយ៍។ មិនអាចត្រឡប់វិញបានទេ។';

  @override
  String get deleteWhatIsDeleted =>
      'នឹងលុប៖ ប្រតិបត្តិការ ប្រភេទ ដែនកំណត់ចំណាយ ថវិកា គោលដៅសន្សំ និងប្រវត្តិ កិច្ចការ ព្រឹត្តិការណ៍ប្រតិទិន ការរំលឹក បញ្ជីទិញឥវ៉ាន់ និងប្រវត្តិរូបរបស់អ្នក។';

  @override
  String get deleteExportHint =>
      'ចង់បានច្បាប់ចម្លងជាមុនមែនទេ? នាំចេញប្រតិបត្តិការនៅ ហិរញ្ញវត្ថុ → របាយការណ៍។';

  @override
  String get deletePasswordLabel => 'បញ្ចូលពាក្យសម្ងាត់ដើម្បីបញ្ជាក់';

  @override
  String get deleteButton => 'លុបគណនីរបស់ខ្ញុំ';

  @override
  String get deleteConfirmTitle => 'លុបអ្វីៗទាំងអស់?';

  @override
  String get deleteConfirmBody =>
      'គណនី និងទិន្នន័យទាំងអស់របស់អ្នកនឹងត្រូវលុបជាអចិន្ត្រៃយ៍។';

  @override
  String get deleteInProgress => 'កំពុងលុបទិន្នន័យរបស់អ្នក…';

  @override
  String get deleteDone => 'គណនីរបស់អ្នកត្រូវបានលុប។';
}
