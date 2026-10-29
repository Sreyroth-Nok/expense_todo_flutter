import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../providers/locale_provider.dart';
import '../../routing/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../providers/clock_provider.dart';
import '../../utils/date_utils.dart';
import '../../utils/money.dart';
import '../../services/auth_repository.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_states.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/ui_kit.dart';
import '../../providers/budget_providers.dart';
import '../../widgets/budget_progress_card.dart';
import '../../providers/calendar_providers.dart';
import '../calendar/calendar_tab.dart';
import '../../providers/reminder_providers.dart';
import '../../providers/savings_providers.dart';
import '../../widgets/savings_goal_card.dart';
import '../../models/spending_limit.dart';
import '../../services/spending_limit_calculator.dart';
import '../../providers/spending_limit_providers.dart';
import '../spending_limits/spending_limits_screen.dart';
import '../../widgets/limit_progress_card.dart';
import '../../models/planner_task.dart';
import '../../providers/task_providers.dart';
import '../../widgets/task_tile.dart';
import '../../models/finance_summary.dart';
import '../../models/finance_transaction.dart';
import '../../providers/transaction_providers.dart';
import '../../widgets/transaction_tile.dart';
import '../../providers/dashboard_providers.dart';

/// Remembers whether the user hid amounts on the dashboard (eye button).
class HideAmountsNotifier extends Notifier<bool> {
  static const _key = 'hide_amounts';

  @override
  bool build() => ref.watch(sharedPreferencesProvider).getBool(_key) ?? false;

  void toggle() {
    state = !state;
    ref.read(sharedPreferencesProvider).setBool(_key, state);
  }
}

final hideAmountsProvider =
    NotifierProvider<HideAmountsNotifier, bool>(HideAmountsNotifier.new);

/// Home dashboard: balance card, spending this month, quick actions,
/// today's spending, daily limit, recent transactions, the week ahead,
/// budgets and savings goals.
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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          children: [
            // ── Header ───────────────────────────────────────────
            Row(
              children: [
                const AppLogo(size: 30, horizontal: true),
                const Spacer(),
                IconButton(
                  tooltip: l.plannerReminders,
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () => context.go(AppRoutes.planner),
                ),
                GestureDetector(
                  onTap: () => context.go(AppRoutes.settings),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppColors.softTeal,
                    child: Text(
                      displayName.isEmpty
                          ? '?'
                          : displayName.substring(0, 1).toUpperCase(),
                      style: AppTextStyles.titleMedium
                          .copyWith(color: AppColors.primaryDark),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(14),
            Text(
              l.homeGreeting(displayName.split(' ').first),
              style: AppTextStyles.headlineMedium,
            ),
            Text(
              AppDateUtils.formatDay(DateTime.now()),
              style: AppTextStyles.bodySmall,
            ),
            const Gap(14),
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
    final preferred = ref.watch(currentUserProfileProvider).value?.currency ?? 'USD';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _MonthSelector(),
        const Gap(6),
        _BalanceCard(summary: data.summary, preferredCurrency: preferred)
            .animate()
            .fadeIn(duration: 350.ms)
            .slideY(begin: 0.05),
        const Gap(14),
        _SpendingThisMonth(
          summary: data.summary,
          monthly: statuses[LimitPeriod.monthly],
          preferredCurrency: preferred,
        ),
        const Gap(18),

        // ── Quick actions ──────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: RoundAction(
                icon: Icons.south_west_rounded,
                label: l.quickAddIncome,
                color: AppColors.success,
                onTap: () => context.push(
                    AppRoutes.newTransactionOf(TransactionType.income.name)),
              ),
            ),
            Expanded(
              child: RoundAction(
                icon: Icons.north_east_rounded,
                label: l.quickAddExpense,
                color: AppColors.warning,
                onTap: () => context.push(
                    AppRoutes.newTransactionOf(TransactionType.expense.name)),
              ),
            ),
            Expanded(
              child: RoundAction(
                icon: Icons.add_task_rounded,
                label: l.quickAddTask,
                color: AppColors.primary,
                onTap: () => context.push(AppRoutes.newTask),
              ),
            ),
            Expanded(
              child: RoundAction(
                icon: Icons.shopping_basket_rounded,
                label: l.quickShoppingList,
                color: AppColors.primaryDark,
                onTap: () => context.go(AppRoutes.lists),
              ),
            ),
          ],
        ),
        const Gap(18),

        // ── Today + daily limit ────────────────────────────────────
        _TodayCard(todaySpending: data.todaySpending),
        const Gap(12),
        if (statuses[LimitPeriod.daily] case final daily?)
          LimitProgressCard(
            status: daily,
            onTap: () => context.go(AppRoutes.spendingLimits),
          )
        else
          const SetLimitCard(period: LimitPeriod.daily),
        const Gap(24),

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
          child: Text(AppDateUtils.formatMonth(month.start),
              style: AppTextStyles.titleLarge),
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

/// Deep Teal card: net balance of the month, income and expenses, with an
/// eye button that hides the amounts (privacy in public places).
///
/// Currencies are never mixed: with several currencies, small chips switch
/// between them.
class _BalanceCard extends ConsumerStatefulWidget {
  const _BalanceCard({required this.summary, required this.preferredCurrency});

  final FinanceSummary summary;
  final String preferredCurrency;

  @override
  ConsumerState<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends ConsumerState<_BalanceCard> {
  String? _currency;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final hidden = ref.watch(hideAmountsProvider);
    final currencies = widget.summary.byCurrency.keys.toList();
    final currency = currencies.contains(_currency)
        ? _currency!
        : (currencies.isNotEmpty ? currencies.first : widget.preferredCurrency);
    final totals = widget.summary.byCurrency[currency] ??
        CurrencyTotals(currency: currency);

    String amount(int minor, {bool signed = false}) =>
        hidden ? '••••••' : Money.format(minor, currency, signed: signed);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(70),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Decorative circles.
          Positioned(
            right: -40,
            top: -50,
            child: _Circle(size: 150, color: Colors.white.withAlpha(18)),
          ),
          Positioned(
            right: 40,
            bottom: -60,
            child: _Circle(size: 120, color: AppColors.honey.withAlpha(40)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 12, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      l.homeBalanceThisMonth,
                      style: AppTextStyles.labelLarge
                          .copyWith(color: Colors.white.withAlpha(220)),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: hidden ? l.homeShowAmounts : l.homeHideAmounts,
                      onPressed: ref.read(hideAmountsProvider.notifier).toggle,
                      icon: Icon(
                        hidden
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ],
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    amount(totals.netMinor),
                    style: AppTextStyles.displayLarge.copyWith(
                      color: Colors.white,
                      fontSize: 34,
                    ),
                  ),
                ),
                if (currencies.length > 1) ...[
                  const Gap(8),
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final c in currencies)
                        GestureDetector(
                          onTap: () => setState(() => _currency = c),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                              color: c == currency
                                  ? Colors.white
                                  : Colors.white.withAlpha(40),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              c,
                              style: AppTextStyles.labelSmall.copyWith(
                                color: c == currency
                                    ? AppColors.primaryDark
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                const Gap(16),
                Row(
                  children: [
                    Expanded(
                      child: _CardFigure(
                        icon: Icons.south_west_rounded,
                        iconColor: AppColors.success,
                        label: l.homeIncome,
                        value: amount(totals.incomeMinor),
                      ),
                    ),
                    Expanded(
                      child: _CardFigure(
                        icon: Icons.north_east_rounded,
                        iconColor: AppColors.error,
                        label: l.homeExpenses,
                        value: amount(totals.expenseMinor),
                      ),
                    ),
                  ],
                ),
                if (widget.summary.isEmpty) ...[
                  const Gap(12),
                  Text(
                    l.homeNoTransactionsMonth,
                    style: AppTextStyles.bodySmall
                        .copyWith(color: Colors.white.withAlpha(210)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Circle extends StatelessWidget {
  const _Circle({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class _CardFigure extends StatelessWidget {
  const _CardFigure({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const Gap(8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: AppTextStyles.labelSmall
                      .copyWith(color: Colors.white.withAlpha(210))),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value,
                    style: AppTextStyles.titleMedium
                        .copyWith(color: Colors.white)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// "Spending this month — $1,250 / $2,000 · 62%" against the monthly limit.
class _SpendingThisMonth extends ConsumerWidget {
  const _SpendingThisMonth({
    required this.summary,
    required this.monthly,
    required this.preferredCurrency,
  });

  final FinanceSummary summary;
  final LimitStatus? monthly;
  final String preferredCurrency;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final hidden = ref.watch(hideAmountsProvider);
    final status = monthly;

    if (status == null) {
      final spent =
          summary.byCurrency[preferredCurrency]?.expenseMinor ?? 0;
      return AppCard(
        onTap: () => context.push(AppRoutes.editLimit(LimitPeriod.monthly.name)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.homeSpendingThisMonth,
                      style: AppTextStyles.titleMedium),
                  const Gap(2),
                  Text(l.homeNoMonthlyTarget, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            Text(
              hidden ? '••••' : Money.format(spent, preferredCurrency),
              style: AppTextStyles.titleLarge,
            ),
          ],
        ),
      );
    }

    final percent = (status.progress * 100).round();
    final currency = status.limit.currency;
    return AppCard(
      onTap: () => context.go(AppRoutes.spendingLimits),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.homeSpendingThisMonth, style: AppTextStyles.titleMedium),
          const Gap(10),
          ProgressBar(
            value: status.progress,
            color: status.level.barColor,
            height: 10,
          ),
          const Gap(8),
          Row(
            children: [
              Text(
                hidden
                    ? '•••• / ••••'
                    : '${Money.format(status.spentMinor, currency)} / '
                        '${Money.format(status.limit.amountMinor, currency)}',
                style: AppTextStyles.bodySmall,
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: AppTextStyles.labelLarge.copyWith(
                  color: status.level.color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TodayCard extends ConsumerWidget {
  const _TodayCard({required this.todaySpending});

  final FinanceSummary todaySpending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final hidden = ref.watch(hideAmountsProvider);
    final text = todaySpending.isEmpty
        ? l.homeNoSpendingToday
        : hidden
            ? '••••'
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
            child: Text(l.homeNothingThisWeek, style: AppTextStyles.bodySmall),
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
          Text(l.homeNoActiveBudget, style: AppTextStyles.bodySmall),
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
