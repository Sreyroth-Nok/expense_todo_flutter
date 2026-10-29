import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/l10n/l10n.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/app_snack_bar.dart';
import '../../domain/auth_providers.dart';

/// "Continue with Google" button (white with the Google "G", following
/// Google's branding guidelines). Shows its own loading state and errors.
class GoogleSignInButton extends ConsumerWidget {
  const GoogleSignInButton({super.key, this.enabled = true});

  final bool enabled;

  Future<void> _signIn(BuildContext context, WidgetRef ref) async {
    FocusScope.of(context).unfocus();
    final ok = await ref.read(googleSignInProvider.notifier).signIn();
    if (!ok && context.mounted) {
      final error = ref.read(googleSignInProvider).errorMessage;
      // No message when the user simply closed the account picker.
      if (error != null) AppSnackBar.error(context, error);
    }
    // On success GoRouter's auth redirect opens Home.
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final loading = ref.watch(googleSignInProvider).isLoading;
    return OutlinedButton(
      onPressed: !enabled || loading ? null : () => _signIn(context, ref),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border, width: 1.2),
        backgroundColor: AppColors.background,
      ),
      child: loading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: AppColors.primary),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SvgPicture.asset('assets/icons/google_g.svg',
                    width: 20, height: 20),
                const SizedBox(width: 12),
                Text(
                  context.l10n.authContinueWithGoogle,
                  style: AppTextStyles.buttonText
                      .copyWith(color: AppColors.textPrimary),
                ),
              ],
            ),
    );
  }
}

/// "────── or ──────" divider between email and Google sign-in.
class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: AppColors.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(context.l10n.authOr, style: AppTextStyles.bodySmall),
        ),
        const Expanded(child: Divider(color: AppColors.border)),
      ],
    );
  }
}
