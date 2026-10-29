import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../routing/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/date_utils.dart';
import '../../utils/money.dart';
import '../../widgets/app_card.dart';
import '../../widgets/app_states.dart';
import '../../widgets/date_range_filter.dart';
import '../../widgets/ui_kit.dart';
import '../../services/transaction_repository.dart';
import '../../models/finance_summary.dart';
import '../../models/finance_transaction.dart';
import '../../models/transaction_category.dart';
import '../../models/transaction_filter.dart';
import '../../providers/transaction_providers.dart';
import '../../widgets/transaction_tile.dart';

/// Transaction history with search and filters.
class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  late TransactionFilter _filter =
      TransactionFilter(range: AppDateUtils.monthOf(DateTime.now()));
  RangeSelection _selection = RangeSelection(
    RangePreset.thisMonth,
    AppDateUtils.monthOf(DateTime.now()),
  );
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _chooseRange() async {
    final selection = await pickDateRange(context, current: _selection.preset);
    if (selection == null) return;
    setState(() {
      _selection = selection;
      _filter = selection.range == null
          ? _filter.copyWith(clearRange: true)
          : _filter.copyWith(range: selection.range);
    });
  }

  Future<void> _chooseCategory(List<TransactionCategory> categories) async {
    // Returns '' for "All categories".
    final id = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        builder: (context, controller) => ListView(
          controller: controller,
          children: [
            ListTile(
              title: const Text('All categories'),
              onTap: () => Navigator.of(context).pop(''),
            ),
            for (final c in categories)
              ListTile(
                title: Text(c.name),
                subtitle: Text(c.type.label),
                trailing: c.id == _filter.categoryId
                    ? const Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.of(context).pop(c.id),
              ),
          ],
        ),
      ),
    );
    if (id == null) return;
    setState(() {
      _filter = id.isEmpty
          ? _filter.copyWith(clearCategory: true)
          : _filter.copyWith(categoryId: id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final txAsync = ref.watch(transactionQueryProvider(_filter.queryPart));
    final categories = ref.watch(categoriesProvider).value ?? const [];
    final categoryById = {for (final c in categories) c.id: c};
    final selectedCategory = categoryById[_filter.categoryId];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Transactions')),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add transaction',
        onPressed: () => context.push(AppRoutes.newTransactionOf(
            (_filter.type ?? TransactionType.expense).name)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        child: const Icon(Icons.add_rounded, size: 28),
      ),
      body: Column(
        children: [
          // ── Type tabs + search + filters ─────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: PillTabs<TransactionType?>(
              options: const [null, TransactionType.income, TransactionType.expense],
              selected: _filter.type,
              labelOf: (t) => t == null ? 'All' : (t.isIncomeType ? 'Income' : 'Expenses'),
              onSelected: (type) => setState(() {
                _filter = type == null
                    ? _filter.copyWith(clearType: true)
                    : _filter.copyWith(type: type);
              }),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              controller: _search,
              onChanged: (v) =>
                  setState(() => _filter = _filter.copyWith(search: v)),
              decoration: InputDecoration(
                hintText: 'Search description or category',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _search.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        tooltip: 'Clear search',
                        onPressed: () => setState(() {
                          _search.clear();
                          _filter = _filter.copyWith(search: '');
                        }),
                      ),
              ),
            ),
          ),
          SizedBox(
            height: 52,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _FilterChip(
                  icon: Icons.date_range_rounded,
                  label: _selection.label,
                  selected: true,
                  onTap: _chooseRange,
                ),
                const Gap(8),
                _FilterChip(
                  icon: Icons.category_outlined,
                  label: selectedCategory?.name ?? 'Category',
                  selected: selectedCategory != null,
                  onTap: () => _chooseCategory(categories),
                ),
              ],
            ),
          ),

          // ── Results ─────────────────────────────────────────────
          Expanded(
            child: txAsync.when(
              loading: () => const LoadingState(),
              error: (e, _) => Center(
                child: ErrorState(
                  error: e,
                  onRetry: () => ref.invalidate(
                      transactionQueryProvider(_filter.queryPart)),
                ),
              ),
              data: (all) {
                final items = all.where(_filter.matches).toList();
                if (items.isEmpty) {
                  return Center(
                    child: SingleChildScrollView(
                      child: EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: all.isEmpty
                            ? 'No transactions yet'
                            : 'No matching transactions',
                        message: all.isEmpty
                            ? 'Start by adding your first income or expense to see your records here.'
                            : 'Try a different search, date range or category.',
                        actionLabel: all.isEmpty ? 'Add Transaction' : null,
                        onAction: () => context.push(AppRoutes.newTransactionOf(
                            TransactionType.expense.name)),
                      ),
                    ),
                  );
                }
                return _TransactionList(
                  items: items,
                  categoryById: categoryById,
                  reachedCap: _filter.range == null &&
                      all.length >= TransactionRepository.allTimeLimit,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  const _TransactionList({
    required this.items,
    required this.categoryById,
    required this.reachedCap,
  });

  final List<FinanceTransaction> items;
  final Map<String, TransactionCategory> categoryById;
  final bool reachedCap;

  @override
  Widget build(BuildContext context) {
    final summary = FinanceSummary.fromTransactions(items);

    // Flatten into header + rows so ListView.builder stays lazy.
    final rows = <Object>[];
    DateTime? lastDay;
    for (final tx in items) {
      if (lastDay == null || !AppDateUtils.isSameDay(lastDay, tx.date)) {
        rows.add(tx.date);
        lastDay = tx.date;
      }
      rows.add(tx);
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
      itemCount: rows.length + 1 + (reachedCap ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == 0) return _ResultsSummary(summary: summary);
        if (index == rows.length + 1) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Showing the latest ${TransactionRepository.allTimeLimit} '
              'transactions. Choose a date range to see older ones.',
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
          );
        }
        final row = rows[index - 1];
        if (row is DateTime) {
          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 4),
            child: Text(
              AppDateUtils.relativeDayLabel(row),
              style: AppTextStyles.labelMedium,
            ),
          );
        }
        final tx = row as FinanceTransaction;
        return TransactionTile(
          transaction: tx,
          category: categoryById[tx.categoryId],
          onTap: () => context.push(AppRoutes.transactionDetail(tx.id)),
        );
      },
    );
  }
}

/// Income / expense totals of the visible results, one line per currency.
class _ResultsSummary extends StatelessWidget {
  const _ResultsSummary({required this.summary});

  final FinanceSummary summary;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        children: [
          for (final t in summary.byCurrency.values)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Text(t.currency, style: AppTextStyles.labelMedium),
                  const Spacer(),
                  Text(
                    '+${Money.format(t.incomeMinor, t.currency)}',
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.success),
                  ),
                  const Gap(12),
                  Text(
                    '-${Money.format(t.expenseMinor, t.currency)}',
                    style: AppTextStyles.labelLarge,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      avatar: icon == null
          ? null
          : Icon(icon,
              size: 16,
              color: selected ? AppColors.primary : AppColors.textSecondary),
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      backgroundColor: AppColors.background,
      selectedColor: AppColors.softTeal,
      side: BorderSide(
        color: selected ? AppColors.primary.withAlpha(80) : AppColors.border,
      ),
      labelStyle: AppTextStyles.labelLarge.copyWith(
        color: selected ? AppColors.primaryDark : AppColors.textSecondary,
      ),
    );
  }
}
