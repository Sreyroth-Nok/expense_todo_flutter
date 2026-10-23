import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// The LifeMate brand logo widget.
///
/// Shows the teal leaf/mate icon alongside the "LifeMate" wordmark.
/// [size] controls the icon diameter; text scales proportionally.
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 48,
    this.showText = true,
    this.color,
    this.animate = false,
  });

  final double size;
  final bool showText;
  final Color? color;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final iconColor = color ?? AppColors.primary;

    Widget logo = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.softTeal,
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Icon(
            Icons.spa_rounded,
            size: size * 0.58,
            color: iconColor,
          ),
        ),
        if (showText) ...[
          SizedBox(height: size * 0.18),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Life',
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontSize: size * 0.42,
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                TextSpan(
                  text: 'Mate',
                  style: AppTextStyles.headlineMedium.copyWith(
                    fontSize: size * 0.42,
                    color: iconColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );

    if (animate) {
      logo = logo
          .animate()
          .fadeIn(duration: 600.ms)
          .scale(begin: const Offset(0.85, 0.85), duration: 600.ms);
    }

    return logo;
  }
}
