import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ttrpg_tracker/app.dart';

void main() {
  testWidgets('App renders home screen', (WidgetTester tester) async {
    // Set a desktop-sized window for the test
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(
      const ProviderScope(child: TTRPGTrackerApp()),
    );

    // Home screen content is displayed (actual HomeScreen now)
    expect(find.text('TTRPG Session Tracker'), findsOneWidget);
    expect(find.text('Continue Campaign'), findsOneWidget);
    expect(find.text('New Campaign'), findsOneWidget);
    expect(find.text('Review Sessions'), findsOneWidget);

    // Sidebar is visible on desktop
    expect(find.text('TTRPG Tracker'), findsOneWidget);
  });
}
