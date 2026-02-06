import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../../providers/onboarding_providers.dart';
import 'onboarding_controls.dart';
import 'onboarding_pages.dart';

/// First-time user onboarding screen.
/// Shows a PageView with welcome and feature highlights.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    ref.read(onboardingPageProvider.notifier).setPage(page);
  }

  void _goToPage(int page) {
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _nextPage() {
    final currentPage = ref.read(onboardingPageProvider);
    if (currentPage < totalOnboardingPages - 1) {
      _goToPage(currentPage + 1);
    }
  }

  Future<void> _completeOnboarding({bool goToNewCampaign = false}) async {
    await ref.read(onboardingCompletionProvider.notifier).completeOnboarding();
    if (mounted) {
      if (goToNewCampaign) {
        context.go(Routes.newCampaign);
      } else {
        context.go(Routes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentPage = ref.watch(onboardingPageProvider);
    final isLastPage = currentPage == totalOnboardingPages - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button row
            OnboardingSkipButton(
              isLastPage: isLastPage,
              onSkip: () => _completeOnboarding(),
            ),
            // Page content
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                children: const [
                  WelcomePage(),
                  RecordPage(),
                  TranscribePage(),
                  InsightsPage(),
                  ThemePreferencePage(),
                ],
              ),
            ),
            // Bottom controls
            OnboardingBottomControls(
              currentPage: currentPage,
              isLastPage: isLastPage,
              onNext: _nextPage,
              onGetStarted: () => _completeOnboarding(goToNewCampaign: true),
              onSkipForNow: () => _completeOnboarding(),
              onDotTap: _goToPage,
            ),
          ],
        ),
      ),
    );
  }
}
