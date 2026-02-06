import 'package:flutter/material.dart';

import '../../theme/spacing.dart';

/// Number of pages in the onboarding flow.
const int totalOnboardingPages = 5;

/// Skip button that appears at top right of onboarding.
class OnboardingSkipButton extends StatelessWidget {
  const OnboardingSkipButton({
    required this.isLastPage,
    required this.onSkip,
    super.key,
  });

  final bool isLastPage;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    // Hide skip button on last page (Get Started is there)
    if (isLastPage) {
      return const SizedBox(height: Spacing.xxl);
    }

    return Container(
      height: Spacing.xxl,
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
      child: TextButton(onPressed: onSkip, child: const Text('Skip')),
    );
  }
}

/// Bottom controls with progress dots and navigation buttons.
class OnboardingBottomControls extends StatelessWidget {
  const OnboardingBottomControls({
    required this.currentPage,
    required this.isLastPage,
    required this.onNext,
    required this.onGetStarted,
    required this.onSkipForNow,
    required this.onDotTap,
    super.key,
  });

  final int currentPage;
  final bool isLastPage;
  final VoidCallback onNext;
  final VoidCallback onGetStarted;
  final VoidCallback onSkipForNow;
  final ValueChanged<int> onDotTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress dots
          OnboardingProgressDots(
            currentPage: currentPage,
            totalPages: totalOnboardingPages,
            onDotTap: onDotTap,
          ),
          const SizedBox(height: Spacing.lg),
          // Action button
          SizedBox(
            width: double.infinity,
            child: isLastPage
                ? ElevatedButton(
                    onPressed: onGetStarted,
                    child: const Text('Create Your First Campaign'),
                  )
                : ElevatedButton(onPressed: onNext, child: const Text('Next')),
          ),
          if (isLastPage) ...[
            const SizedBox(height: Spacing.sm),
            TextButton(
              onPressed: onSkipForNow,
              child: const Text('Skip for now'),
            ),
          ],
        ],
      ),
    );
  }
}

/// Progress dots indicator.
class OnboardingProgressDots extends StatelessWidget {
  const OnboardingProgressDots({
    required this.currentPage,
    required this.totalPages,
    required this.onDotTap,
    super.key,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onDotTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        totalPages,
        (index) => GestureDetector(
          onTap: () => onDotTap(index),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: Spacing.xs),
            width: index == currentPage ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: index == currentPage
                  ? theme.colorScheme.primary
                  : theme.colorScheme.outline,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}
