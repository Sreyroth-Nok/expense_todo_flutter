import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/data/auth_repository.dart';
import '../data/category_repository.dart';
import '../domain/finance_transaction.dart';
import '../domain/transaction_category.dart';
import '../domain/transaction_providers.dart';
import 'widgets/category_visuals.dart';

/// Lists the user's categories and lets them add, edit and delete them.
class CategoriesScreen extends ConsumerWidget {
  const CategoriesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Categories'),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            indicatorColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            tabs: [Tab(text: 'Expense'), Tab(text: 'Income')],
          ),
        ),
        floatingActionButton: Builder(
          // Builder gives a context below DefaultTabController.
          builder: (context) => FloatingActionButton(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            tooltip: 'Add category',
            onPressed: () {
              final tab = DefaultTabController.of(context).index;
              _openEditor(
                context,
                ref,
                type: tab == 0 ? TransactionType.expense : TransactionType.income,
              );
            },
            child: const Icon(Icons.add_rounded),
          ),
        ),
        body: categoriesAsync.when(
          loading: () => const LoadingState(),
          error: (e, _) => Center(child: ErrorState(error: e)),
          data: (all) => TabBarView(
            children: [
              for (final type in TransactionType.values.reversed)
                _CategoryList(
                  categories: all.where((c) => c.type == type).toList(),
                  onEdit: (c) =>
                      _openEditor(context, ref, type: c.type, existing: c),
                  onDelete: (c) => _delete(context, ref, c),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openEditor(
    BuildContext context,
    WidgetRef ref, {
    required TransactionType type,
    TransactionCategory? existing,
  }) async {
    final result = await showModalBottomSheet<TransactionCategory>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.background,
      builder: (context) => _CategoryEditor(type: type, existing: existing),
    );
    if (result == null || !context.mounted) return;

    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    final repo = ref.read(categoryRepositoryProvider);
    try {
      if (existing == null) {
        await repo.add(uid, result);
      } else {
        await repo.update(uid, result);
      }
      if (context.mounted) AppSnackBar.success(context, 'Category saved.');
    } catch (e) {
      if (context.mounted) AppSnackBar.error(context, readableError(e));
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    TransactionCategory category,
  ) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'Delete "${category.name}"?',
      message: 'Existing transactions are kept and still show this '
          'category name. You will not be able to pick it for new ones.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;
    final uid = ref.read(currentUidProvider);
    if (uid == null) return;
    try {
      await ref.read(categoryRepositoryProvider).delete(uid, category.id);
      if (context.mounted) AppSnackBar.success(context, 'Category deleted.');
    } catch (e) {
      if (context.mounted) AppSnackBar.error(context, readableError(e));
    }
  }
}

class _CategoryList extends StatelessWidget {
  const _CategoryList({
    required this.categories,
    required this.onEdit,
    required this.onDelete,
  });

  final List<TransactionCategory> categories;
  final ValueChanged<TransactionCategory> onEdit;
  final ValueChanged<TransactionCategory> onDelete;

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(
        child: EmptyState(
          icon: Icons.category_outlined,
          title: 'No categories',
          message: 'Tap + to create your first category.',
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: categories.length,
      separatorBuilder: (_, _) => const Divider(),
      itemBuilder: (context, i) {
        final c = categories[i];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading:
              CategoryIconBadge(iconKey: c.iconKey, colorValue: c.colorValue),
          title: Text(c.name, style: AppTextStyles.titleMedium),
          onTap: () => onEdit(c),
          trailing: IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            color: AppColors.textSecondary,
            tooltip: 'Delete',
            onPressed: () => onDelete(c),
          ),
        );
      },
    );
  }
}

/// Bottom sheet for creating or editing a category.
class _CategoryEditor extends StatefulWidget {
  const _CategoryEditor({required this.type, this.existing});

  final TransactionType type;
  final TransactionCategory? existing;

  @override
  State<_CategoryEditor> createState() => _CategoryEditorState();
}

class _CategoryEditorState extends State<_CategoryEditor> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.existing?.name ?? '');
  late String _iconKey = widget.existing?.iconKey ?? 'other';
  late int _color = widget.existing?.colorValue ?? CategoryIcons.palette.first;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final base = widget.existing ??
        TransactionCategory(
          name: '',
          type: widget.type,
          iconKey: _iconKey,
          colorValue: _color,
        );
    Navigator.of(context).pop(
      base.copyWith(name: _name.text.trim(), iconKey: _iconKey, colorValue: _color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.existing == null
                    ? 'New ${widget.type.label.toLowerCase()} category'
                    : 'Edit category',
                style: AppTextStyles.headlineSmall,
              ),
              const Gap(16),
              AppTextField(
                label: 'Name',
                controller: _name,
                autofocus: widget.existing == null,
                textCapitalization: TextCapitalization.words,
                validator: (v) {
                  final required = AppValidators.required(v, fieldName: 'Name');
                  if (required != null) return required;
                  if (v!.trim().length > 30) {
                    return 'Name must be 30 characters or fewer.';
                  }
                  return null;
                },
              ),
              const Gap(16),
              Text('Icon', style: AppTextStyles.titleMedium),
              const Gap(8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final key in CategoryIcons.byKey.keys)
                    InkWell(
                      onTap: () => setState(() => _iconKey = key),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: key == _iconKey
                                ? AppColors.primary
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: CategoryIconBadge(
                            iconKey: key, colorValue: _color, size: 40),
                      ),
                    ),
                ],
              ),
              const Gap(16),
              Text('Color', style: AppTextStyles.titleMedium),
              const Gap(8),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final color in CategoryIcons.palette)
                    GestureDetector(
                      onTap: () => setState(() => _color = color),
                      child: CircleAvatar(
                        radius: 16,
                        backgroundColor: Color(color),
                        child: color == _color
                            ? const Icon(Icons.check_rounded,
                                size: 18, color: Colors.white)
                            : null,
                      ),
                    ),
                ],
              ),
              const Gap(24),
              AppPrimaryButton(label: 'Save', onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}
