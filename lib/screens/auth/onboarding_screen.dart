import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../l10n/l10n.dart';
import '../../routing/app_routes.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../widgets/app_button.dart';
import '../../widgets/illustrations.dart';
import '../../widgets/ui_kit.dart';

class _OnboardingPage {
  const _OnboardingPage({
    required this.art,
    required this.title,
    required this.subtitle,
  });

  final Widget art;
  final String title;
  final String subtitle;
}

List<_OnboardingPage> _pagesFor(AppLocalizations l) => [
      _OnboardingPage(
        art: const FinanceArt(size: 240),
        title: l.onboardingTitle1,
        subtitle: l.onboardingBody1,
      ),
      _OnboardingPage(
        art: const PlannerArt(size: 240),
        title: l.onboardingTitle2,
        subtitle: l.onboardingBody2,
      ),
      _OnboardingPage(
        art: const SavingsArt(size: 240),
        title: l.onboardingTitle3,
        subtitle: l.onboardingBody3,
      ),
    ];

/// Three intro pages: finance, planner, savings. Shown once.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
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

  void _next(int count) {
    if (_currentPage < count - 1) {
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
    final pages = _pagesFor(l);
    final isLast = _currentPage == pages.length - 1;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 12),
                child: TextButton(
                  onPressed: _finish,
                  child: Text(
                    l.onboardingSkip,
                    style: AppTextStyles.labelLarge
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, index) =>
                    _OnboardingPageView(page: pages[index]),
              ),
            ),
            PageDots(count: pages.length, index: _currentPage),
            const Gap(28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: AppPrimaryButton(
                label: isLast ? l.onboardingGetStarted : l.onboardingNext,
                onPressed: () => _next(pages.length),
              ),
            ),
            const Gap(8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l.authAlreadyHaveAccount, style: AppTextStyles.bodySmall),
                TextButton(
                  onPressed: () => context.go(AppRoutes.login),
                  child: Text(l.authLogIn),
                ),
              ],
            ),
            const Gap(12),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Gap(12),
          page.art
              .animate()
              .fadeIn(duration: 450.ms)
              .scale(begin: const Offset(0.92, 0.92), duration: 450.ms),
          const Gap(32),
          Text(
            page.title,
            style: AppTextStyles.displayMedium.copyWith(
              fontSize: 26,
              color: AppColors.primaryDark,
              height: 1.25,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 120.ms),
          const Gap(14),
          Text(
            page.subtitle,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.textSecondary,
              height: 1.55,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 220.ms),
        ],
      ),
    );
  }
}
