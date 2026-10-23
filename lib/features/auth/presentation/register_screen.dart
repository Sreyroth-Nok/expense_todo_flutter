import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../domain/auth_providers.dart';
import '../../../core/l10n/l10n.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(registerProvider.notifier).register(
          email: _emailController.text,
          password: _passwordController.text,
          displayName: _nameController.text,
        );

    if (!mounted) return;
    if (!success) {
      final error = ref.read(registerProvider).errorMessage;
      AppSnackBar.error(
          context, error ?? context.l10n.registerFailed);
    }
    // Navigation handled by GoRouter auth redirect.
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final authState = ref.watch(registerProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Back button ──────────────────────────────────
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back_rounded),
                    onPressed: () => context.go(AppRoutes.login),
                    tooltip: l.registerBackToLogin,
                  ),
                ),

                const Gap(8),

                // ── Logo ─────────────────────────────────────────
                const Center(child: AppLogo(size: 48)),
                const Gap(28),

                // ── Headline ──────────────────────────────────────
                Text(
                  l.registerTitle,
                  style: AppTextStyles.displayMedium,
                ).animate().fadeIn(delay: 100.ms),
                const Gap(6),
                Text(
                  l.registerSubtitle,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 200.ms),

                const Gap(32),

                // ── Full name ─────────────────────────────────────
                AppTextField(
                  label: l.fieldFullName,
                  hint: l.fieldFullNameHint,
                  controller: _nameController,
                  validator: AppValidators.displayName,
                  keyboardType: TextInputType.name,
                  textInputAction: TextInputAction.next,
                  textCapitalization: TextCapitalization.words,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

                const Gap(14),

                // ── Email ─────────────────────────────────────────
                AppTextField(
                  label: l.fieldEmail,
                  hint: 'you@example.com',
                  controller: _emailController,
                  validator: AppValidators.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.email_outlined),
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                const Gap(14),

                // ── Password ──────────────────────────────────────
                AppPasswordField(
                  label: l.fieldPassword,
                  hint: l.fieldPasswordHint,
                  controller: _passwordController,
                  validator: AppValidators.password,
                  textInputAction: TextInputAction.next,
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),

                const Gap(14),

                // ── Confirm password ──────────────────────────────
                AppPasswordField(
                  label: l.fieldConfirmPassword,
                  hint: l.fieldConfirmPasswordHint,
                  controller: _confirmController,
                  validator: AppValidators.confirmPassword(
                    _passwordController.text,
                  ),
                  textInputAction: TextInputAction.done,
                ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                // ── Password hint ─────────────────────────────────
                const Gap(8),
                _PasswordRequirementsHint()
                    .animate()
                    .fadeIn(delay: 420.ms),

                const Gap(28),

                // ── Register button ───────────────────────────────
                AppPrimaryButton(
                  label: l.registerButton,
                  onPressed: isLoading ? null : _submit,
                  isLoading: isLoading,
                ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.15),

                const Gap(20),

                // ── Login link ────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${l.authAlreadyHaveAccount}  ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    AppTextLinkButton(
                      label: l.authLogIn,
                      onPressed: () => context.go(AppRoutes.login),
                    ),
                  ],
                ).animate().fadeIn(delay: 500.ms),

                const Gap(24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small password requirement hint shown below the password field.
class _PasswordRequirementsHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.softTeal,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l.registerPasswordRules,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.primaryDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
