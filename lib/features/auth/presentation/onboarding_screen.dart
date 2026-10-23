import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/app_button.dart';
import '../../../shared/widgets/app_logo.dart';
import '../../../core/l10n/l10n.dart';

/// Data model for each onboarding page.
class _OnboardingPage {
  const _OnboardingPage({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
}

List<_OnboardingPage> _pagesFor(AppLocalizations l) => [
  _OnboardingPage(
    icon: Icons.account_balance_wallet_rounded,
    title: l.onboardingTitle1,
    subtitle: l.onboardingBody1,
    color: AppColors.primary,
  ),
  _OnboardingPage(
    icon: Icons.task_alt_rounded,
    title: l.onboardingTitle2,
    subtitle: l.onboardingBody2,
    color: AppColors.honey,
  ),
  _OnboardingPage(
    icon: Icons.shopping_cart_rounded,
    title: l.onboardingTitle3,
    subtitle: l.onboardingBody3,
    color: AppColors.success,
  ),
];

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  List<_OnboardingPage> get _pages => _pagesFor(context.l10n);

  final _controller = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (mounted) context.go(AppRoutes.login);
  }

  void _next() {
    if (_currentPage < _pages.length - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Skip button ──────────────────────────────────────
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 16),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    l.onboardingSkip,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),

            // ── Pages ────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return _OnboardingPageView(page: page);
                },
              ),
            ),

            // ── Dots ─────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: _currentPage == i ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    color: _currentPage == i
                        ? AppColors.primary
                        : AppColors.border,
                  ),
                );
              }),
            ),

            const Gap(32),

            // ── CTA buttons ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  AppPrimaryButton(
                    label: isLast ? l.onboardingGetStarted : l.onboardingNext,
                    onPressed: _next,
                    icon: isLast ? Icons.arrow_forward_rounded : null,
                  ),
                  const Gap(12),
                  if (isLast)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${l.authAlreadyHaveAccount}  ',
                          style: AppTextStyles.bodySmall,
                        ),
                        AppTextLinkButton(
                          label: l.authLogIn,
                          onPressed: () => context.go(AppRoutes.login),
                        ),
                      ],
                    ),
                ],
              ),
            ),

            const Gap(24),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageView extends StatelessWidget {
  const _OnboardingPageView({required this.page});

  final _OnboardingPage page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // ── Illustration container ───────────────────────────
          Container(
            width: 180,
            height: 180,
            decoration: BoxDecoration(
              color: page.color.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 88,
              color: page.color,
            ),
          )
              .animate()
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.8, 0.8), duration: 500.ms),

          const Gap(40),

          // ── Logo ─────────────────────────────────────────────
          const AppLogo(size: 36, showText: false),

          const Gap(24),

          // ── Title ────────────────────────────────────────────
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineLarge,
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

          const Gap(16),

          // ── Subtitle ─────────────────────────────────────────
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.6,
            ),
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
        ],
      ),
    );
  }
}
