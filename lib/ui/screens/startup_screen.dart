import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../providers/onboarding_providers.dart';

/// Startup screen that checks onboarding state and redirects accordingly.
/// This screen is shown briefly while loading the onboarding completion state.
class StartupScreen extends ConsumerWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final onboardingState = ref.watch(onboardingCompletionProvider);

    return onboardingState.when(
      data: (hasCompleted) {
        // Navigate after the current frame to avoid build-time navigation
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            if (hasCompleted) {
              context.go(Routes.home);
            } else {
              context.go(Routes.onboarding);
            }
          }
        });
        return const _LoadingView();
      },
      loading: () => const _LoadingView(),
      error: (error, stack) {
        // On error, default to showing onboarding
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            context.go(Routes.onboarding);
          }
        });
        return const _LoadingView();
      },
    );
  }
}

/// Simple loading view shown during startup.
class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.auto_stories_outlined,
              size: 64,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text('TTRPG Session Tracker', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 32),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
