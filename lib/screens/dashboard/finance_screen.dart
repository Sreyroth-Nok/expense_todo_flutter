import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../routing/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_card.dart';
import '../../l10n/l10n.dart';

/// Finance tab: entry point to every money feature.
class FinanceScreen extends StatelessWidget {
  const FinanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l.financeTitle)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _FinanceTile(
            icon: Icons.receipt_long_rounded,
            title: l.financeTransactions,
            subtitle: l.financeTransactionsDesc,
            onTap: () => context.go(AppRoutes.transactions),
          ),
          _FinanceTile(
            icon: Icons.speed_rounded,
            title: l.financeLimits,
            subtitle: l.financeLimitsDesc,
            onTap: () => context.go(AppRoutes.spendingLimits),
          ),
          _FinanceTile(
            icon: Icons.category_rounded,
            title: l.financeCategories,
            subtitle: l.financeCategoriesDesc,
            onTap: () => context.push(AppRoutes.categories),
          ),
          _FinanceTile(
            icon: Icons.pie_chart_rounded,
            title: l.financeBudgets,
            subtitle: l.financeBudgetsDesc,
            onTap: () => context.go(AppRoutes.budgets),
          ),
          _FinanceTile(
            icon: Icons.savings_rounded,
            title: l.financeSavings,
            subtitle: l.financeSavingsDesc,
            onTap: () => context.go(AppRoutes.savings),
          ),
          _FinanceTile(
            icon: Icons.insert_chart_rounded,
            title: l.financeReports,
            subtitle: l.financeReportsDesc,
            onTap: () => context.go(AppRoutes.reports),
          ),
        ],
      ),
    );
  }
}

class _FinanceTile extends StatelessWidget {
  const _FinanceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        onTap: onTap,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.softTeal,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
            ),
            const Gap(14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.titleMedium),
                  const Gap(2),
                  Text(subtitle, style: AppTextStyles.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }
}
