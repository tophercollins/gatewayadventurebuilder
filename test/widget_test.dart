import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ttrpg_tracker/ui/screens/home_screen.dart';
import 'package:ttrpg_tracker/ui/screens/onboarding/onboarding_screen.dart';
import 'package:ttrpg_tracker/ui/screens/startup_screen.dart';

void main() {
  testWidgets('StartupScreen shows loading indicator', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: StartupScreen())),
    );

    // Startup screen shows app title while loading
    expect(find.text('TTRPG Session Tracker'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('HomeScreen shows main options', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: HomeScreen())),
    );

    // Home screen content is displayed
    expect(find.text('TTRPG Session Tracker'), findsOneWidget);
    expect(find.text('Continue Campaign'), findsOneWidget);
    expect(find.text('New Campaign'), findsOneWidget);
    expect(find.text('Review Sessions'), findsOneWidget);
  });

  testWidgets('OnboardingScreen shows welcome page', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: OnboardingScreen())),
    );

    await tester.pumpAndSettle();

    // Onboarding welcome page is displayed
    expect(find.text('Welcome to TTRPG Session Tracker'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('OnboardingScreen navigates through pages', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: OnboardingScreen())),
    );

    await tester.pumpAndSettle();

    // Start on welcome page
    expect(find.text('Welcome to TTRPG Session Tracker'), findsOneWidget);

    // Tap Next to go to page 2
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Record Your Sessions'), findsOneWidget);

    // Tap Next to go to page 3
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Automatic Transcription'), findsOneWidget);

    // Tap Next to go to page 4 (last page)
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('AI-Powered Insights'), findsOneWidget);

    // Last page shows action buttons
    expect(find.text('Create Your First Campaign'), findsOneWidget);
    expect(find.text('Skip for now'), findsOneWidget);
  });
}
