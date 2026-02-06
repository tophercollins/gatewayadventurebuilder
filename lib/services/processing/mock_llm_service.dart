import 'llm_response_models.dart';
import 'llm_service.dart';

/// Mock LLM service for testing without API calls.
/// Returns realistic structured data based on generic TTRPG sessions.
class MockLLMService implements LLMService {
  MockLLMService({
    this.simulateDelay = true,
    this.delayDuration = const Duration(milliseconds: 500),
    this.shouldFail = false,
    this.failureMessage = 'Simulated failure',
  });

  /// Whether to simulate network delay.
  final bool simulateDelay;

  /// How long to delay.
  final Duration delayDuration;

  /// Whether all calls should fail.
  final bool shouldFail;

  /// Error message when failing.
  final String failureMessage;

  Future<void> _delay() async {
    if (simulateDelay) {
      await Future.delayed(delayDuration);
    }
  }

  @override
  Future<bool> isAvailable() async => true;

  @override
  Future<LLMResult<String>> generateText({required String prompt}) async {
    await _delay();
    if (shouldFail) {
      return LLMResult.failure(failureMessage);
    }
    return const LLMResult.success('Mock generated text response.');
  }

  @override
  Future<LLMResult<SummaryResponse>> generateSummary({
    required String transcript,
    required String prompt,
  }) async {
    await _delay();
    if (shouldFail) {
      return LLMResult.failure(failureMessage);
    }
    return const LLMResult.success(SummaryResponse(
      overallSummary: '''The party gathered at the Rusty Tankard tavern to '''
          '''discuss their next moves. After reviewing the map provided by '''
          '''Merchant Theron, they decided to venture into the Shadowfen '''
          '''Marshes in search of the lost temple. The journey was fraught '''
          '''with danger as they encountered a band of goblin raiders near '''
          '''the Old Mill.\n\n'''
          '''Combat was fierce but the party prevailed, with the fighter '''
          '''landing a critical blow on the goblin chieftain. They rescued '''
          '''a captured merchant who revealed valuable information about '''
          '''the temple's location. The session ended with the party making '''
          '''camp at the edge of the marshes, preparing for the dangers ahead.''',
    ));
  }

  @override
  Future<LLMResult<ScenesResponse>> extractScenes({
    required String transcript,
    required String prompt,
  }) async {
    await _delay();
    if (shouldFail) {
      return LLMResult.failure(failureMessage);
    }
    return const LLMResult.success(ScenesResponse(scenes: [
      SceneData(
        title: 'Tavern Planning',
        summary: 'The party met at the Rusty Tankard to plan their expedition.',
        startTimeMs: 0,
        endTimeMs: 1800000,
      ),
      SceneData(
        title: 'Journey to the Marshes',
        summary: 'Travel montage with minor encounters on the road.',
        startTimeMs: 1800000,
        endTimeMs: 3600000,
      ),
      SceneData(
        title: 'Goblin Ambush',
        summary: 'Combat encounter with goblin raiders at the Old Mill.',
        startTimeMs: 3600000,
        endTimeMs: 7200000,
      ),
      SceneData(
        title: 'Merchant Rescue',
        summary: 'Freed a captured merchant who provided quest information.',
        startTimeMs: 7200000,
        endTimeMs: 9000000,
      ),
      SceneData(
        title: 'Making Camp',
        summary: 'The party set up camp and prepared for the marshes.',
        startTimeMs: 9000000,
        endTimeMs: 10800000,
      ),
    ]));
  }

  @override
  Future<LLMResult<EntitiesResponse>> extractEntities({
    required String transcript,
    required String prompt,
  }) async {
    await _delay();
    if (shouldFail) {
      return LLMResult.failure(failureMessage);
    }
    return const LLMResult.success(EntitiesResponse(
      npcs: [
        NpcData(
          name: 'Barkeep Mira',
          description: 'A cheerful halfling woman who runs the Rusty Tankard.',
          role: 'merchant',
          context: 'Served the party drinks and shared local rumors.',
        ),
        NpcData(
          name: 'Merchant Theron',
          description: 'An elderly human with a weathered face and keen eyes.',
          role: 'quest_giver',
          context: 'Provided the map and quest to find the lost temple.',
        ),
        NpcData(
          name: 'Grubnash the Goblin Chief',
          description: 'A scarred goblin with a crude iron crown.',
          role: 'enemy',
          context: 'Led the ambush at the Old Mill, defeated in combat.',
        ),
        NpcData(
          name: 'Marcus the Merchant',
          description: 'A middle-aged trader from the southern cities.',
          role: 'ally',
          context: 'Rescued from the goblins, grateful to the party.',
        ),
      ],
      locations: [
        LocationData(
          name: 'The Rusty Tankard',
          description: 'A cozy tavern known for its warm hearth and cold ale.',
          locationType: 'tavern',
          context: 'Starting location where the party planned their journey.',
        ),
        LocationData(
          name: 'Shadowfen Marshes',
          description: 'A dangerous swamp rumored to hide an ancient temple.',
          locationType: 'wilderness',
          context: 'Destination of the party\'s quest.',
        ),
        LocationData(
          name: 'The Old Mill',
          description: 'An abandoned mill on the road, now a goblin hideout.',
          locationType: 'dungeon',
          context: 'Site of the goblin ambush and merchant rescue.',
        ),
      ],
      items: [
        ItemData(
          name: 'Theron\'s Map',
          description: 'A weathered parchment showing the route to the temple.',
          itemType: 'quest_item',
          context: 'Given by Merchant Theron at the start of the quest.',
        ),
        ItemData(
          name: 'Chieftain\'s Crown',
          description: 'A crude iron crown worn by the goblin chief.',
          itemType: 'treasure',
          context: 'Looted from Grubnash after the battle.',
        ),
      ],
    ));
  }

  @override
  Future<LLMResult<ActionItemsResponse>> extractActionItems({
    required String transcript,
    required String prompt,
  }) async {
    await _delay();
    if (shouldFail) {
      return LLMResult.failure(failureMessage);
    }
    return const LLMResult.success(ActionItemsResponse(actionItems: [
      ActionItemData(
        title: 'Find the Lost Temple in Shadowfen Marshes',
        description: 'Navigate the marshes and locate the ancient temple.',
        actionType: 'plot_thread',
      ),
      ActionItemData(
        title: 'Return Theron\'s map after the quest',
        description: 'Promised to return the map once the temple is found.',
        actionType: 'action_item',
      ),
      ActionItemData(
        title: 'Investigate the goblin presence',
        description: 'Why are goblins organized under a chieftain here?',
        actionType: 'hook',
      ),
      ActionItemData(
        title: 'Check on Marcus\'s family',
        description: 'Marcus asked the party to visit his family in town.',
        actionType: 'follow_up',
      ),
    ]));
  }

  @override
  Future<LLMResult<PlayerMomentsResponse>> extractPlayerMoments({
    required String transcript,
    required String prompt,
  }) async {
    await _delay();
    if (shouldFail) {
      return LLMResult.failure(failureMessage);
    }
    return const LLMResult.success(PlayerMomentsResponse(moments: [
      PlayerMomentData(
        playerName: 'Alex',
        characterName: 'Thorin Ironforge',
        description: 'Landed a critical hit on the goblin chieftain.',
        momentType: 'combat',
      ),
      PlayerMomentData(
        playerName: 'Sam',
        characterName: 'Elara Moonwhisper',
        description: 'Convinced Barkeep Mira to share secret information.',
        momentType: 'roleplay',
      ),
      PlayerMomentData(
        playerName: 'Jordan',
        characterName: 'Zephyr',
        description: '"I didn\'t choose the rogue life, the rogue life chose me"',
        momentType: 'quote',
        quoteText: 'I didn\'t choose the rogue life, the rogue life chose me',
      ),
      PlayerMomentData(
        playerName: 'Taylor',
        characterName: 'Brother Marcus',
        description: 'Made the difficult choice to spare the surrendering goblins.',
        momentType: 'decision',
      ),
    ]));
  }
}
