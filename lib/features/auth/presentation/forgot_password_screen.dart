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
import '../../../shared/widgets/app_snack_bar.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../domain/auth_providers.dart';
import '../../../core/l10n/l10n.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(forgotPasswordProvider.notifier)
        .sendResetEmail(_emailController.text);

    if (!mounted) return;
    if (success) {
      AppSnackBar.success(
        context,
        context.l10n.forgotSent,
      );
    } else {
      final error = ref.read(forgotPasswordProvider).errorMessage;
      AppSnackBar.error(context, error ?? context.l10n.forgotFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final state = ref.watch(forgotPasswordProvider);
    final isLoading = state.isLoading;
    final isSuccess = state.isSuccess;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l.forgotTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: isSuccess
              ? _SuccessView(
                  onBackToLogin: () => context.go(AppRoutes.login),
                )
              : Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // ── Illustration ────────────────────────────
                      Center(
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.softTeal,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.lock_reset_rounded,
                            size: 52,
                            color: AppColors.primary,
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(duration: 500.ms)
                          .scale(begin: const Offset(0.8, 0.8)),

                      const Gap(32),

                      // ── Instructions ─────────────────────────────
                      Text(
                        l.forgotHeadline,
                        style: AppTextStyles.headlineLarge,
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 200.ms),

                      const Gap(10),

                      Text(
                        l.forgotBody,
                        style: AppTextStyles.bodyLarge.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.6,
                        ),
                        textAlign: TextAlign.center,
                      ).animate().fadeIn(delay: 300.ms),

                      const Gap(36),

                      // ── Email field ───────────────────────────────
                      AppTextField(
                        label: l.fieldEmail,
                        hint: 'you@example.com',
                        controller: _emailController,
                        validator: AppValidators.email,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        prefixIcon: const Icon(Icons.email_outlined),
                      ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),

                      const Gap(28),

                      // ── Send button ───────────────────────────────
                      AppPrimaryButton(
                        label: l.forgotSendButton,
                        onPressed: isLoading ? null : _submit,
                        isLoading: isLoading,
                        icon: Icons.send_rounded,
                      ).animate().fadeIn(delay: 400.ms),

                      const Gap(20),

                      // ── Back link ──────────────────────────────────
                      Center(
                        child: AppTextLinkButton(
                          label: l.forgotBackToLogin,
                          onPressed: () => context.go(AppRoutes.login),
                        ),
                      ).animate().fadeIn(delay: 450.ms),
                    ],
                  ),
                ),
        ),
      ),
    );
  }
}

/// Shown after the reset email has been sent successfully.
class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.onBackToLogin});

  final VoidCallback onBackToLogin;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Color(0xFFDCFCE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              size: 52,
              color: AppColors.success,
            ),
          ),
        )
            .animate()
            .scale(begin: const Offset(0.5, 0.5), duration: 600.ms)
            .fadeIn(duration: 600.ms),

        const Gap(32),

        Text(
          l.forgotCheckInbox,
          style: AppTextStyles.headlineLarge,
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms),

        const Gap(12),

        Text(
          l.forgotCheckInboxBody,
          style: AppTextStyles.bodyLarge.copyWith(
            color: AppColors.textSecondary,
            height: 1.6,
          ),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 400.ms),

        const Gap(40),

        AppPrimaryButton(
          label: l.forgotBackToLogin,
          onPressed: onBackToLogin,
          icon: Icons.arrow_back_rounded,
        ).animate().fadeIn(delay: 500.ms),
      ],
    );
  }
}
