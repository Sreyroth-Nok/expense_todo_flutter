import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Rounded horizontal progress bar. [value] may exceed 1.0; it is clamped
/// for drawing only.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    this.color = AppColors.primary,
    this.height = 8,
  });

  final double value;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height),
      child: LinearProgressIndicator(
        value: value.isNaN ? 0 : value.clamp(0.0, 1.0),
        minHeight: height,
        color: color,
        backgroundColor: AppColors.divider,
      ),
    );
  }
}
