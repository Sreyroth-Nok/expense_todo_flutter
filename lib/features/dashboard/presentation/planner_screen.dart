import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../calendar/presentation/calendar_tab.dart';
import '../../reminders/presentation/reminders_tab.dart';
import '../../tasks/presentation/tasks_tab.dart';
import '../../../core/l10n/l10n.dart';

/// Planner tab: Tasks, Calendar and Reminders.
class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(l.plannerTitle),
          bottom: TabBar(
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [
              Tab(text: l.plannerTasks),
              Tab(text: l.plannerCalendar),
              Tab(text: l.plannerReminders),
            ],
          ),
        ),
        body: const TabBarView(
          children: [TasksTab(), CalendarTab(), RemindersTab()],
        ),
      ),
    );
  }
}
