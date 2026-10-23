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

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
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
    // Navigation is handled by GoRouter's auth redirect — no manual push needed.
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final authState = ref.watch(loginProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Logo ────────────────────────────────────────
                const Center(child: AppLogo(size: 56, animate: true)),
                const Gap(40),

                // ── Headline ─────────────────────────────────────
                Text(
                  l.loginTitle,
                  style: AppTextStyles.displayMedium,
                ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                const Gap(6),
                Text(
                  l.loginSubtitle,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ).animate().fadeIn(delay: 300.ms, duration: 400.ms),

                const Gap(36),

                // ── Email field ───────────────────────────────────
                AppTextField(
                  label: l.fieldEmail,
                  hint: l.fieldEmailHint,
                  controller: _emailController,
                  validator: AppValidators.email,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  focusNode: _emailFocus,
                  prefixIcon: const Icon(Icons.email_outlined),
                  onChanged: (_) => ref
                      .read(loginProvider.notifier)
                      .build(), // clear stale error
                )
                    .animate()
                    .fadeIn(delay: 350.ms, duration: 400.ms)
                    .slideY(begin: 0.1, duration: 400.ms),

                const Gap(16),

                // ── Password field ────────────────────────────────
                AppPasswordField(
                  label: l.fieldPassword,
                  hint: '••••••••',
                  controller: _passwordController,
                  validator: (v) =>
                      v == null || v.isEmpty ? l.validationPasswordRequired : null,
                  textInputAction: TextInputAction.done,
                  focusNode: _passwordFocus,
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 400.ms)
                    .slideY(begin: 0.1, duration: 400.ms),

                const Gap(8),

                // ── Forgot password link ───────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: AppTextLinkButton(
                    label: l.loginForgotPassword,
                    onPressed: () => context.push(AppRoutes.forgotPassword),
                  ),
                ).animate().fadeIn(delay: 450.ms, duration: 400.ms),

                const Gap(28),

                // ── Login button ──────────────────────────────────
                AppPrimaryButton(
                  label: l.authLogIn,
                  onPressed: isLoading ? null : _submit,
                  isLoading: isLoading,
                )
                    .animate()
                    .fadeIn(delay: 500.ms, duration: 400.ms)
                    .slideY(begin: 0.15, duration: 400.ms),

                const Gap(24),

                // ── Register link ─────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${l.loginNoAccount}  ',
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    AppTextLinkButton(
                      label: l.loginCreateOne,
                      onPressed: () => context.go(AppRoutes.register),
                    ),
                  ],
                ).animate().fadeIn(delay: 600.ms, duration: 400.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
