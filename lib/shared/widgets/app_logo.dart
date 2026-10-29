import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// The LifeMate leaf mark: two Deep Teal leaves and one Honey leaf.
/// Drawn in code, so it is sharp at every size and needs no image asset.
class LifeMateMark extends StatelessWidget {
  const LifeMateMark({super.key, this.size = 48});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(painter: _LeafMarkPainter()),
    );
  }
}

class _LeafMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final base = Offset(s * 0.48, s * 0.92);

    void leaf(double length, double width, double angle, Color color,
        {Offset? from}) {
      final origin = from ?? base;
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      canvas.rotate(angle);
      final path = Path()
        ..moveTo(0, 0)
        ..quadraticBezierTo(width, -length * 0.45, 0, -length)
        ..quadraticBezierTo(-width, -length * 0.45, 0, 0)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
      // Leaf vein.
      canvas.drawLine(
        Offset.zero,
        Offset(0, -length * 0.82),
        Paint()
          ..color = Colors.white.withAlpha(110)
          ..strokeWidth = s * 0.018
          ..strokeCap = StrokeCap.round,
      );
      canvas.restore();
    }

    leaf(s * 0.86, s * 0.34, -0.42, AppColors.primary);
    leaf(s * 0.62, s * 0.26, 0.38, AppColors.primaryDark);
    leaf(s * 0.48, s * 0.22, 1.05, AppColors.honey,
        from: Offset(s * 0.52, s * 0.9));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Leaf mark + "LifeMate" wordmark, optionally with the tagline.
///
/// [horizontal] puts the text next to the mark (used in app bars).
class AppLogo extends StatelessWidget {
  const AppLogo({
    super.key,
    this.size = 48,
    this.showText = true,
    this.tagline,
    this.horizontal = false,
    this.animate = false,
    this.color,
  });

  final double size;
  final bool showText;

  /// e.g. "Plan Today · Live Better" (pass a translated string).
  final String? tagline;
  final bool horizontal;
  final bool animate;

  /// Wordmark color (defaults to Deep Teal).
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final wordmark = Text(
      'LifeMate',
      style: AppTextStyles.displayMedium.copyWith(
        fontSize: horizontal ? size * 0.62 : size * 0.62,
        color: color ?? AppColors.primary,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        height: 1.1,
      ),
    );

    Widget logo;
    if (horizontal) {
      logo = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LifeMateMark(size: size),
          SizedBox(width: size * 0.2),
          if (showText) wordmark,
        ],
      );
    } else {
      logo = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LifeMateMark(size: size),
          if (showText) ...[
            SizedBox(height: size * 0.12),
            wordmark,
          ],
          if (tagline != null) ...[
            SizedBox(height: size * 0.08),
            Text(
              tagline!,
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                fontSize: math.max(12, size * 0.22),
              ),
            ),
          ],
        ],
      );
    }

    if (animate) {
      logo = logo
          .animate()
          .fadeIn(duration: 600.ms)
          .scale(begin: const Offset(0.9, 0.9), duration: 600.ms);
    }
    return logo;
  }
}
