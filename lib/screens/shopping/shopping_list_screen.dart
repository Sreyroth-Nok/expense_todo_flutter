import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_states.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/ui_kit.dart';
import '../../services/auth_repository.dart';
import '../../services/shopping_repository.dart';
import '../../models/shopping.dart';
import '../../providers/shopping_providers.dart';

/// Items of one shopping list: quick add, check off, edit, remove.
class ShoppingListScreen extends ConsumerStatefulWidget {
  const ShoppingListScreen({super.key, required this.listId});

  final String listId;

  @override
  ConsumerState<ShoppingListScreen> createState() => _ShoppingListScreenState();
}

class _ShoppingListScreenState extends ConsumerState<ShoppingListScreen> {
  final _quickAdd = TextEditingController();

  @override
  void dispose() {
    _quickAdd.dispose();
    super.dispose();
  }

  String? get _uid => ref.read(currentUidProvider);
  ShoppingRepository get _repo => ref.read(shoppingRepositoryProvider);

  Future<void> _run(Future<void> Function(String uid) action) async {
    final uid = _uid;
    if (uid == null) return;
    try {
      await action(uid);
    } catch (e) {
      if (mounted) AppSnackBar.error(context, readableError(e));
    }
  }

  Future<void> _addQuick() async {
    final name = _quickAdd.text.trim();
    if (name.isEmpty) return;
    _quickAdd.clear();
    await _run((uid) =>
        _repo.saveItem(uid, widget.listId, ShoppingItem(name: name)));
  }

  Future<void> _editItem(ShoppingItem? item) async {
    final result = await showModalBottomSheet<ShoppingItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (_) => _ItemEditor(item: item),
    );
    if (result == null) return;
    await _run((uid) => _repo.saveItem(uid, widget.listId, result));
  }

  Future<void> _menu(String action, ShoppingList list) async {
    switch (action) {
      case 'rename':
        final name = await showTextInputDialog(
          context,
          title: 'Rename list',
          label: 'List name',
          initialValue: list.name,
          validator: validateListName,
        );
        if (name != null) {
          await _run((uid) => _repo.renameList(uid, list.id, name));
        }
      case 'clear':
        await _run((uid) async {
          final n = await _repo.clearPurchased(uid, list.id);
          if (mounted) AppSnackBar.success(context, 'Removed $n purchased item(s).');
        });
      case 'delete':
        final ok = await showConfirmDialog(
          context,
          title: 'Delete "${list.name}"?',
          message: 'The list and all its items will be removed.',
          confirmLabel: 'Delete',
          destructive: true,
        );
        if (!ok || !mounted) return;
        await _run((uid) => _repo.deleteList(uid, list.id));
        if (mounted) context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(shoppingListByIdProvider(widget.listId));
    final itemsAsync = ref.watch(shoppingItemsProvider(widget.listId));
    final list = listAsync.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(list?.name ?? 'Shopping list'),
        actions: [
          if (list != null)
            PopupMenuButton<String>(
              tooltip: 'List options',
              onSelected: (v) => _menu(v, list),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rename', child: Text('Rename list')),
                PopupMenuItem(
                    value: 'clear', child: Text('Remove purchased items')),
                PopupMenuItem(value: 'delete', child: Text('Delete list')),
              ],
            ),
        ],
      ),
      body: listAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => Center(child: ErrorState(error: e)),
        data: (l) => l == null
            ? const Center(
                child: EmptyState(
                  icon: Icons.search_off_rounded,
                  title: 'List not found',
                  message: 'It may have been deleted.',
                ),
              )
            : Column(
                children: [
                  // ── Quick add ────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _quickAdd,
                            textCapitalization: TextCapitalization.sentences,
                            textInputAction: TextInputAction.done,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(60),
                            ],
                            onSubmitted: (_) => _addQuick(),
                            decoration: const InputDecoration(
                              hintText: 'Add an item, e.g. Rice',
                              prefixIcon: Icon(Icons.add_shopping_cart_rounded),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Add with quantity',
                          icon: const Icon(Icons.tune_rounded),
                          onPressed: () => _editItem(null),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: itemsAsync.when(
                      loading: () => const LoadingState(),
                      error: (e, _) => Center(child: ErrorState(error: e)),
                      data: (items) => items.isEmpty
                          ? const Center(
                              child: EmptyState(
                                icon: Icons.shopping_basket_outlined,
                                title: 'This list is empty',
                                message: 'Type an item above and press enter.',
                              ),
                            )
                          : _ItemList(
                              items: items,
                              onToggle: (i) => _run((uid) => _repo.setPurchased(
                                  uid, widget.listId, i.id, !i.isPurchased)),
                              onEdit: _editItem,
                              onDelete: (i) => _run((uid) =>
                                  _repo.deleteItem(uid, widget.listId, i.id)),
                              onAdd: () => _editItem(null),
                            ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ItemList extends StatelessWidget {
  const _ItemList({
    required this.items,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  final VoidCallback onAdd;
  final List<ShoppingItem> items;
  final ValueChanged<ShoppingItem> onToggle;
  final ValueChanged<ShoppingItem> onEdit;
  final ValueChanged<ShoppingItem> onDelete;

  @override
  Widget build(BuildContext context) {
    final toBuy = items.where((i) => !i.isPurchased).toList();
    final bought = items.where((i) => i.isPurchased).toList();

    Widget row(ShoppingItem item) => Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          onDismissed: (_) => onDelete(item),
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: AppColors.error.withAlpha(30),
            child: const Icon(Icons.delete_outline_rounded,
                color: AppColors.error),
          ),
          child: ListTile(
            leading: RoundCheck(
              checked: item.isPurchased,
              semanticLabel: item.name,
              onChanged: (_) => onToggle(item),
            ),
            title: Text(
              item.name,
              style: AppTextStyles.bodyLarge.copyWith(
                decoration:
                    item.isPurchased ? TextDecoration.lineThrough : null,
                color: item.isPurchased
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
              ),
            ),
            trailing: Text(item.quantityLabel, style: AppTextStyles.labelLarge),
            onTap: () => onEdit(item),
          ),
        );

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        for (final i in toBuy) row(i),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Item'),
            ),
          ),
        ),
        if (bought.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text('Purchased (${bought.length})',
                style: AppTextStyles.labelMedium),
          ),
          for (final i in bought) row(i),
        ],
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Swipe left on an item to remove it.',
              style: AppTextStyles.caption, textAlign: TextAlign.center),
        ),
      ],
    );
  }
}

/// Bottom sheet to add / edit an item with quantity and unit.
class _ItemEditor extends StatefulWidget {
  const _ItemEditor({this.item});

  final ShoppingItem? item;

  @override
  State<_ItemEditor> createState() => _ItemEditorState();
}

class _ItemEditorState extends State<_ItemEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.item?.name);
  late final _qty =
      TextEditingController(text: '${widget.item?.quantity ?? 1}');
  late final _unit = TextEditingController(text: widget.item?.unit);

  @override
  void dispose() {
    _name.dispose();
    _qty.dispose();
    _unit.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final base = widget.item ?? const ShoppingItem(name: '');
    Navigator.of(context).pop(base.copyWith(
      name: _name.text.trim(),
      quantity: int.parse(_qty.text.trim()),
      unit: _unit.text.trim(),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.item == null ? 'Add item' : 'Edit item',
                style: AppTextStyles.headlineSmall),
            const Gap(16),
            AppTextField(
              label: 'Item',
              controller: _name,
              autofocus: widget.item == null,
              textCapitalization: TextCapitalization.sentences,
              validator: (v) {
                final t = v?.trim() ?? '';
                if (t.isEmpty) return 'Item name is required.';
                return t.length > 60 ? 'Use 60 characters or fewer.' : null;
              },
            ),
            const Gap(12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: AppTextField(
                    label: 'Quantity',
                    controller: _qty,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      return n == null || n < 1 || n > 9999
                          ? 'Enter 1–9999.'
                          : null;
                    },
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: AppTextField(
                    label: 'Unit (optional)',
                    hint: 'kg, pcs…',
                    controller: _unit,
                    validator: (v) =>
                        (v?.trim().length ?? 0) > 12 ? 'Max 12 characters.' : null,
                  ),
                ),
              ],
            ),
            const Gap(20),
            AppPrimaryButton(label: 'Save', onPressed: _save),
          ],
        ),
      ),
    );
  }
}
