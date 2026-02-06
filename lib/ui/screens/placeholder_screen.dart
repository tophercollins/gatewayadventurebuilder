import 'package:flutter/material.dart';

import '../theme/spacing.dart';

/// Placeholder screen for route verification.
/// Each screen displays its name and route path.
/// Will be replaced with actual screen implementations in later phases.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    required this.title,
    required this.route,
    super.key,
  });

  final String title;
  final String route;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: theme.textTheme.headlineLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.md),
              Text(
                route,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontFamily: 'monospace',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: Spacing.xl),
              Text(
                'Placeholder Screen',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
