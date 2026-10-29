import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Shows a full-screen translucent overlay with a centered spinner.
///
/// Wrap your scaffold body in a [Stack] and add this on top when [isLoading] is true.
/// The overlay absorbs pointer events so the user cannot tap while loading.
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({super.key, this.isLoading = true, this.child});

  final bool isLoading;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ignore: use_null_aware_elements
        if (child != null) child!,
        if (isLoading)
          const Positioned.fill(
            child: AbsorbPointer(
              child: ColoredBox(
                color: Color(0x55FFFFFF),
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
