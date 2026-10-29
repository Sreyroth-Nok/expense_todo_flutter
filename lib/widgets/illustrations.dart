import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Simple illustrations built from shapes and icons, in the Deep Teal +
/// Honey palette. They need no image files and scale to any size.
///
/// Swap them for professional artwork later (e.g. SVGs in assets/images/)
/// without changing the screens: each screen only uses these widgets.

/// Soft teal circle with a few decorative dots and leaves behind [child].
class ArtCircle extends StatelessWidget {
  const ArtCircle({super.key, required this.child, this.size = 200});

  final Widget child;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.86,
            height: size * 0.86,
            decoration: const BoxDecoration(
              color: AppColors.softTeal,
              shape: BoxShape.circle,
            ),
          ),
          _dot(size, 0.08, 0.18, AppColors.honey, 0.05),
          _dot(size, 0.86, 0.12, AppColors.primary, 0.035),
          _dot(size, 0.9, 0.7, AppColors.honey, 0.04),
          _dot(size, 0.1, 0.78, AppColors.primary.withAlpha(120), 0.03),
          Positioned(
            left: size * 0.02,
            bottom: size * 0.08,
            child: Transform.rotate(
              angle: -0.6,
              child: Icon(Icons.eco_rounded,
                  size: size * 0.18, color: AppColors.primary.withAlpha(150)),
            ),
          ),
          Positioned(
            right: size * 0.02,
            top: size * 0.26,
            child: Transform.rotate(
              angle: 0.5,
              child: Icon(Icons.eco_rounded,
                  size: size * 0.14, color: AppColors.honey.withAlpha(200)),
            ),
          ),
          child,
        ],
      ),
    );
  }

  Widget _dot(double size, double x, double y, Color color, double r) {
    return Positioned(
      left: size * x,
      top: size * y,
      child: Container(
        width: size * r,
        height: size * r,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
    );
  }
}

/// White rounded "card" used inside illustrations.
class _ArtCard extends StatelessWidget {
  const _ArtCard({required this.width, required this.height, required this.child});

  final double width;
  final double height;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(width * 0.12),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryDark.withAlpha(30),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}

/// Phone with a small bar chart and a honey coin — "manage your money".
class FinanceArt extends StatelessWidget {
  const FinanceArt({super.key, this.size = 220});
  final double size;

  @override
  Widget build(BuildContext context) {
    final w = size * 0.42;
    return ArtCircle(
      size: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _ArtCard(
            width: w,
            height: w * 1.55,
            child: Padding(
              padding: EdgeInsets.all(w * 0.12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: w * 0.08,
                    width: w * 0.5,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      for (final (h, c) in [
                        (0.35, AppColors.primary.withAlpha(120)),
                        (0.6, AppColors.primary),
                        (0.45, AppColors.honey),
                        (0.8, AppColors.primaryDark),
                      ])
                        Container(
                          width: w * 0.13,
                          height: w * h,
                          decoration: BoxDecoration(
                            color: c,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: -w * 0.35,
            top: w * 0.18,
            child: _Coin(size: w * 0.5),
          ),
        ],
      ),
    );
  }
}

class _Coin extends StatelessWidget {
  const _Coin({required this.size});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.honey,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: size * 0.07),
        boxShadow: [
          BoxShadow(color: AppColors.honey.withAlpha(90), blurRadius: 12),
        ],
      ),
      child: Center(
        child: Text(
          '\$',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: size * 0.48,
          ),
        ),
      ),
    );
  }
}

/// Calendar card with a honey check badge — "plan your day".
class PlannerArt extends StatelessWidget {
  const PlannerArt({super.key, this.size = 220});
  final double size;

  @override
  Widget build(BuildContext context) {
    final w = size * 0.52;
    return ArtCircle(
      size: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _ArtCard(
            width: w,
            height: w * 0.95,
            child: Column(
              children: [
                Container(
                  height: w * 0.22,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(w * 0.12)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(w * 0.08),
                    child: GridView.count(
                      crossAxisCount: 4,
                      mainAxisSpacing: w * 0.05,
                      crossAxisSpacing: w * 0.05,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        for (var i = 0; i < 12; i++)
                          Container(
                            decoration: BoxDecoration(
                              color: i == 6
                                  ? AppColors.honey
                                  : AppColors.softTeal,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: -w * 0.18,
            bottom: -w * 0.16,
            child: Container(
              width: w * 0.42,
              height: w * 0.42,
              decoration: BoxDecoration(
                color: AppColors.honey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Icon(Icons.check_rounded,
                  color: Colors.white, size: w * 0.26),
            ),
          ),
        ],
      ),
    );
  }
}

/// Piggy bank with coins — savings.
class SavingsArt extends StatelessWidget {
  const SavingsArt({super.key, this.size = 160});
  final double size;

  @override
  Widget build(BuildContext context) {
    return ArtCircle(
      size: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(Icons.savings_rounded, size: size * 0.5, color: AppColors.primary),
          Positioned(
            right: -size * 0.04,
            top: -size * 0.02,
            child: _Coin(size: size * 0.2),
          ),
        ],
      ),
    );
  }
}

/// Clipboard with check marks — used for empty states.
class EmptyListArt extends StatelessWidget {
  const EmptyListArt({super.key, this.size = 160, this.icon});
  final double size;

  /// Optional feature icon shown in the badge.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final w = size * 0.4;
    return ArtCircle(
      size: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          _ArtCard(
            width: w,
            height: w * 1.25,
            child: Padding(
              padding: EdgeInsets.all(w * 0.14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  for (var i = 0; i < 3; i++)
                    Row(
                      children: [
                        Icon(Icons.check_box_rounded,
                            size: w * 0.18,
                            color: i == 2 ? AppColors.border : AppColors.primary),
                        SizedBox(width: w * 0.06),
                        Expanded(
                          child: Container(
                            height: w * 0.06,
                            decoration: BoxDecoration(
                              color: AppColors.border,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          if (icon != null)
            Positioned(
              right: -w * 0.3,
              bottom: -w * 0.1,
              child: Container(
                width: w * 0.5,
                height: w * 0.5,
                decoration: BoxDecoration(
                  color: AppColors.honey,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                ),
                child: Icon(icon, color: Colors.white, size: w * 0.26),
              ),
            ),
        ],
      ),
    );
  }
}

/// Big check mark with confetti — success screens.
class SuccessArt extends StatelessWidget {
  const SuccessArt({super.key, this.size = 180});
  final double size;

  @override
  Widget build(BuildContext context) {
    final rnd = math.Random(7);
    final confetti = [
      for (var i = 0; i < 14; i++)
        (
          rnd.nextDouble(),
          rnd.nextDouble(),
          i.isEven ? AppColors.honey : AppColors.primary,
          rnd.nextDouble() * math.pi,
        ),
    ];
    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          for (final (x, y, color, angle) in confetti)
            Positioned(
              left: size * (0.05 + x * 0.85),
              top: size * (0.05 + y * 0.85),
              child: Transform.rotate(
                angle: angle,
                child: Container(
                  width: size * 0.05,
                  height: size * 0.025,
                  decoration: BoxDecoration(
                    color: color.withAlpha(200),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          Container(
            width: size * 0.62,
            height: size * 0.62,
            decoration: const BoxDecoration(
              color: AppColors.softTeal,
              shape: BoxShape.circle,
            ),
          ),
          Container(
            width: size * 0.46,
            height: size * 0.46,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded,
                color: Colors.white, size: size * 0.3),
          ),
        ],
      ),
    );
  }
}
