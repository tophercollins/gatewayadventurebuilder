import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes.dart';
import 'providers/theme_provider.dart';
import 'ui/theme/app_theme.dart';
import 'ui/widgets/notification_listener.dart' as app_notifications;

/// Root application widget with theming and routing.
class HistoryCheckApp extends ConsumerWidget {
  const HistoryCheckApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'History Check',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        return app_notifications.NotificationListener(
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
