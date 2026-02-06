import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/routes.dart';
import 'ui/theme/app_theme.dart';
import 'ui/widgets/notification_listener.dart' as app_notifications;

/// Root application widget with theming and routing.
class TTRPGTrackerApp extends ConsumerWidget {
  const TTRPGTrackerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return app_notifications.NotificationListener(
      child: MaterialApp.router(
        title: 'TTRPG Session Tracker',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        routerConfig: appRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
