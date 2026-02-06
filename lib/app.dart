import 'package:flutter/material.dart';

import 'config/routes.dart';
import 'ui/theme/app_theme.dart';

/// Root application widget with theming and routing.
class TTRPGTrackerApp extends StatelessWidget {
  const TTRPGTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'TTRPG Session Tracker',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
