import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:ttrpg_tracker/config/routes.dart';

import 'test_helpers/test_app.dart';

void main() {
  late Database db;

  setUp(() async {
    db = await setUpTestEnvironment();
  });

  tearDown(() async {
    await tearDownTestEnvironment(db);
  });

  testWidgets('Creating a new campaign', (WidgetTester tester) async {
    // Set desktop viewport
    tester.view.physicalSize = const Size(1280, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    // 1. Pump app at home
    await tester.pumpWidget(buildTestApp(initialLocation: Routes.home));
    await tester.pumpAndSettle();

    // 2. Verify home screen shows (may appear in both header and sidebar)
    expect(find.text('History Check'), findsWidgets);

    // 3. Verify empty state shows "Start Your First Campaign"
    expect(find.text('Start Your First Campaign'), findsOneWidget);

    // 4. Tap "Start Your First Campaign" card
    await tester.tap(find.byKey(const Key('home_startFirstCampaign')));
    await tester.pumpAndSettle();

    // 5. Verify New Campaign form loads
    expect(find.text('Campaign Name'), findsOneWidget);
    expect(find.text('Game System'), findsOneWidget);

    // 6. Enter campaign name
    await tester.enterText(
      find.byKey(const Key('newCampaign_name')),
      'Curse of Strahd',
    );

    // 7. Tap game system dropdown and select D&D 5e
    await tester.tap(find.byKey(const Key('newCampaign_gameSystem')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dungeons & Dragons 5e / 5.5e').last);
    await tester.pumpAndSettle();

    // 8. Tap dropdown again and select "Other"
    await tester.tap(find.byKey(const Key('newCampaign_gameSystem')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Other').last);
    await tester.pumpAndSettle();

    // 9. Verify custom game system field appears
    expect(find.byKey(const Key('newCampaign_customGameSystem')), findsOneWidget);

    // 10. Enter custom game system
    await tester.enterText(
      find.byKey(const Key('newCampaign_customGameSystem')),
      'Homebrew D&D',
    );

    // 11. Enter description
    await tester.enterText(
      find.byKey(const Key('newCampaign_description')),
      'A gothic horror campaign in the dread domain of Barovia.',
    );

    // 12. Tap import toggle to expand import section
    await tester.tap(find.byKey(const Key('newCampaign_importToggle')));
    await tester.pumpAndSettle();

    // 13. Enter import text
    expect(find.byKey(const Key('newCampaign_importText')), findsOneWidget);
    await tester.enterText(
      find.byKey(const Key('newCampaign_importText')),
      'Strahd von Zarovich is the vampire lord of Barovia.',
    );

    // 14. Scroll to and tap "Create Campaign" button
    await tester.ensureVisible(find.byKey(const Key('newCampaign_create')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('newCampaign_create')));
    await tester.pumpAndSettle();

    // 15-17. Verify navigation to CampaignHomeScreen with campaign name
    expect(find.text('Curse of Strahd'), findsOneWidget);
  });
}
