import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../routing/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/date_utils.dart';
import '../../utils/money.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/date_range_filter.dart';
import '../../widgets/app_button.dart';
import '../../widgets/progress_bar.dart';
import '../../widgets/ui_kit.dart';
import '../../services/auth_repository.dart';
import '../../providers/budget_providers.dart';
import '../../widgets/budget_progress_card.dart';
import '../../providers/savings_providers.dart';
import '../../widgets/savings_goal_card.dart';
import '../../models/transaction_filter.dart';
import '../../providers/transaction_providers.dart';
import '../../widgets/transaction_tile.dart';
import '../../services/report_export_service.dart';
import '../../models/finance_report.dart';

/// Financial reports for a chosen date range, with CSV export.
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  RangeSelection _selection = RangeSelection(
    RangePreset.thisMonth,
    AppDateUtils.monthOf(DateTime.now()),
  );
  bool _exporting = false;

  DateRange get _range => _selection.range!;

  Future<void> _choosePreset(RangePreset preset) async {
    if (preset != RangePreset.custom) {
      setState(() =>
          _selection = RangeSelection(preset, preset.rangeAt(DateTime.now())));
      return;
    }
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: DateTimeRange(
        start: _range.start,
        end: _range.end.subtract(const Duration(days: 1)),
      ),
    );
    if (picked == null) return;
    setState(() => _selection = RangeSelection(
          RangePreset.custom,
          DateRange(AppDateUtils.dayOf(picked.start).start,
              AppDateUtils.dayOf(picked.end).end),
        ));
  }

  Future<void> _export(FinanceReport report) async {
    final box = context.findRenderObject() as RenderBox?;
    setState(() => _exporting = true);
    try {
      await ref.read(reportExportServiceProvider).shareTransactionsCsv(
            report.transactions,
            report.range,
            sharePositionOrigin:
                box == null ? null : box.localToGlobal(Offset.zero) & box.size,
          );
    } catch (e) {
      if (mounted) AppSnackBar.error(context, readableError(e));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final txAsync =
        ref.watch(transactionQueryProvider(TransactionFilter(range: _range)));
    final preferred = ref.watch(currentUserProfileProvider).value?.currency;
    final report = txAsync.whenData(
        (txs) => FinanceReport.build(_range, txs, preferredCurrency: preferred));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Financial Report')),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: AppPrimaryButton(
          label: 'Export Report (CSV)',
          icon: Icons.ios_share_rounded,
          isLoading: _exporting,
          onPressed: report.value == null || report.value!.isEmpty
              ? null
              : () => _export(report.value!),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          PillTabs<RangePreset>(
            options: const [
              RangePreset.thisMonth,
              RangePreset.thisYear,
              RangePreset.custom,
            ],
            selected: _selection.preset,
            labelOf: (p) => switch (p) {
              RangePreset.thisMonth => 'Monthly',
              RangePreset.thisYear => 'Yearly',
              _ => 'Custom',
            },
            onSelected: _choosePreset,
          ),
          const Gap(12),
          Row(
            children: [
              Text(
                '${AppDateUtils.formatShortDay(_range.start)} – '
                '${AppDateUtils.formatShortDay(_range.end.subtract(const Duration(days: 1)))} '
                '${_range.start.year}',
                style: AppTextStyles.titleMedium,
              ),
            ],
          ),
          const Gap(12),
          report.when(
            loading: () => const LoadingState(),
            error: (e, _) => ErrorState(error: e),
            data: (r) => _ReportBody(report: r),
          ),
          const Gap(24),
          const _BudgetsSection(),
          const Gap(24),
          const _SavingsSection(),
        ],
      ),
    );
  }
}

class _ReportBody extends ConsumerWidget {
  const _ReportBody({required this.report});

  final FinanceReport report;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (report.isEmpty) {
      return const EmptyState(
        icon: Icons.insert_chart_outlined_rounded,
        title: 'No transactions in this period',
        message: 'Pick another date range, or record some transactions.',
      );
    }
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final byId = {for (final c in categories) c.id: c};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Income & expense summary ─────────────────────────────
        const SectionTitle(title: 'Income & expenses'),
        AppCard(
          child: Column(
            children: [
              for (final t in report.summary.byCurrency.values)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 44,
                        child: Text(t.currency,
                            style: AppTextStyles.labelMedium),
                      ),
                      Expanded(
                        child: _Stat('Income',
                            Money.format(t.incomeMinor, t.currency),
                            AppColors.success),
                      ),
                      Expanded(
                        child: _Stat('Expenses',
                            Money.format(t.expenseMinor, t.currency),
                            AppColors.textPrimary),
                      ),
                      Expanded(
                        child: _Stat(
                          'Net',
                          Money.format(t.netMinor, t.currency, signed: true),
                          t.netMinor >= 0 ? AppColors.success : AppColors.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const Gap(24),

        // ── Spending by category ─────────────────────────────────
        const SectionTitle(title: 'Spending by category'),
        for (final entry in report.expensesByCategory.entries) ...[
          AppCard(
            child: _CategoryDonut(
              currency: entry.key,
              totals: entry.value,
              colorOf: (id) => byId[id] == null
                  ? null
                  : Color(byId[id]!.colorValue),
              nameOf: (c) => byId[c.categoryId]?.name ?? c.categoryName,
              showCurrency: report.expensesByCategory.length > 1,
            ),
          ),
          const Gap(12),
        ],
        if (report.expensesByCategory.isEmpty)
          Text('No expenses in this period.', style: AppTextStyles.bodySmall),
        const Gap(12),

        // ── Daily spending ───────────────────────────────────────
        if (report.dailyExpenses.isNotEmpty) ...[
          const SectionTitle(title: 'Daily spending'),
          for (final entry in report.dailyExpenses.entries) ...[
            AppCard(child: _DailyChart(currency: entry.key, days: entry.value)),
            const Gap(12),
          ],
          const Gap(12),
        ],

        // ── Monthly spending ─────────────────────────────────────
        const SectionTitle(title: 'Monthly spending'),
        for (final entry in report.monthlyExpenses.entries) ...[
          AppCard(
            child: Column(
              children: [
                for (final m in entry.value)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(DateFormat('MMM yyyy').format(m.start),
                              style: AppTextStyles.bodySmall),
                        ),
                        Expanded(
                          child: ProgressBar(
                            value: _maxOf(entry.value) == 0
                                ? 0
                                : m.amountMinor / _maxOf(entry.value),
                            color: AppColors.honey,
                          ),
                        ),
                        const Gap(10),
                        Text(Money.format(m.amountMinor, entry.key),
                            style: AppTextStyles.labelLarge),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Gap(12),
        ],
        const Gap(12),

        // ── Transaction history ──────────────────────────────────
        SectionTitle(
          title: 'Transactions (${report.transactions.length})',
          actionLabel: 'History',
          onAction: () => context.go(AppRoutes.transactions),
        ),
        AppCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            children: [
              for (final tx in report.transactions.take(20))
                TransactionTile(
                  transaction: tx,
                  category: byId[tx.categoryId],
                  showDate: true,
                  onTap: () => context.push(AppRoutes.transactionDetail(tx.id)),
                ),
              if (report.transactions.length > 20)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Showing 20 of ${report.transactions.length}. Export CSV to get all of them.',
                    style: AppTextStyles.bodySmall,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  static int _maxOf(List<PeriodTotal> list) =>
      list.fold(0, (m, p) => p.amountMinor > m ? p.amountMinor : m);
}

/// Donut chart of expenses by category with a legend (largest first).
/// Categories after the 5th are grouped as "Others".
class _CategoryDonut extends StatelessWidget {
  const _CategoryDonut({
    required this.currency,
    required this.totals,
    required this.colorOf,
    required this.nameOf,
    required this.showCurrency,
  });

  final String currency;
  final List<CategoryTotal> totals;
  final Color? Function(String categoryId) colorOf;
  final String Function(CategoryTotal) nameOf;
  final bool showCurrency;

  static const _fallback = [
    AppColors.primary,
    AppColors.honey,
    Color(0xFFDB2777),
    Color(0xFF2563EB),
    Color(0xFF7C3AED),
  ];

  @override
  Widget build(BuildContext context) {
    final total = totals.fold(0, (s, c) => s + c.amountMinor);
    final top = totals.take(5).toList();
    final othersAmount =
        totals.skip(5).fold(0, (s, c) => s + c.amountMinor);

    final rows = <(String, int, Color)>[
      for (var i = 0; i < top.length; i++)
        (
          nameOf(top[i]),
          top[i].amountMinor,
          colorOf(top[i].categoryId) ?? _fallback[i % _fallback.length],
        ),
      if (othersAmount > 0) ('Others', othersAmount, AppColors.textSecondary),
    ];

    return Column(
      children: [
        if (showCurrency)
          Align(
            alignment: Alignment.centerLeft,
            child: AppBadge(label: currency, color: AppColors.primary),
          ),
        const Gap(8),
        DonutChart(
          size: 190,
          thickness: 28,
          slices: [
            for (final r in rows) DonutSlice(r.$2.toDouble(), r.$3),
          ],
          center: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Expenses',
                  style: AppTextStyles.labelSmall, textAlign: TextAlign.center),
              const Gap(2),
              FittedBox(
                child: Text(Money.format(total, currency),
                    style: AppTextStyles.headlineSmall),
              ),
            ],
          ),
        ),
        const Gap(18),
        for (final (name, amount, color) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                ),
                const Gap(10),
                Expanded(
                  child: Text(name,
                      style: AppTextStyles.bodyMedium,
                      overflow: TextOverflow.ellipsis),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    total == 0 ? '0%' : '${(amount * 100 / total).round()}%',
                    style: AppTextStyles.bodySmall,
                    textAlign: TextAlign.end,
                  ),
                ),
                const Gap(12),
                Text(Money.format(amount, currency),
                    style: AppTextStyles.labelLarge),
              ],
            ),
          ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, this.color);

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelSmall),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value,
              style: AppTextStyles.titleMedium.copyWith(color: color)),
        ),
      ],
    );
  }
}

/// Simple bar chart: one bar per day, highest day = full height.
class _DailyChart extends StatelessWidget {
  const _DailyChart({required this.currency, required this.days});

  final String currency;
  final List<PeriodTotal> days;

  @override
  Widget build(BuildContext context) {
    final max = days.fold(0, (m, d) => d.amountMinor > m ? d.amountMinor : m);
    final total = days.fold(0, (s, d) => s + d.amountMinor);
    final average = days.isEmpty ? 0 : total ~/ days.length;
    final peak = days.firstWhere((d) => d.amountMinor == max,
        orElse: () => days.first);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 110,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              for (final d in days)
                Expanded(
                  child: Tooltip(
                    message:
                        '${AppDateUtils.formatShortDay(d.start)}: ${Money.format(d.amountMinor, currency)}',
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 1),
                      height: max == 0 ? 2 : 2 + 108 * d.amountMinor / max,
                      decoration: BoxDecoration(
                        color: d.amountMinor == max && max > 0
                            ? AppColors.honey
                            : AppColors.primary.withAlpha(170),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const Gap(6),
        Row(
          children: [
            Text(AppDateUtils.formatShortDay(days.first.start),
                style: AppTextStyles.caption),
            const Spacer(),
            Text(AppDateUtils.formatShortDay(days.last.start),
                style: AppTextStyles.caption),
          ],
        ),
        const Gap(10),
        Text(
          'Average ${Money.format(average, currency)}/day · '
          'Highest ${Money.format(max, currency)} on ${AppDateUtils.formatShortDay(peak.start)}',
          style: AppTextStyles.bodySmall,
        ),
      ],
    );
  }
}

class _BudgetsSection extends ConsumerWidget {
  const _BudgetsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetsProvider).value ?? const [];
    final now = DateTime.now();
    final relevant = budgets.where((b) => !b.isPastAt(now)).take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Budget progress',
          actionLabel: 'All budgets',
          onAction: () => context.go(AppRoutes.budgets),
        ),
        if (relevant.isEmpty)
          Text('No active or upcoming budgets.', style: AppTextStyles.bodySmall),
        for (final b in relevant) ...[
          BudgetProgressCard(
            budget: b,
            onTap: () => context.push(AppRoutes.budgetDetail(b.id)),
          ),
          const Gap(12),
        ],
      ],
    );
  }
}

class _SavingsSection extends ConsumerWidget {
  const _SavingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(savingsGoalsProvider).value ?? const [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionTitle(
          title: 'Savings progress',
          actionLabel: 'All goals',
          onAction: () => context.go(AppRoutes.savings),
        ),
        if (goals.isEmpty)
          Text('No savings goals yet.', style: AppTextStyles.bodySmall),
        for (final g in goals.take(5)) ...[
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
