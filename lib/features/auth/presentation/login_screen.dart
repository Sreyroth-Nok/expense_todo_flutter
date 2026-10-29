import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/app_snack_bar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../domain/auth_providers.dart';
import 'widgets/google_sign_in_button.dart';

/// Email + password login, or "Continue with Google".
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(loginProvider.notifier).login(
          email: _emailController.text,
          password: _passwordController.text,
        );

    if (!mounted) return;
    if (!success) {
      final error = ref.read(loginProvider).errorMessage;
      AppSnackBar.error(context, error ?? context.l10n.loginFailed);
    }
    // Navigation is handled by GoRouter's auth redirect.
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isLoading = ref.watch(loginProvider).isLoading;
    final googleLoading = ref.watch(googleSignInProvider).isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: AppLogo(size: 64, animate: true)),
                const Gap(36),
                Text(l.loginTitle, style: AppTextStyles.headlineLarge)
                    .animate()
                    .fadeIn(delay: 150.ms),
                const Gap(4),
                Text(
                  l.loginSubtitle,
                  style: AppTextStyles.bodyMedium
                      .copyWith(color: AppColors.textSecondary),
                ).animate().fadeIn(delay: 200.ms),
                const Gap(24),

                AppTextField(
                  label: l.fieldEmail,
                  showLabel: false,
                  controller: _emailController,
                  validator: AppValidators.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                const Gap(14),
                AppPasswordField(
                  label: l.fieldPassword,
                  showLabel: false,
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  textInputAction: TextInputAction.done,
                  validator: (v) =>
                      v == null || v.isEmpty ? l.validationPasswordRequired : null,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                    child: Text(
                      l.loginForgotPassword,
                      style: AppTextStyles.labelMedium.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const Gap(8),

                AppPrimaryButton(
                  label: l.authLogIn,
                  onPressed: isLoading || googleLoading ? null : _submit,
                  isLoading: isLoading,
                ),
                const Gap(20),
                const OrDivider(),
                const Gap(20),
                GoogleSignInButton(enabled: !isLoading),
                const Gap(28),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l.loginNoAccount,
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                    TextButton(
                      onPressed: () => context.go(AppRoutes.register),
                      child: Text(
                        l.authSignUp,
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
