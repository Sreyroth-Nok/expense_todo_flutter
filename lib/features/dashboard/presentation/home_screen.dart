import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/clock_provider.dart';
import '../../../core/utils/date_utils.dart';
import '../../../core/utils/money.dart';
import '../../../features/auth/data/auth_repository.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/app_states.dart';
import '../../budgets/domain/budget_providers.dart';
import '../../budgets/presentation/widgets/budget_progress_card.dart';
import '../../calendar/domain/calendar_providers.dart';
import '../../calendar/presentation/calendar_tab.dart';
import '../../reminders/domain/reminder_providers.dart';
import '../../savings/domain/savings_providers.dart';
import '../../savings/presentation/widgets/savings_goal_card.dart';
import '../../spending_limits/domain/spending_limit.dart';
import '../../spending_limits/domain/spending_limit_providers.dart';
import '../../spending_limits/presentation/spending_limits_screen.dart';
import '../../spending_limits/presentation/widgets/limit_progress_card.dart';
import '../../transactions/domain/finance_summary.dart';
import '../../transactions/domain/finance_transaction.dart';
import '../../transactions/domain/transaction_providers.dart';
import '../../tasks/domain/planner_task.dart';
import '../../tasks/domain/task_providers.dart';
import '../../tasks/presentation/widgets/task_tile.dart';
import '../../transactions/presentation/widgets/transaction_tile.dart';
import '../domain/dashboard_providers.dart';
import '../../../core/l10n/l10n.dart';

/// Home dashboard: this month's money summary, today's spending, spending
/// limits, quick actions, recent transactions, the week ahead (tasks,
/// events, bills), budgets and savings goals.
///
/// All numbers come from live Firestore streams for the signed-in user —
/// no sample data is ever shown.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final user = ref.watch(authStateProvider).value;
    final profileName = ref.watch(currentUserProfileProvider).value?.displayName;
    final displayName = (profileName?.isNotEmpty ?? false)
        ? profileName!
        : user?.displayName ?? user?.email ?? '';
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const AppLogo(size: 28, showText: true),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Text(
              l.homeGreeting(displayName.split(' ').first),
              style: AppTextStyles.headlineLarge,
            ),
            const Gap(4),
            Text(
              AppDateUtils.formatDay(DateTime.now()),
              style: AppTextStyles.bodyMedium
                  .copyWith(color: AppColors.textSecondary),
            ),
            const Gap(20),
            const _QuickActions(),
            const Gap(24),
            dashboardAsync.when(
              loading: () => const LoadingState(),
              error: (e, _) => ErrorState(error: e),
              data: (data) => _DashboardBody(data: data),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardBody extends ConsumerWidget {
  const _DashboardBody({required this.data});

  final DashboardData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final statuses = ref.watch(limitStatusesProvider).value ?? const {};
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final categoryById = {for (final c in categories) c.id: c};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Month summary ──────────────────────────────────────────
        const _MonthSelector(),
        const Gap(8),
        _SummaryCard(summary: data.summary),
        const Gap(16),

        // ── Today ──────────────────────────────────────────────────
        _TodayCard(todaySpending: data.todaySpending),
        const Gap(24),

        // ── Spending limits ────────────────────────────────────────
        SectionTitle(
          title: l.homeSpendingLimits,
          actionLabel: l.commonManage,
          onAction: () => context.go(AppRoutes.spendingLimits),
        ),
        const Gap(4),
        for (final period in LimitPeriod.values) ...[
          if (statuses[period] case final status?)
            LimitProgressCard(
              status: status,
              onTap: () => context.go(AppRoutes.spendingLimits),
            )
          else
            SetLimitCard(period: period),
          const Gap(12),
        ],
        const Gap(12),

        // ── Recent transactions ────────────────────────────────────
        SectionTitle(
          title: l.homeRecentTransactions,
          actionLabel: l.commonSeeAll,
          onAction: () => context.go(AppRoutes.transactions),
        ),
        if (data.recent.isEmpty)
          EmptyState(
            icon: Icons.receipt_long_outlined,
            title: l.homeNothingRecorded(
                AppDateUtils.formatMonth(data.month.start)),
            message: l.homeNothingRecordedBody,
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Column(
              children: [
                for (final tx in data.recent)
                  TransactionTile(
                    transaction: tx,
                    category: categoryById[tx.categoryId],
                    showDate: true,
                    onTap: () =>
                        context.push(AppRoutes.transactionDetail(tx.id)),
                  ),
              ],
            ),
          ),
        const Gap(24),
        const _PlannerPreview(),
        const Gap(24),
        const _GoalsPreview(),
      ],
    );
  }
}

class _MonthSelector extends ConsumerWidget {
  const _MonthSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final month = ref.watch(selectedMonthProvider);
    final notifier = ref.read(selectedMonthProvider.notifier);
    final isCurrent = month == AppDateUtils.monthOf(DateTime.now());

    return Row(
      children: [
        Expanded(
          child: Text(
            AppDateUtils.formatMonth(month.start),
            style: AppTextStyles.titleLarge,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: l.homePreviousMonth,
          onPressed: notifier.previous,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: l.homeNextMonth,
          onPressed: isCurrent ? null : notifier.next,
        ),
      ],
    );
  }
}

/// Income, expenses and net for the selected month — one block per currency.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final FinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    if (summary.isEmpty) {
      return AppCard(
        color: AppColors.softTeal,
        borderColor: AppColors.softTeal,
        child: Row(
          children: [
            const Icon(Icons.account_balance_wallet_rounded,
                color: AppColors.primary, size: 32),
            const Gap(12),
            Expanded(
              child: Text(
                l.homeNoTransactionsMonth,
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.primaryDark),
              ),
            ),
          ],
        ),
      );
    }

    final blocks = summary.byCurrency.values.toList();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < blocks.length; i++) ...[
            if (i > 0) ...[const Gap(12), const Divider(), const Gap(12)],
            if (blocks.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppBadge(
                    label: blocks[i].currency, color: AppColors.primary),
              ),
            Row(
              children: [
                Expanded(
                  child: _Figure(
                    label: l.homeIncome,
                    value:
                        Money.format(blocks[i].incomeMinor, blocks[i].currency),
                    color: AppColors.success,
                    icon: Icons.south_west_rounded,
                  ),
                ),
                Expanded(
                  child: _Figure(
                    label: l.homeExpenses,
                    value: Money.format(
                        blocks[i].expenseMinor, blocks[i].currency),
                    color: AppColors.textPrimary,
                    icon: Icons.north_east_rounded,
                  ),
                ),
              ],
            ),
            const Gap(12),
            _Figure(
              label: l.homeNet,
              value: Money.format(blocks[i].netMinor, blocks[i].currency,
                  signed: true),
              color: blocks[i].netMinor >= 0
                  ? AppColors.success
                  : AppColors.error,
              large: true,
            ),
          ],
        ],
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
    this.large = false,
  });

  final String label;
  final String value;
  final Color color;
  final IconData? icon;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: color),
              const Gap(4),
            ],
            Text(label, style: AppTextStyles.labelMedium),
          ],
        ),
        const Gap(4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: (large
                    ? AppTextStyles.headlineLarge
                    : AppTextStyles.headlineSmall)
                .copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _TodayCard extends StatelessWidget {
  const _TodayCard({required this.todaySpending});

  final FinanceSummary todaySpending;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final text = todaySpending.isEmpty
        ? l.homeNoSpendingToday
        : todaySpending.byCurrency.values
            .map((t) => Money.format(t.expenseMinor, t.currency))
            .join('  ·  ');

    return AppCard(
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.honey.withAlpha(40),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.wb_sunny_rounded, color: AppColors.warning),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.homeTodaysSpending, style: AppTextStyles.labelMedium),
                const Gap(2),
                Text(text, style: AppTextStyles.titleLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Row(
      children: [
        _QuickAction(
          icon: Icons.add_card_rounded,
          label: l.quickIncome,
          color: AppColors.success,
          onTap: () => context.push(
              AppRoutes.newTransactionOf(TransactionType.income.name)),
        ),
        _QuickAction(
          icon: Icons.shopping_cart_checkout_rounded,
          label: l.quickExpense,
          color: AppColors.primary,
          onTap: () => context.push(
              AppRoutes.newTransactionOf(TransactionType.expense.name)),
        ),
        _QuickAction(
          icon: Icons.task_alt_rounded,
          label: l.quickTask,
          color: AppColors.warning,
          onTap: () => context.push(AppRoutes.newTask),
        ),
        _QuickAction(
          icon: Icons.checklist_rounded,
          label: l.quickShopping,
          color: AppColors.primaryDark,
          onTap: () => context.go(AppRoutes.lists),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: AppCard(
          padding: const EdgeInsets.symmetric(vertical: 12),
          onTap: onTap,
          child: Column(
            children: [
              Icon(icon, color: color),
              const Gap(6),
              Text(label, style: AppTextStyles.labelMedium),
            ],
          ),
        ),
      ),
    );
  }
}

/// Next tasks, events and bill reminders (7 days ahead, overdue first).
class _PlannerPreview extends ConsumerWidget {
  const _PlannerPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final tasks = ref.watch(tasksProvider).value ?? const [];
    final events =
        ref.watch(eventsInRangeProvider(upcomingRange(now, days: 7))).value ??
            const [];
    final reminders = ref.watch(remindersProvider).value ?? const [];

    final weekEnd = DateTime(now.year, now.month, now.day + 8);
    final nextTasks = [
      ...TaskQueries.overdue(tasks, now),
      ...TaskQueries.dueToday(tasks, now).where((t) => !t.isDone),
      ...TaskQueries.upcoming(tasks, now)
          .where((t) => t.dueAt!.isBefore(weekEnd)),
    ].take(3).toList();
    final nextEvents = (events.where((e) => e.endAt.isAfter(now)).toList()
          ..sort((a, b) => a.startAt.compareTo(b.startAt)))
        .take(3)
        .toList();
    final bills = upcomingReminders(reminders, now, billsOnly: true)
        .where((p) => p.$2.isBefore(weekEnd))
        .take(3)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: l.homeComingUp,
          actionLabel: l.navPlanner,
          onAction: () => context.go(AppRoutes.planner),
        ),
        if (nextTasks.isEmpty && nextEvents.isEmpty && bills.isEmpty)
          AppCard(
            child: Text(
              l.homeNothingThisWeek,
              style: AppTextStyles.bodySmall,
            ),
          )
        else
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Column(
              children: [
                for (final t in nextTasks) TaskTile(task: t),
                for (final e in nextEvents)
                  ListTile(
                    leading: const Icon(Icons.event_rounded,
                        color: AppColors.primary),
                    title: Text(e.title, style: AppTextStyles.titleMedium),
                    subtitle: Text(
                      '${AppDateUtils.relativeDayLabel(e.startAt, now: now)} · ${eventTimeLabel(e)}',
                      style: AppTextStyles.bodySmall,
                    ),
                    onTap: () => context.push(AppRoutes.editEvent(e.id)),
                  ),
                for (final (r, at) in bills)
                  ListTile(
                    leading: Icon(
                      Icons.receipt_long_rounded,
                      color: r.isOverdueAt(now)
                          ? AppColors.error
                          : AppColors.warning,
                    ),
                    title: Text(r.title, style: AppTextStyles.titleMedium),
                    subtitle: Text(
                      '${r.isOverdueAt(now) ? '${l.commonOverdue} · ' : ''}${AppDateUtils.relativeDayLabel(at, now: now)}',
                      style: AppTextStyles.bodySmall.copyWith(
                          color: r.isOverdueAt(now) ? AppColors.error : null),
                    ),
                    trailing: r.amountMinor == null
                        ? null
                        : Text(
                            Money.format(r.amountMinor!, r.currency ?? 'USD'),
                            style: AppTextStyles.labelLarge),
                    onTap: () => context.push(AppRoutes.editReminder(r.id)),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Active budgets and in-progress savings goals (two of each).
class _GoalsPreview extends ConsumerWidget {
  const _GoalsPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final now = ref.watch(clockProvider).value ?? DateTime.now();
    final budgets = (ref.watch(budgetsProvider).value ?? const [])
        .where((b) => b.isActiveAt(now))
        .take(2)
        .toList();
    final goals = (ref.watch(savingsGoalsProvider).value ?? const [])
        .where((g) => !g.isCompleted)
        .take(2)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: l.homeBudgets,
          actionLabel: budgets.isEmpty ? l.commonCreate : l.commonAll,
          onAction: () => budgets.isEmpty
              ? context.push(AppRoutes.newBudget)
              : context.go(AppRoutes.budgets),
        ),
        if (budgets.isEmpty)
          Text(l.homeNoActiveBudget,
              style: AppTextStyles.bodySmall),
        for (final b in budgets) ...[
          BudgetProgressCard(
            budget: b,
            onTap: () => context.push(AppRoutes.budgetDetail(b.id)),
          ),
          const Gap(12),
        ],
        const Gap(12),
        SectionTitle(
          title: l.homeSavingsGoals,
          actionLabel: goals.isEmpty ? l.commonCreate : l.commonAll,
          onAction: () => goals.isEmpty
              ? context.push(AppRoutes.newSavingsGoal)
              : context.go(AppRoutes.savings),
        ),
        if (goals.isEmpty)
          Text(l.homeNoSavingsGoal, style: AppTextStyles.bodySmall),
        for (final g in goals) ...[
          SavingsGoalCard(
            goal: g,
            onTap: () => context.push(AppRoutes.savingsGoalDetail(g.id)),
          ),
          const Gap(12),
        ],
      ],
    );
  }
}
