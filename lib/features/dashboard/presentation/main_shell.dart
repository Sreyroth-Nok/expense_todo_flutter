import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/services/time_zone_service.dart';
import '../../reminders/domain/notification_sync.dart';
import '../../../core/l10n/l10n.dart';

/// The persistent bottom navigation shell displayed after login.
///
/// This shell wraps all five main destinations:
///   0 - Home (Dashboard)
///   1 - Finance
///   2 - Planner
///   3 - Lists
///   4 - Settings
///
/// Each tab is a separate branch in GoRouter's [StatefulShellRoute] so
/// each branch keeps its own navigation stack when you switch tabs.
class MainShell extends ConsumerWidget {
  const MainShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    // Keeps scheduled reminder notifications in sync with Firestore for as
    // long as the signed-in shell is on screen.
    ref.watch(notificationSyncProvider);
    // Saves the phone's time zone to the profile when it changes.
    ref.watch(timeZoneSyncProvider);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          border: const Border(
            top: BorderSide(color: AppColors.border, width: 1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 12,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          items: [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: l.navHome,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet_outlined),
              activeIcon: Icon(Icons.account_balance_wallet_rounded),
              label: l.navFinance,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today_outlined),
              activeIcon: Icon(Icons.calendar_today_rounded),
              label: l.navPlanner,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.checklist_outlined),
              activeIcon: Icon(Icons.checklist_rounded),
              label: l.navLists,
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings_rounded),
              label: l.navSettings,
            ),
          ],
        ),
      ),
    );
  }
}
