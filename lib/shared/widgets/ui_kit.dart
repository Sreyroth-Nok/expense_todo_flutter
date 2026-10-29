import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Pill-shaped segmented tabs, e.g. All / Income / Expenses.
class PillTabs<T> extends StatelessWidget {
  const PillTabs({
    super.key,
    required this.options,
    required this.selected,
    required this.labelOf,
    required this.onSelected,
  });

  final List<T> options;
  final T selected;
  final String Function(T) labelOf;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          for (final option in options)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(option),
                child: Semantics(
                  selected: option == selected,
                  button: true,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: option == selected
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: option == selected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withAlpha(60),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      labelOf(option),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelLarge.copyWith(
                        color: option == selected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// One slice of a [DonutChart].
class DonutSlice {
  const DonutSlice(this.value, this.color);
  final double value;
  final Color color;
}

/// Ring chart with a widget in the middle (e.g. the total).
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.slices,
    this.size = 180,
    this.thickness = 26,
    this.center,
  });

  final List<DonutSlice> slices;
  final double size;
  final double thickness;
  final Widget? center;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _DonutPainter(slices, thickness),
          ),
          if (center != null)
            SizedBox(
              width: size - thickness * 2 - 12,
              child: center,
            ),
        ],
      ),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter(this.slices, this.thickness);

  final List<DonutSlice> slices;
  final double thickness;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(thickness / 2, thickness / 2,
        size.width - thickness, size.height - thickness);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = thickness;

    final total = slices.fold<double>(0, (s, e) => s + e.value);
    if (total <= 0) {
      canvas.drawArc(rect, 0, math.pi * 2, false,
          paint..color = AppColors.divider);
      return;
    }
    const gap = 0.025; // radians between slices
    var start = -math.pi / 2;
    for (final slice in slices) {
      final sweep = slice.value / total * math.pi * 2;
      final drawSweep = slices.length > 1 ? math.max(0.0, sweep - gap) : sweep;
      canvas.drawArc(rect, start, drawSweep, false, paint..color = slice.color);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) =>
      old.slices != slices || old.thickness != thickness;
}

/// Teal hills drawn along the bottom of the splash screen.
class WaveBackground extends StatelessWidget {
  const WaveBackground({super.key, this.height = 220});
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(painter: _WavePainter()),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    Path hill(double startY, double c1y, double c2y, double endY) => Path()
      ..moveTo(0, h * startY)
      ..cubicTo(w * 0.3, h * c1y, w * 0.65, h * c2y, w, h * endY)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();

    canvas.drawPath(
        hill(0.25, 0.05, 0.55, 0.2), Paint()..color = AppColors.softTeal);
    canvas.drawPath(hill(0.55, 0.35, 0.75, 0.45),
        Paint()..color = AppColors.primary.withAlpha(110));
    canvas.drawPath(
        hill(0.78, 0.62, 0.95, 0.7), Paint()..color = AppColors.primary);
    canvas.drawPath(
        hill(0.92, 0.85, 1.0, 0.88), Paint()..color = AppColors.primaryDark);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Small page dots for onboarding / splash.
class PageDots extends StatelessWidget {
  const PageDots({super.key, required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: i == index ? 20 : 7,
            height: 7,
            decoration: BoxDecoration(
              color: i == index ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

/// Round icon button with a label underneath (dashboard quick actions).
class RoundAction extends StatelessWidget {
  const RoundAction({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

/// Honey-colored primary button (used for "Save" and empty-state actions,
/// as in the design).
class HoneyButton extends StatelessWidget {
  const HoneyButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.honey,
        foregroundColor: AppColors.textPrimary,
        disabledBackgroundColor: AppColors.honey.withAlpha(120),
      ),
      child: isLoading
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                  strokeWidth: 2.5, color: AppColors.textPrimary),
            )
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: 8)],
                Text(label, style: AppTextStyles.buttonText),
              ],
            ),
    );
  }
}

/// Round check circle used in task and shopping lists.
class RoundCheck extends StatelessWidget {
  const RoundCheck({
    super.key,
    required this.checked,
    required this.onChanged,
    this.semanticLabel,
  });

  final bool checked;
  final ValueChanged<bool> onChanged;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      checked: checked,
      label: semanticLabel,
      button: true,
      child: InkResponse(
        onTap: () => onChanged(!checked),
        radius: 22,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: checked ? AppColors.primary : Colors.transparent,
              border: Border.all(
                color: checked ? AppColors.primary : AppColors.border,
                width: 2,
              ),
            ),
            child: checked
                ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                : null,
          ),
        ),
      ),
    );
  }
}
