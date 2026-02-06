import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/theme_provider.dart';
import '../../theme/colors.dart';
import '../../theme/spacing.dart';

/// Base widget for onboarding pages with consistent styling.
class OnboardingPageContent extends StatelessWidget {
  const OnboardingPageContent({
    required this.icon,
    required this.title,
    required this.description,
    this.iconColor,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final contentWidth = screenWidth > Spacing.maxContentWidth
        ? Spacing.maxContentWidth
        : screenWidth;

    return Center(
      child: Container(
        width: contentWidth,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: (iconColor ?? theme.colorScheme.primary).withValues(
                  alpha: 0.1,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 56,
                color: iconColor ?? theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: Spacing.xl),
            // Title
            Text(
              title,
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.md),
            // Description
            Text(
              description,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Welcome page - first page of onboarding.
class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const OnboardingPageContent(
      icon: Icons.auto_stories_outlined,
      title: 'Welcome to History Check',
      description:
          'The easiest way to capture and remember everything that happens '
          'in your tabletop RPG sessions. Never lose track of NPCs, '
          'plot threads, or memorable moments again.',
    );
  }
}

/// Record page - explains audio recording feature.
class RecordPage extends StatelessWidget {
  const RecordPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OnboardingPageContent(
      icon: Icons.mic_outlined,
      iconColor: theme.brightness.recording,
      title: 'Record Your Sessions',
      description:
          'Simply press record when your session starts. The app captures '
          'everything locally on your device, even without an internet connection. '
          'Works for sessions of any length.',
    );
  }
}

/// Transcribe page - explains transcription feature.
class TranscribePage extends StatelessWidget {
  const TranscribePage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OnboardingPageContent(
      icon: Icons.text_snippet_outlined,
      iconColor: theme.brightness.processing,
      title: 'Automatic Transcription',
      description:
          'When your session ends, the app automatically transcribes the audio '
          'right on your device. No cloud uploads required. Your recordings '
          'stay private and secure.',
    );
  }
}

/// Insights page - explains AI analysis feature.
class InsightsPage extends StatelessWidget {
  const InsightsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return OnboardingPageContent(
      icon: Icons.auto_awesome_outlined,
      iconColor: theme.brightness.success,
      title: 'AI-Powered Insights',
      description:
          'Get automatic summaries, scene breakdowns, and entity extraction. '
          'The AI identifies NPCs, locations, items, and action items from your '
          'sessions, building a searchable database of your campaign world.',
    );
  }
}

/// Theme preference page - lets user pick light/dark/system on first launch.
class ThemePreferencePage extends ConsumerWidget {
  const ThemePreferencePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final contentWidth = screenWidth > Spacing.maxContentWidth
        ? Spacing.maxContentWidth
        : screenWidth;

    return Center(
      child: Container(
        width: contentWidth,
        padding: const EdgeInsets.symmetric(horizontal: Spacing.lg),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.palette_outlined,
                size: 56,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: Spacing.xl),
            Text(
              'Choose Your Theme',
              style: theme.textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.md),
            Text(
              'Pick a look that suits you. You can change this anytime in Settings.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Spacing.xl),
            SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.light,
                  icon: Icon(Icons.light_mode, size: 18),
                  label: Text('Light'),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  icon: Icon(Icons.dark_mode, size: 18),
                  label: Text('Dark'),
                ),
              ],
              selected: {themeMode},
              onSelectionChanged: (selected) {
                ref
                    .read(themeModeProvider.notifier)
                    .setThemeMode(selected.first);
              },
            ),
          ],
        ),
      ),
    );
  }
}
