import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/l10n/l10n.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../shared/widgets/ui_kit.dart';
import '../data/auth_repository.dart';

/// Splash screen — shown while the app determines the auth state.
///
/// After [_splashDuration], it evaluates:
///   1. Is the user authenticated?  → go to Home
///   2. Has onboarding been seen?   → go to Login
///   3. First launch                → go to Onboarding
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  static const _splashDuration = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(_splashDuration);
    if (!mounted) return;

    final user = ref.read(authRepositoryProvider).currentUser;
    if (user != null) {
      context.go(AppRoutes.home);
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

    if (!mounted) return;
    context.go(onboardingComplete ? AppRoutes.login : AppRoutes.onboarding);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Align(
            alignment: Alignment.bottomCenter,
            child: WaveBackground(height: 240),
          ),
          Align(
            alignment: const Alignment(0, -0.2),
            child: AppLogo(
              size: 84,
              tagline: context.l10n.appTagline,
              animate: true,
            ),
          ),
          Align(
            alignment: const Alignment(0, 0.92),
            child: const _LoadingDots()
                .animate()
                .fadeIn(delay: 400.ms, duration: 400.ms),
          ),
        ],
      ),
    );
  }
}

/// Three pulsing dots (honey / white) on the wave.
class _LoadingDots extends StatelessWidget {
  const _LoadingDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == 0 ? AppColors.honey : Colors.white,
              shape: BoxShape.circle,
            ),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scale(
                delay: (i * 180).ms,
                duration: 500.ms,
                begin: const Offset(0.7, 0.7),
                end: const Offset(1.15, 1.15),
              ),
      ],
    );
  }
}
