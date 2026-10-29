import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/l10n.dart';
import '../../routing/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../utils/validators.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_logo.dart';
import '../../widgets/app_snack_bar.dart';
import '../../widgets/app_text_field.dart';
import '../../providers/auth_providers.dart';
import '../../widgets/google_sign_in_button.dart';

/// Create an account with email + password, or with Google.
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
      AppSnackBar.error(context, error ?? context.l10n.registerFailed);
    }
    // Navigation handled by GoRouter auth redirect.
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isLoading = ref.watch(registerProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: l.registerBackToLogin,
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: AppLogo(size: 56)),
                const Gap(20),
                Text(
                  l.registerTitle,
                  style: AppTextStyles.headlineMedium,
                  textAlign: TextAlign.center,
                ).animate().fadeIn(),
                const Gap(4),
                Text(
                  l.registerSubtitle,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const Gap(24),
                AppTextField(
                  label: l.fieldFullName,
                  showLabel: false,
                  controller: _nameController,
                  validator: AppValidators.displayName,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                const Gap(14),
                AppTextField(
                  label: l.fieldEmail,
                  showLabel: false,
                  controller: _emailController,
                  validator: AppValidators.email,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  textInputAction: TextInputAction.next,
                  prefixIcon: const Icon(Icons.email_outlined),
                ),
                const Gap(14),
                AppPasswordField(
                  label: l.fieldPassword,
                  showLabel: false,
                  controller: _passwordController,
                  validator: AppValidators.password,
                  textInputAction: TextInputAction.next,
                ),
                const Gap(14),
                AppPasswordField(
                  label: l.fieldConfirmPassword,
                  showLabel: false,
                  controller: _confirmController,
                  validator: (v) =>
                      AppValidators.confirmPassword(_passwordController.text)(v),
                  textInputAction: TextInputAction.done,
                ),
                const Gap(8),
                Text(l.registerPasswordRules, style: AppTextStyles.bodySmall),
                const Gap(24),
                AppPrimaryButton(
                  label: l.registerButton,
                  onPressed: isLoading ? null : _submit,
                  isLoading: isLoading,
                ),
                const Gap(18),
                const OrDivider(),
                const Gap(18),
                GoogleSignInButton(enabled: !isLoading),
                const Gap(20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l.authAlreadyHaveAccount,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.login),
                      child: Text(
                        l.authLogIn,
                        style: AppTextStyles.labelLarge.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
