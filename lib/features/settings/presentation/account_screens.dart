import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/l10n/l10n.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_card.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../../shared/widgets/app_states.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/settings_actions.dart';

// ── Edit profile ───────────────────────────────────────────────────────────

/// Change the display name. (Profile photos are not part of the MVP, so
/// Firebase Storage is not used.)
class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  TextEditingController? _name;
  bool _saving = false;

  @override
  void dispose() {
    _name?.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await ref.read(settingsActionsProvider).updateDisplayName(_name!.text);
      if (!mounted) return;
      AppSnackBar.success(context, context.l10n.profileSaved);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppSnackBar.error(context, readableError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final profileAsync = ref.watch(currentUserProfileProvider);
    final email = ref.watch(authStateProvider).value?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l.profileTitle)),
      body: profileAsync.when(
        loading: () => const LoadingState(),
        error: (e, _) => Center(child: ErrorState(error: e)),
        data: (profile) {
          _name ??= TextEditingController(text: profile?.displayName ?? '');
          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                AppTextField(
                  label: l.profileName,
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  validator: AppValidators.displayName,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                const Gap(16),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: l.profileEmail,
                    prefixIcon: const Icon(Icons.email_outlined),
                    enabled: false,
                  ),
                  child: Text(email, style: AppTextStyles.bodyLarge),
                ),
                const Gap(6),
                Text(l.profileEmailNote, style: AppTextStyles.bodySmall),
                const Gap(28),
                AppPrimaryButton(
                  label: l.commonSave,
                  icon: Icons.check_rounded,
                  isLoading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Change password ────────────────────────────────────────────────────────

class ChangePasswordScreen extends ConsumerWidget {
  const ChangePasswordScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(context.l10n.changePasswordTitle)),
      body: ChangePasswordForm(
        onSubmit: (current, next) async {
          await ref.read(settingsActionsProvider).changePassword(current, next);
          if (!context.mounted) return;
          AppSnackBar.success(context, context.l10n.passwordChanged);
          context.pop();
        },
      ),
    );
  }
}

/// The change-password form. Separate from the screen so it can be
/// widget-tested without Firebase.
class ChangePasswordForm extends StatefulWidget {
  const ChangePasswordForm({super.key, required this.onSubmit});

  /// Called with (currentPassword, newPassword) after validation.
  final Future<void> Function(String current, String next) onSubmit;

  @override
  State<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends State<ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _next = TextEditingController();
  final _confirm = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _current.dispose();
    _next.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      await widget.onSubmit(_current.text, _next.text);
    } catch (e) {
      if (mounted) AppSnackBar.error(context, readableError(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(l.changePasswordInfo, style: AppTextStyles.bodyMedium),
          const Gap(20),
          AppPasswordField(
            key: const Key('currentPassword'),
            label: l.currentPassword,
            controller: _current,
            validator: (v) =>
                v == null || v.isEmpty ? l.validationPasswordRequired : null,
          ),
          const Gap(16),
          AppPasswordField(
            key: const Key('newPassword'),
            label: l.newPassword,
            controller: _next,
            validator: (v) {
              final base = AppValidators.password(v);
              if (base != null) return base;
              return v == _current.text ? l.newPasswordSame : null;
            },
          ),
          const Gap(16),
          AppPasswordField(
            key: const Key('confirmPassword'),
            label: l.confirmNewPassword,
            controller: _confirm,
            validator: (v) => AppValidators.confirmPassword(_next.text)(v),
          ),
          const Gap(8),
          Text(l.registerPasswordRules, style: AppTextStyles.bodySmall),
          const Gap(28),
          AppPrimaryButton(
            label: l.changePasswordButton,
            icon: Icons.lock_reset_rounded,
            isLoading: _saving,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

// ── Delete account ─────────────────────────────────────────────────────────

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  bool _deleting = false;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    final l = context.l10n;
    final usesPassword = ref.read(hasPasswordProvider);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final ok = await showConfirmDialog(
      context,
      title: l.deleteConfirmTitle,
      message: l.deleteConfirmBody,
      confirmLabel: l.commonDelete,
      destructive: true,
    );
    if (!ok || !mounted) return;

    setState(() => _deleting = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await ref
          .read(settingsActionsProvider)
          .deleteAccount(usesPassword ? _password.text : null);
      // The auth redirect moves to the login screen; the messenger outlives
      // this screen so the confirmation is still shown.
      messenger.showSnackBar(SnackBar(content: Text(l.deleteDone)));
    } on AuthCancelledException {
      // Closed the Google picker: nothing was deleted.
      if (mounted) setState(() => _deleting = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      AppSnackBar.error(context, readableError(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final usesPassword = ref.watch(hasPasswordProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l.deleteTitle)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppCard(
              color: AppColors.error.withAlpha(18),
              borderColor: AppColors.error.withAlpha(60),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: AppColors.error),
                  const Gap(12),
                  Expanded(
                    child: Text(l.deleteWarning,
                        style: AppTextStyles.titleMedium
                            .copyWith(color: AppColors.error)),
                  ),
                ],
              ),
            ),
            const Gap(16),
            Text(l.deleteWhatIsDeleted, style: AppTextStyles.bodyMedium),
            const Gap(12),
            TextButton.icon(
              onPressed: () => context.go(AppRoutes.reports),
              icon: const Icon(Icons.ios_share_rounded),
              label: Text(l.deleteExportHint),
            ),
            const Gap(16),
            if (usesPassword)
              AppPasswordField(
                label: l.deletePasswordLabel,
                controller: _password,
                validator: (v) =>
                    v == null || v.isEmpty ? l.validationPasswordRequired : null,
              )
            else
              Text(l.deleteGoogleHint, style: AppTextStyles.bodyMedium),
            const Gap(28),
            if (_deleting)
              Column(
                children: [
                  const CircularProgressIndicator(color: AppColors.error),
                  const Gap(12),
                  Text(l.deleteInProgress, style: AppTextStyles.bodyMedium),
                ],
              )
            else
              ElevatedButton.icon(
                onPressed: _delete,
                icon: const Icon(Icons.delete_forever_rounded),
                label: Text(
                    usesPassword ? l.deleteButton : l.deleteConfirmWithGoogle),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
