import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/progress_bar.dart';
import '../../auth/data/auth_repository.dart';
import '../data/shopping_repository.dart';
import '../domain/shopping.dart';
import '../domain/shopping_providers.dart';
import '../../../core/l10n/l10n.dart';

/// Lists tab: all shopping lists with purchased / total counts.
class ShoppingListsScreen extends ConsumerWidget {
  const ShoppingListsScreen({super.key});

  static Future<void> createList(BuildContext context, WidgetRef ref) async {
    final name = await showTextInputDialog(
      context,
      title: 'New shopping list',
      label: 'List name',
      confirmLabel: 'Create',
      validator: validateListName,
    );
    final uid = ref.read(currentUidProvider);
    if (name == null || uid == null || !context.mounted) return;
    try {
      final id = await ref.read(shoppingRepositoryProvider).createList(uid, name);
      if (context.mounted) context.push(AppRoutes.shoppingList(id));
    } catch (e) {
      if (context.mounted) AppSnackBar.error(context, readableError(e));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listsAsync = ref.watch(shoppingListsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.listsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => createList(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.playlist_add_rounded),
        label: const Text('New list'),
      ),
      body: listsAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => Center(child: ErrorState(error: e)),
        data: (lists) => lists.isEmpty
            ? Center(
                child: EmptyState(
                  icon: Icons.shopping_cart_outlined,
                  title: 'No shopping lists',
                  message: 'Create a list for groceries, the market or '
                      'anything else you need to buy.',
                  actionLabel: 'Create a list',
                  onAction: () => createList(context, ref),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 96),
                itemCount: lists.length,
                separatorBuilder: (_, _) => const Gap(12),
                itemBuilder: (context, i) => _ListCard(list: lists[i]),
              ),
      ),
    );
  }
}

class _ListCard extends ConsumerWidget {
  const _ListCard({required this.list});

  final ShoppingList list;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(shoppingItemsProvider(list.id)).value;
    final total = items?.length ?? 0;
    final bought = items?.where((i) => i.isPurchased).length ?? 0;

    return AppCard(
      onTap: () => context.push(AppRoutes.shoppingList(list.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_basket_rounded,
                  color: AppColors.primary),
              const Gap(10),
              Expanded(
                child: Text(list.name,
                    style: AppTextStyles.titleMedium,
                    overflow: TextOverflow.ellipsis),
              ),
              Text(
                items == null ? '…' : '$bought / $total',
                style: AppTextStyles.labelLarge,
              ),
            ],
          ),
          const Gap(10),
          ProgressBar(
            value: total == 0 ? 0 : bought / total,
            color: bought == total && total > 0
                ? AppColors.success
                : AppColors.honey,
            height: 6,
          ),
          const Gap(6),
          Text(
            total == 0
                ? 'Empty list'
                : bought == total
                    ? 'All items purchased'
                    : '${total - bought} item(s) left to buy',
            style: AppTextStyles.bodySmall,
          ),
        ],
      ),
    );
  }
}
