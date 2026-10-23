# LifeMate — Phase 1 Implementation Plan

> **✅ STATUS: COMPLETE** — `flutter analyze lib` returns **No issues found** across all 29 Dart files.
> **Next action required**: Firebase Console setup (Steps 1–6 below) → run `flutterfire configure`

## 🏗️ What Phase 1 Built

| Area | Status |
|------|--------|
| Flutter project with correct folder structure | ✅ Done |
| Deep Teal + Honey design system on white | ✅ Done |
| GoRouter with auth-guard redirects | ✅ Done |
| Splash → Onboarding → Login → Register → Forgot Password | ✅ Done |
| Firebase Auth + Firestore wired up | ✅ Done (needs config) |
| User profile Firestore document on register | ✅ Done |
| Persistent login; auto-redirect on app start | ✅ Done |
| Home stub + Settings with logout | ✅ Done |

---

## 🛠️ Required Tools

Before creating the project, install and verify each tool:

```
flutter --version        # must be 3.22+ (Flutter 3.x, Dart 3.x)
dart --version
node --version           # needed for Firebase CLI
npm install -g firebase-tools
firebase --version
```

Also install **FlutterFire CLI**:
```
dart pub global activate flutterfire_cli
flutterfire --version
```

---

## 📦 Dependency List with Rationale

### `pubspec.yaml` dependencies

| Package | Version | Why |
|---------|---------|-----|
| `firebase_core` | ^3.x | Bootstrap Firebase in Flutter |
| `firebase_auth` | ^5.x | Email/password authentication |
| `cloud_firestore` | ^5.x | NoSQL user-scoped database |
| `firebase_app_check` | ^0.3.x | Prevent API abuse |
| `flutter_riverpod` | ^2.x | Reactive state management + DI |
| `riverpod_annotation` | ^2.x | Code-gen annotations for Riverpod |
| `go_router` | ^14.x | Declarative navigation + auth guards |
| `google_fonts` | ^6.x | Inter font (clean modern look) |
| `intl` | ^0.19.x | Date/number formatting, localization |
| `shared_preferences` | ^2.x | Store onboarding-seen flag |
| `flutter_svg` | ^2.x | SVG icons and illustrations |
| `gap` | ^3.x | Clean spacing widgets |
| `form_validator` | ^2.x | Reusable field validators |
| `flutter_animate` | ^4.x | Micro-animations without boilerplate |
| `logger` | ^2.x | Structured debug logging |

### `dev_dependencies`

| Package | Why |
|---------|-----|
| `riverpod_generator` | Code-gen for `@riverpod` annotations |
| `build_runner` | Runs code generation |
| `custom_lint` | Riverpod lint rules |
| `riverpod_lint` | Provider-specific lints |
| `flutter_lints` | Dart/Flutter best-practice lints |
| `firebase_app_check_testing` | Dev bypass for App Check |

---

## 🗂️ Complete Folder Structure

```
lib/
├── main.dart                          # App entry point
├── app.dart                           # MaterialApp.router + theme
│
├── core/
│   ├── theme/
│   │   ├── app_colors.dart            # Color palette constants
│   │   ├── app_text_styles.dart       # Typography scale
│   │   └── app_theme.dart             # ThemeData builder
│   ├── routing/
│   │   ├── app_router.dart            # GoRouter config + guards
│   │   └── app_routes.dart            # Route path constants
│   ├── constants/
│   │   └── app_constants.dart         # Firestore collection names, etc.
│   ├── errors/
│   │   ├── app_exception.dart         # Typed exception hierarchy
│   │   └── firebase_error_mapper.dart # Map FirebaseAuthException codes
│   ├── utils/
│   │   ├── validators.dart            # Email, password validators
│   │   └── date_utils.dart            # Local-time helpers
│   └── services/
│       └── notification_service.dart  # FCM + local notification bootstrap
│
├── shared/
│   ├── widgets/
│   │   ├── app_button.dart            # Primary / secondary / text buttons
│   │   ├── app_text_field.dart        # Themed input field
│   │   ├── app_loading_overlay.dart   # Full-screen loading
│   │   ├── app_snack_bar.dart         # Success / error snack bars
│   │   └── app_logo.dart              # LifeMate logo widget
│   └── models/
│       └── user_profile.dart          # UserProfile Firestore model
│
└── features/
    ├── auth/
    │   ├── data/
    │   │   └── auth_repository.dart   # Firebase Auth operations
    │   ├── domain/
    │   │   └── auth_providers.dart    # Riverpod auth state providers
    │   └── presentation/
    │       ├── splash_screen.dart
    │       ├── onboarding_screen.dart
    │       ├── login_screen.dart
    │       ├── register_screen.dart
    │       └── forgot_password_screen.dart
    │
    ├── dashboard/                     # Phase 2
    ├── transactions/                  # Phase 2
    ├── spending_limits/               # Phase 3
    ├── budgets/                       # Phase 4
    ├── savings/                       # Phase 4
    ├── tasks/                         # Phase 5
    ├── calendar/                      # Phase 5
    ├── reminders/                     # Phase 5
    ├── shopping/                      # Phase 5
    ├── reports/                       # Phase 4
    └── settings/
        └── presentation/
            └── settings_screen.dart   # Stub — logout button (Phase 1)
```

---

## 🔥 Firebase Console Setup Steps

> **Do these steps before running `flutterfire configure`.**

### Step 1 — Create Firebase Project

1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add project**
3. Name: **LifeMate**
4. Disable Google Analytics for now (can enable later)
5. Click **Create project**

### Step 2 — Enable Authentication

1. In your project → **Build → Authentication**
2. Click **Get started**
3. **Sign-in method** tab → Enable **Email/Password**
4. Save

### Step 3 — Create Firestore Database

1. **Build → Firestore Database**
2. Click **Create database**
3. Choose **Start in test mode** (we will add proper rules in Phase 1 code)
4. Select region closest to your users (e.g. `asia-southeast1` for Cambodia)
5. Click **Done**

### Step 4 — Enable App Check (optional in dev)

1. **Build → App Check**
2. Register your Android app with **Play Integrity** (for production)
3. For development: use the debug token provided by the SDK
4. You can skip App Check for initial development — the code already handles the bypass

### Step 5 — Register Apps

1. **Project Settings → Add app**
2. Register **Android app**: use package name `com.lifemate.app`
3. Register **iOS app**: use bundle ID `com.lifemate.app`
4. Download `google-services.json` → place in `android/app/`
5. Download `GoogleService-Info.plist` → place in `ios/Runner/`

### Step 6 — FlutterFire Configure

After placing config files, run inside the project root:
```bash
flutterfire configure --project=YOUR_FIREBASE_PROJECT_ID
```
This generates `lib/firebase_options.dart` automatically.

---

## 🚀 Commands to Create the Project

Run these in order:

```bash
# 1. Create Flutter project
flutter create --org com.lifemate --project-name lifemate .

# 2. Add all dependencies
flutter pub add firebase_core firebase_auth cloud_firestore firebase_app_check
flutter pub add flutter_riverpod riverpod_annotation go_router
flutter pub add google_fonts intl shared_preferences
flutter pub add flutter_svg gap flutter_animate logger

# 3. Add dev dependencies
flutter pub add --dev build_runner riverpod_generator custom_lint riverpod_lint

# 4. Configure FlutterFire (after Firebase Console setup)
flutterfire configure

# 5. Run code generation
dart run build_runner build --delete-conflicting-outputs

# 6. Run on connected device / emulator
flutter run
```

---

## ✅ Phase 1 Test Checklist

After running, verify each point:

- [ ] App launches to Splash screen (2 seconds), then goes to Onboarding
- [ ] Onboarding seen flag is persisted — second launch skips onboarding
- [ ] Register creates a Firebase Auth user and a Firestore `/users/{uid}` document
- [ ] Login with correct credentials navigates to Home (stub screen)
- [ ] Login with wrong password shows a readable error
- [ ] Forgot password sends a reset email (check inbox)
- [ ] Back button from Login cannot reach protected Home screen
- [ ] Logout clears auth state and redirects to Login
- [ ] Deep Teal + Honey colors are visible on all auth screens
- [ ] No hardcoded Firebase values (all from `firebase_options.dart`)

---

## 🔒 Phase 1 Firestore Security Rules

Deploy these rules in Firebase Console → Firestore → Rules:

```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {

    // Users can only access their own document
    match /users/{userId} {
      allow read, write: if request.auth != null
                         && request.auth.uid == userId;

      // Sub-collections inherit ownership check
      match /{collection}/{docId} {
        allow read, write: if request.auth != null
                           && request.auth.uid == userId;

        match /{subCollection}/{subDocId} {
          allow read, write: if request.auth != null
                             && request.auth.uid == userId;
        }
      }
    }

    // Deny everything else
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 📌 Phase 1 Scope Boundaries

| In scope | Out of scope |
|----------|--------------|
| Auth (email/password) | Social sign-in |
| User profile document | Profile photo upload |
| Bottom nav (stubs) | Dashboard data |
| Theme + design system | Dark mode |
| GoRouter + auth guard | Deep links |
| Splash + Onboarding | Animated onboarding |
| Local notification bootstrap | FCM push notifications |

> **Phase 2** will add: Categories, Transactions, Transaction History, Dashboard summary cards.

---
---

# LifeMate — Phases 2 & 3

> **✅ STATUS: COMPLETE** (2026-10-23)
> • `flutter analyze` → **No issues found**
> • `flutter test` → **53 tests pass** (unit, fake-Firestore flow, widget)
> • `cd firestore_tests && npm test` → **19 security-rule tests pass** (emulator)
> • `flutter build apk --debug` → builds

## What was built

| Area | Status |
|------|--------|
| Categories (12 starter categories, add / rename / recolor / delete) | ✅ |
| Add / edit / delete income & expenses, with confirm-before-delete | ✅ |
| Transaction history: search, date presets + custom range, type & category filters | ✅ |
| Transaction details screen | ✅ |
| Home dashboard: month selector, income / expenses / net, today's spending, limits, recent, quick actions | ✅ |
| Finance hub (Budgets / Savings / Reports labelled Phase 4) | ✅ |
| Daily + monthly spending limits, warning threshold (Off/50/75/80/90%) | ✅ |
| Limit alerts: device notification + in-app message, no duplicates | ✅ |
| Firestore rules with field validation + emulator tests | ✅ |

## How money is stored (important)

Every amount is an **integer in minor units** in the field `amountMinorUnits`:
USD `$4.50` → `450`, KHR `12,000៛` → `12000` (KHR uses 0 decimals).
Input text is parsed digit-by-digit (`Money.parseToMinor`), never via `double`,
so no rounding errors. Each transaction keeps its own `currency`; totals are
always **per currency** — different currencies are never added together.

## Spending-limit rules as implemented

- Only **expenses in the limit's currency** count; income never counts.
- Daily = local calendar day `[00:00, next 00:00)`, monthly = `[1st 00:00, next 1st)`.
- Levels: `ok` → `warning` (≥ threshold %) → `reached` (= limit) → `exceeded` (> limit).
- Remaining allowance can be zero or negative ("Over by $1.00").
- Recording an expense is **never blocked**.
- Totals are computed live from Firestore streams — nothing cached that can drift.
- Alerts: one notification each time the level gets *more severe* within a period.
  The last notified level is stored in `notificationEvents/limit_{period}_{periodKey}`.
  If an edit/delete lowers spending, the lower level is stored silently, so
  crossing again later alerts again. A new day/month = new key = fresh state.
- If notification permission is denied, the same alert appears in-app.

## New Firestore documents

| Path | Fields |
|------|--------|
| `users/{uid}/categories/{id}` | name (1–30), type, iconKey, colorValue:int, isDefault, createdAt, updatedAt |
| `users/{uid}/transactions/{id}` | type, amountMinorUnits:int>0, currency, categoryId, categoryName, description (≤200), date:timestamp, createdAt, updatedAt |
| `users/{uid}/spendingLimits/{daily\|monthly}` | period (= doc id), amountMinorUnits, currency, alertsEnabled, warningThresholdPercent (null or 1–99), createdAt, updatedAt |
| `users/{uid}/notificationEvents/{limit_daily_2026-10-23}` | kind, period, periodKey, level, updatedAt |
| `users/{uid}` (added field) | categoriesSeeded:bool |

Index: `transactions (type ASC, date DESC)` — in `firestore.indexes.json`.

## What YOU need to do

1. **Deploy rules and indexes** (replaces the Phase 1 rules shown above):
   ```bash
   firebase login
   firebase use lifemate-34a2b
   firebase deploy --only firestore:rules,firestore:indexes
   ```
   The index takes a few minutes to build. Until then, filtering history by
   Income/Expense shows "A database index is still being created".
2. **iOS only:** `lib/firebase_options.dart` still has a placeholder iOS key.
   Run `flutterfire configure` again after registering the iOS app.
3. Run: `flutter pub get` then `flutter run`.

## How to test Phases 2 & 3

Automated:
```bash
flutter test                         # 53 Dart tests
cd firestore_tests && npm install && npm test   # 19 rule tests (needs Java)
```
> If the rules test says "port taken", a previous emulator is still running —
> close the leftover `java.exe` (Firestore emulator) and retry.

Manual checklist:
- [ ] New account → Categories screen shows 8 expense + 4 income categories
- [ ] Add a $4.00 expense → dashboard Expenses and Today's spending show $4.00
- [ ] Add income → Income and Net update; spending limits unchanged
- [ ] Set daily limit $5, warning 80% → card shows "$1.00 left", **Warning**
- [ ] Add $2.00 expense → "Over by $1.00", red; notification appears (allow permission)
- [ ] Add another expense → **no** second notification (same condition)
- [ ] Edit the $2.00 expense to $0.50 → card returns to Warning/On track
- [ ] Delete an expense (confirm dialog) → totals and limits recalculate
- [ ] Add a KHR expense → separate KHR summary row; not counted in USD limit
- [ ] Deny notification permission → alerts still appear as in-app messages
- [ ] Turn alerts off → no notification, card still shows status (bell-off icon)
- [ ] History: search, date presets, custom range, type and category filters
- [ ] Log out → log in as another user → none of the first user's data visible

## Assumptions & limitations (clearly labelled)

- **Time zone:** "local day/month" uses the **device** time zone. The profile
  `timeZone` setting becomes configurable in Phase 6 (needs the `timezone` package).
  All period logic takes an explicit `DateTime`, so switching is a small change.
- **Alerts are checked on this device** right after a save. An expense added
  from a *different* device is evaluated the next time this device saves
  something. A Cloud Function trigger (planned for Phase 6) would make it fully
  server-side; the `notificationEvents` format already supports that.
- "All time" history shows the latest 500 transactions (a note is displayed).
- Budget, savings, tasks, bills and calendar cards on the dashboard are labelled
  "Phase 4/5" — not implemented yet.
- Account deletion still does not remove sub-collections (Phase 1 note; needs a
  Cloud Function).

## New dependencies

| Package | Why |
|---------|-----|
| `flutter_local_notifications` | On-device spending-limit notifications (requires core-library desugaring, enabled in `android/app/build.gradle.kts`, and `POST_NOTIFICATIONS` in the manifest) |
| `fake_cloud_firestore` (dev) | In-memory Firestore so add/edit/delete → limit tests run without a network |

> **Phase 4** next: Budgets, Savings goals, Financial reports.

---
---

# LifeMate — Phases 4 & 5

> **✅ STATUS: COMPLETE** (2026-10-23)
> • `flutter analyze` → **No issues found**
> • `flutter test` → **107 tests pass** (was 53)
> • `cd firestore_tests && npm test` → **36 security-rule tests pass** (was 19)
> • `flutter build apk --debug` → builds

## What was built

| Phase | Feature | Where |
|-------|---------|-------|
| 4 | Budgets: period, total, per-category amounts, warning %, Active/Upcoming/Past | Finance → Budgets |
| 4 | Savings goals: target, date, deposits/withdrawals history, mark completed, monthly reminder | Finance → Savings goals |
| 4 | Reports: income/expense/net, by category, daily chart, monthly, budgets, savings, CSV export | Finance → Reports |
| 5 | Tasks: due date/time, priority, status, Today/Upcoming/All, filter, sort, reminder | Planner → Tasks |
| 5 | Calendar: month grid with dots, day agenda, events (all-day, multi-day, location, reminder) | Planner → Calendar |
| 5 | Reminders & bill reminders: repeat daily/weekly/monthly, mark paid/done, dismiss, overdue | Planner → Reminders |
| 5 | Shopping lists: create/rename/delete, quick add, quantity + unit, check off, clear purchased | Lists tab |
| — | Dashboard: week ahead (tasks, events, bills), budgets, savings; Task/Shopping quick actions | Home |

## Design decisions (and why)

- **Budget allocations are a map inside the budget document**
  (`allocations: { food: 20000 }`) instead of an `allocations/` sub-collection.
  They are few, always read with the budget, and one document = one atomic save.
- **Budget spending is calculated live** from the budget range's expenses —
  nothing stored, so it is always right after edits/deletes. Duplicate
  transaction ids are ignored, so an expense can never be counted twice.
- **Savings: the saved amount only changes together with a contribution**, in a
  Firestore transaction (`savingsGoals/{id}/contributions/{id}`). History and
  total always agree, and you cannot withdraw more than is saved. Income is
  never treated as savings automatically.
- **Reports** download only the chosen range's transactions and group them in
  the app (Firestore aggregation cannot group by currency + category + day).
  CSV amounts are exact decimals; text cells are protected against spreadsheet
  formula injection; the file starts with a BOM so Khmer text opens correctly in Excel.
- **Shopping item counts are counted live**, not stored, so they cannot drift.
- **Calendar events are limited to 31 days** so the month view can find events
  that started earlier with one simple, indexed query.

## How reminders / notifications work

- Reminders, bills, task reminders, event reminders and savings reminders are
  scheduled with the phone's **alarm system** (`flutter_local_notifications` +
  `timezone`). They fire **even when LifeMate is closed** and survive a reboot.
- While you are signed in, the app keeps the phone's schedule in sync with
  Firestore (`notification_sync.dart`): change something on another device and
  this phone reschedules the next time the app is open. Signing out cancels them.
- Repeating reminders use the OS repeat feature, so they keep firing even if the
  app is not opened for weeks.
- Permission is asked the first time you save something with a reminder. If you
  deny it, everything still shows inside the app (overdue in red, dashboard).

**Limitations (clearly labelled):**
- iOS allows ~64 pending notifications; LifeMate schedules the **nearest 50**.
- Without "Alarms & reminders" permission (Android 12+), Android may deliver a
  few minutes late. Exact timing is used automatically when allowed
  (Settings → Apps → LifeMate → Alarms & reminders).
- A device that never opens the app after a change made elsewhere keeps its old
  schedule. **Not implemented:** server-sent push (FCM + a scheduled Cloud
  Function). That needs the Blaze (pay-as-you-go) plan; planned for Phase 6.
- Monthly repeats on the 29th–31st are skipped by the OS in shorter months.
- Budget warnings are shown in the app (badges/colors); they do not send push
  notifications (spending limits do).

## New Firestore documents (all under `users/{uid}/`)

| Path | Key fields |
|------|------------|
| `budgets/{id}` | name, startDate, endDate (last day), currency, totalAmountMinorUnits, allocations map, warningThresholdPercent |
| `savingsGoals/{id}` | name, currency (fixed), targetAmountMinorUnits, savedAmountMinorUnits ≥ 0, targetDate?, isCompleted, reminderDayOfMonth? (1–28) |
| `savingsGoals/{id}/contributions/{id}` | amountMinorUnits (≠ 0, negative = withdrawal), note, date — immutable |
| `tasks/{id}` | title, notes, dueAt?, hasDueTime, priority, status, reminderEnabled, completedAt? |
| `calendarEvents/{id}` | title, startAt, endAt (exclusive, ≤ 31 days), allDay, location, notes, reminderMinutesBefore? |
| `reminders/{id}` | title, notes, kind (general/bill), remindAt, repeat, amountMinorUnits?, currency?, status |
| `shoppingLists/{id}` | name |
| `shoppingLists/{id}/items/{id}` | name, quantity (1–9999), unit, isPurchased — parent list must exist |

All new queries use single-field indexes (created automatically). No new
composite index was needed.

## What YOU need to do

1. **Deploy the updated rules** (Phase 4–5 collections are denied until you do):
   ```bash
   firebase deploy --only firestore:rules,firestore:indexes
   ```
2. `flutter pub get` (new packages) → `flutter run`.
3. Optional (Android 12+): allow **Alarms & reminders** for exact reminder times.

## How to test Phases 4 & 5

Automated:
```bash
flutter test                                    # 107 tests
cd firestore_tests && npm install && npm test   # 36 rule tests
```
> On Windows the Firestore emulator sometimes keeps running after `npm test`.
> If the next run says "port taken", close the leftover `java.exe`.

Manual checklist:
- [ ] Budget for this month, $500 total, Food $200 → add $160 food expense → Food shows **Warning**, total 32%
- [ ] Add a transport expense with no allocation → appears under "Other categories"
- [ ] Budget end date before start → error, not saved
- [ ] Savings goal $800 with $100 already saved → history shows "Starting amount"
- [ ] Withdraw more than saved → error; delete a deposit → saved amount goes down
- [ ] Reports → change range → numbers update; Export → share sheet with a .csv file
- [ ] Task due today 2 minutes from now with "Remind me" → close the app → notification arrives
- [ ] Mark a task done → strikethrough; Today view shows overdue tasks in red
- [ ] Calendar: event 3 days long → dot on each day; event with 15-min reminder fires
- [ ] Bill reminder monthly on the 5th, $25 → "Mark as paid" moves it to next month
- [ ] Deny notifications → reminders still visible, overdue shown in red
- [ ] Shopping: quick add "Rice", set 2 kg, check off, "Remove purchased items", delete list
- [ ] Home shows week ahead, active budgets and savings goals
- [ ] Second account cannot see any of the first account's lists, tasks or goals

## New dependencies

| Package | Why |
|---------|-----|
| `timezone` | Schedules notifications at a local wall-clock time (needed by `zonedSchedule`) |
| `flutter_timezone` | Reads the phone's time-zone name (e.g. Asia/Phnom_Penh) |
| `share_plus` | Opens the system share sheet for the CSV export |
| `path_provider` | Temporary folder for the CSV file |

Android manifest: added `RECEIVE_BOOT_COMPLETED`, `SCHEDULE_EXACT_ALARM` and the
two notification receivers (restore reminders after reboot).

> **Phase 6** next: English/Khmer localization, settings (currency, time zone,
> notification preferences, profile, change password, delete account with data
> cleanup), security review, App Check, performance, release builds.


---
---

# LifeMate — Phase 6 (Localization, Settings, Security, Release)

> **✅ STATUS: COMPLETE** (2026-10-23)
> • `flutter analyze` → **No issues found**
> • `flutter test` → **121 tests pass**
> • `cd firestore_tests && npm test` → **43 security-rule tests pass**
> • `flutter build apk --release --obfuscate --split-debug-info=build/symbols` → builds

## 1. English / Khmer

- Flutter's official localization system (`flutter_localizations` + `gen-l10n`).
  Translations: `lib/l10n/app_en.arb` (template) and `lib/l10n/app_km.arb`.
  The Dart classes in `lib/l10n/app_localizations*.dart` are **generated** —
  edit the `.arb` files, then run `flutter gen-l10n` (or just `flutter run`).
- Use in widgets: `context.l10n.navHome`. In code without a context
  (validators, error messages): `currentL10n`.
- Language choice: Settings → Language. It is saved on the phone **and** in the
  profile, so it follows you to other devices. First launch uses the phone's
  language (Khmer phones start in Khmer).
- Khmer text uses **Noto Sans Khmer** automatically (Inter has no Khmer letters).
- Dates follow the selected language (`Intl.defaultLocale`). Money amounts keep
  Latin digits in both languages for clarity.
- A test checks that every English key has a Khmer translation with the same
  `{placeholders}`, and that nothing was left untranslated by accident.

**Translated now:** bottom navigation, onboarding, login, register, forgot
password, all Settings screens, Home dashboard, Finance hub, Planner tabs,
shopping lists title, shared error / empty / confirm widgets, every form
validator and every login / registration error message.

**⚠️ Not translated yet (still English):** the inner feature screens —
transactions, categories, spending limits, budgets, savings, reports, tasks,
calendar, reminders, shopping list items — and notification texts. The pattern
is in place: move each string into both `.arb` files and replace it with
`context.l10n.yourKey`. **Have a native Khmer speaker review `app_km.arb`**
before publishing.

## 2. Settings (all working)

| Setting | What it does |
|---------|--------------|
| Edit profile | Display name (Firestore + Firebase Auth). Email is shown read-only. Photos are not in the MVP (no Firebase Storage). |
| Change password | Re-authenticates with the current password, validates the new one (different from current, rules, confirmation). |
| Language | English / ខ្មែរ, instant switch, synced to profile. |
| Default currency | Default for new transactions, limits, budgets, goals. Existing records keep their currency; nothing is converted. |
| Time zone | Shows the phone's zone and saves it to the profile automatically. **Design decision:** LifeMate uses the phone's zone for day / month boundaries (to change it, use the phone's Date & time settings). A separate in-app override would require converting every date in the app and is error-prone. |
| Notifications | Permission status + "Allow" button, Android exact-alarm access, and on/off switches for: spending limits, reminders & bills, tasks, events, savings. Off = no pop-ups; still visible in the app. |
| Privacy information | Plain-language explanation (EN / KM). |
| Delete account | Password re-check → confirmation → deletes **all** data (every collection and sub-collection) → deletes the Auth account. |
| Log out | Cancels this phone's scheduled reminders, then signs out. |

## 3. Security review — findings and fixes

| # | Area | Finding | Status |
|---|------|---------|--------|
| 1 | Account deletion | Phase 1 deleted only the profile document; sub-collections stayed in Firestore forever. | **Fixed** — `AccountDataService` deletes all 10 collections + nested ones; a test guards against forgetting new collections. |
| 2 | Profile rules | A user could store any `email`, `locale`, or junk in preferences. | **Fixed** — email must equal the Auth token email and is immutable; locale must be en or km; preferences map validated; time zone length-limited. |
| 3 | App Check | Dependency existed but was never activated. | **Fixed** — activated in `main.dart` (Play Integrity / App Attest in release, debug provider in debug). Enforcement is a console switch (see below). |
| 4 | Logout on shared phones | Scheduled reminders stayed on the phone after logout. | **Fixed** — logout and delete cancel them. |
| 5 | Android backup | `allowBackup` (default true) copied the app's local data, including the Firestore cache with financial records, into device backups. | **Fixed** — backups disabled. |
| 6 | Secrets | No service-account keys or private secrets in the app. `firebase_options.dart` / `google-services.json` contain public identifiers only (safe; protected by rules + App Check). Signing keys are git-ignored. | **OK** |
| 7 | Passwords | Never stored in Firestore; sensitive actions (change password, delete account) re-authenticate first. | **OK** |
| 8 | Authorization | Every path has explicit rules; anything not listed is denied; hiding buttons is never relied on. 43 emulator tests. | **OK** |
| 9 | Input validation | Validated in the app **and** in rules (types, ranges, allowed keys, immutable fields). | **OK** |
| 10 | CSV export | Formula-injection protection (cells starting with = + - @ are prefixed). | **OK** |
| 11 | Logging | `logger` only prints in debug builds; no personal data is logged. | **OK** |
| 12 | Server-side alerts | Limit alerts and reminders are evaluated on the device. | **Open (by design)** — needs Cloud Functions on the Blaze plan. |
| 13 | Savings total vs history | Rules cannot verify that `savedAmountMinorUnits` equals the sum of contributions (rules cannot add up documents). The app always writes both in one transaction. | **Accepted risk** — only the owner can write their own data. |

## 4. Performance notes

- Every list query is bounded: date ranges are filtered **on the server**,
  "all time" is capped at 500, tasks 500, reminders 300, items 300.
- Totals (dashboard, limits, budgets, reports) are calculated from data already
  on the phone — no extra reads or writes for counters.
- Detail / per-item providers are `autoDispose`, so Firestore listeners close
  when a screen is left; identical queries share one listener (value-equal keys).
- The Firestore offline cache is on by default: the app opens fast and works
  offline; changes sync later.
- Release builds are obfuscated and shrunk (R8); fonts are fetched once and cached.

## 5. What YOU need to do

### a) Deploy the updated rules
```bash
firebase deploy --only firestore:rules,firestore:indexes
```

### b) App Check (recommended before release)
1. Firebase Console → **App Check** → Apps → Android → **Play Integrity** →
   add your app's **SHA-256** (Play Console → App integrity → App signing).
2. For debug builds: run the app once, copy the debug secret printed in the
   log ("Enter this debug secret into the allow list ..."), and add it in
   App Check → Apps → ⋮ → **Manage debug tokens**.
3. Watch App Check → APIs → Cloud Firestore metrics for a few days, then press
   **Enforce**. Do not enforce before steps 1–2, or real users get blocked.

### c) Android release
```bash
# 1. Create an upload key once (keep the .jks file and passwords safe!)
keytool -genkey -v -keystore C:\Users\<you>\lifemate-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# 2. Create android/key.properties (git-ignored) with:
#    storePassword=...
#    keyPassword=...
#    keyAlias=upload
#    storeFile=C:/Users/<you>/lifemate-upload.jks

# 3. Bump the version in pubspec.yaml (version: 1.0.0+1 = name + build number)

# 4. Build the bundle for Google Play
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols
#    → build/app/outputs/bundle/release/app-release.aab
#    Keep build/symbols/ privately: it is needed to read crash stack traces.
```
Add the **SHA-1 and SHA-256** of the upload key and of Play's app-signing key
in Firebase → Project settings → Android app.

### d) iOS release (needs a Mac with Xcode)
1. Register the iOS app in Firebase, then run `flutterfire configure` (this
   replaces the placeholder iOS values in `lib/firebase_options.dart`).
2. Open `ios/Runner.xcworkspace` → Signing & Capabilities → choose your team.
3. App Check: add the **App Attest** capability.
4. `flutter build ipa --release --obfuscate --split-debug-info=build/symbols`
   → upload with Xcode or Transporter.

### e) Store listing
Google Play and the App Store require a **public privacy-policy URL** and a
data-safety / privacy-label form. The in-app Privacy screen lists what is
collected (name, email, financial and planner data; no ads, no tracking, no
sharing) — use it as the basis.

## How to test Phase 6

```bash
flutter test                                    # 121 tests
cd firestore_tests && npm install && npm test   # 43 rule tests
```
Manual checklist:
- [ ] Settings → Language → ខ្មែរ: navigation, Home, Settings switch to Khmer instantly
- [ ] Log out → login screen is still in Khmer; log in on a second device → Khmer too
- [ ] Register a new account with the phone set to Khmer → profile `locale` is `km`
- [ ] Edit profile name → Home greeting updates
- [ ] Change password with the wrong current password → readable error; correct → success; log in with the new password
- [ ] Default currency → KHR → the new transaction form starts with KHR
- [ ] Notifications → turn "Tasks" off → task reminders no longer pop up; on → they return
- [ ] Notifications screen shows "not allowed" after denying; "Allow" asks again
- [ ] Delete account with a wrong password → nothing deleted; correct → logged out, Firestore Console shows no `users/{uid}` data
- [ ] `flutter build apk --release` → `flutter install --release` → app runs

> **Next steps (post-MVP):** translate the remaining feature screens, a
> scheduled Cloud Function + FCM for server-side reminders (Blaze plan),
> dark theme (the theme is already token-based), and Crashlytics.
