import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../ui/screens/add_character_screen.dart';
import '../ui/screens/add_session_screen.dart';
import '../ui/screens/add_player_screen.dart';
import '../ui/screens/all_characters_screen.dart';
import '../ui/screens/all_players_screen.dart';
import '../ui/screens/campaign_home/campaign_home_screen.dart';
import '../ui/screens/campaigns_list_screen.dart';
import '../ui/screens/character_detail/character_detail_screen.dart';
import '../ui/screens/characters_list_screen.dart';
import '../ui/screens/home_screen.dart';
import '../ui/screens/item_detail_screen.dart';
import '../ui/screens/location_detail_screen.dart';
import '../ui/screens/monster_detail_screen.dart';
import '../ui/screens/organisation_detail_screen.dart';
import '../ui/screens/new_campaign_screen.dart';
import '../ui/screens/notification_settings/notification_settings_screen.dart';
import '../ui/screens/npc_detail/npc_detail_screen.dart';
import '../ui/screens/onboarding/onboarding_screen.dart';
import '../ui/screens/player_detail/player_detail_screen.dart';
import '../ui/screens/players_screen.dart';
import '../ui/screens/startup_screen.dart';
import '../ui/screens/post_session_screen.dart';
import '../ui/screens/recording_screen.dart';
import '../ui/screens/session_actions_screen.dart';
import '../ui/screens/session_detail_screen.dart';
import '../ui/screens/sessions_list_screen.dart';
import '../ui/screens/session_entities_screen.dart';
import '../ui/screens/session_players_screen.dart';
import '../ui/screens/session_setup_screen.dart';
import '../ui/screens/session_summary_screen.dart';
import '../ui/screens/session_transcript_screen.dart';
import '../ui/screens/stats/stats_screen.dart';
import '../ui/screens/world_database_screen.dart';
import '../ui/screens/worlds_screen.dart';
import '../ui/widgets/app_shell.dart';

/// Route paths for TTRPG Session Tracker.
/// Defined per APP_FLOW.md screen inventory.
abstract final class Routes {
  // Core
  static const String startup = '/startup';
  static const String home = '/';
  static const String onboarding = '/onboarding';
  static const String settings = '/settings';
  static const String notificationSettings = '/settings/notifications';
  static const String stats = '/stats';
  static const String worlds = '/worlds';
  static const String allPlayers = '/players';
  static const String allCharacters = '/characters';
  static const String playerDetail = '/players/:playerId';

  // Campaigns
  static const String campaigns = '/campaigns';
  static const String newCampaign = '/campaigns/new';
  static const String campaignHome = '/campaigns/:id';

  // Sessions
  static const String sessionsList = '/campaigns/:id/sessions';
  static const String newSession = '/campaigns/:id/sessions/new';
  static const String addSession = '/campaigns/:id/sessions/add';
  static const String recording = '/campaigns/:id/sessions/:sessionId/record';
  static const String postSession =
      '/campaigns/:id/sessions/:sessionId/complete';
  static const String sessionDetail = '/campaigns/:id/sessions/:sessionId';
  static const String sessionSummary =
      '/campaigns/:id/sessions/:sessionId/summary';
  static const String sessionEntities =
      '/campaigns/:id/sessions/:sessionId/entities';
  static const String sessionActions =
      '/campaigns/:id/sessions/:sessionId/actions';
  static const String sessionTranscript =
      '/campaigns/:id/sessions/:sessionId/transcript';
  static const String sessionPlayers =
      '/campaigns/:id/sessions/:sessionId/players';

  // World & Players
  static const String worldDatabase = '/campaigns/:id/world';
  static const String npcDetail = '/campaigns/:id/world/npcs/:npcId';
  static const String locationDetail =
      '/campaigns/:id/world/locations/:locationId';
  static const String itemDetail = '/campaigns/:id/world/items/:itemId';
  static const String monsterDetail =
      '/campaigns/:id/world/monsters/:monsterId';
  static const String organisationDetail =
      '/campaigns/:id/world/organisations/:organisationId';
  static const String players = '/campaigns/:id/players';
  static const String newPlayer = '/campaigns/:id/players/new';
  static const String characters = '/campaigns/:id/characters';
  static const String newCharacter = '/campaigns/:id/characters/new';
  static const String characterDetail =
      '/campaigns/:id/characters/:characterId';

  // Helper methods for building paths with parameters
  static String campaignPath(String id) => '/campaigns/$id';
  static String sessionsListPath(String campaignId) =>
      '/campaigns/$campaignId/sessions';
  static String newSessionPath(String campaignId) =>
      '/campaigns/$campaignId/sessions/new';
  static String addSessionPath(String campaignId) =>
      '/campaigns/$campaignId/sessions/add';
  static String recordingPath(String campaignId, String sessionId) =>
      '/campaigns/$campaignId/sessions/$sessionId/record';
  static String postSessionPath(String campaignId, String sessionId) =>
      '/campaigns/$campaignId/sessions/$sessionId/complete';
  static String sessionDetailPath(String campaignId, String sessionId) =>
      '/campaigns/$campaignId/sessions/$sessionId';
  static String sessionSummaryPath(String campaignId, String sessionId) =>
      '/campaigns/$campaignId/sessions/$sessionId/summary';
  static String sessionEntitiesPath(String campaignId, String sessionId) =>
      '/campaigns/$campaignId/sessions/$sessionId/entities';
  static String sessionActionsPath(String campaignId, String sessionId) =>
      '/campaigns/$campaignId/sessions/$sessionId/actions';
  static String sessionTranscriptPath(String campaignId, String sessionId) =>
      '/campaigns/$campaignId/sessions/$sessionId/transcript';
  static String sessionPlayersPath(String campaignId, String sessionId) =>
      '/campaigns/$campaignId/sessions/$sessionId/players';
  static String worldDatabasePath(String campaignId) =>
      '/campaigns/$campaignId/world';
  static String npcDetailPath(String campaignId, String npcId) =>
      '/campaigns/$campaignId/world/npcs/$npcId';
  static String locationDetailPath(String campaignId, String locationId) =>
      '/campaigns/$campaignId/world/locations/$locationId';
  static String itemDetailPath(String campaignId, String itemId) =>
      '/campaigns/$campaignId/world/items/$itemId';
  static String monsterDetailPath(String campaignId, String monsterId) =>
      '/campaigns/$campaignId/world/monsters/$monsterId';
  static String organisationDetailPath(
    String campaignId,
    String organisationId,
  ) => '/campaigns/$campaignId/world/organisations/$organisationId';
  static String playersPath(String campaignId) =>
      '/campaigns/$campaignId/players';
  static String newPlayerPath(String campaignId) =>
      '/campaigns/$campaignId/players/new';
  static String playerDetailPath(String playerId) => '/players/$playerId';
  static String charactersPath(String campaignId) =>
      '/campaigns/$campaignId/characters';
  static String newCharacterPath(String campaignId) =>
      '/campaigns/$campaignId/characters/new';
  static String characterDetailPath(String campaignId, String characterId) =>
      '/campaigns/$campaignId/characters/$characterId';
}

/// Creates a fresh GoRouter instance.
/// Use [initialLocation] to override the start route (e.g. for tests).
GoRouter createAppRouter({String initialLocation = Routes.startup}) {
  final rootKey = GlobalKey<NavigatorState>();
  final shellKey = GlobalKey<NavigatorState>();

  return GoRouter(
    navigatorKey: rootKey,
    initialLocation: initialLocation,
    routes: [
      // Startup - checks onboarding state and redirects
      GoRoute(
        path: Routes.startup,
        name: 'startup',
        parentNavigatorKey: rootKey,
        builder: (context, state) => const StartupScreen(),
      ),

      // Onboarding - outside shell (no sidebar)
      GoRoute(
        path: Routes.onboarding,
        name: 'onboarding',
        parentNavigatorKey: rootKey,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Main shell with sidebar
      ShellRoute(
        navigatorKey: shellKey,
        builder: (context, state, child) {
          final path = state.uri.path;
          final campaignId = extractCampaignId(path);

          return AppShell(
            currentPath: path,
            campaignId: campaignId,
            child: child,
          );
        },
        routes: [
          // Home
          GoRoute(
            path: Routes.home,
            name: 'home',
            pageBuilder: (context, state) => _buildPage(
              context: context,
              state: state,
              title: 'Home',
              child: const HomeScreen(),
            ),
          ),

          // Campaigns List
          GoRoute(
            path: Routes.campaigns,
            name: 'campaigns',
            pageBuilder: (context, state) => _buildPage(
              context: context,
              state: state,
              title: 'Campaigns',
              showBack: true,
              child: const CampaignsListScreen(),
            ),
          ),

          // New Campaign
          GoRoute(
            path: Routes.newCampaign,
            name: 'newCampaign',
            pageBuilder: (context, state) => _buildPage(
              context: context,
              state: state,
              title: 'New Campaign',
              showBack: true,
              child: const NewCampaignScreen(),
            ),
          ),

          // Settings
          GoRoute(
            path: Routes.settings,
            name: 'settings',
            redirect: (context, state) => Routes.notificationSettings,
          ),

          // Notification Settings
          GoRoute(
            path: Routes.notificationSettings,
            name: 'notificationSettings',
            pageBuilder: (context, state) => _buildPage(
              context: context,
              state: state,
              title: 'Notification Settings',
              showBack: true,
              child: const NotificationSettingsScreen(),
            ),
          ),

          // Stats
          GoRoute(
            path: Routes.stats,
            name: 'stats',
            pageBuilder: (context, state) => _buildPage(
              context: context,
              state: state,
              title: 'Stats',
              showBack: true,
              child: const StatsScreen(),
            ),
          ),

          // Global Worlds
          GoRoute(
            path: Routes.worlds,
            name: 'worlds',
            pageBuilder: (context, state) => _buildPage(
              context: context,
              state: state,
              title: 'Worlds',
              showBack: true,
              child: const WorldsScreen(),
            ),
          ),

          // Global Players
          GoRoute(
            path: Routes.allPlayers,
            name: 'allPlayers',
            pageBuilder: (context, state) => _buildPage(
              context: context,
              state: state,
              title: 'All Players',
              showBack: true,
              child: const AllPlayersScreen(),
            ),
          ),

          // Player Detail
          GoRoute(
            path: Routes.playerDetail,
            name: 'playerDetail',
            pageBuilder: (context, state) {
              final playerId = state.pathParameters['playerId']!;
              return _buildPage(
                context: context,
                state: state,
                title: 'Player',
                showBack: true,
                child: PlayerDetailScreen(playerId: playerId),
              );
            },
          ),

          // Global Characters
          GoRoute(
            path: Routes.allCharacters,
            name: 'allCharacters',
            pageBuilder: (context, state) => _buildPage(
              context: context,
              state: state,
              title: 'All Characters',
              showBack: true,
              child: const AllCharactersScreen(),
            ),
          ),

          // Campaign Home (with nested routes)
          GoRoute(
            path: Routes.campaignHome,
            name: 'campaignHome',
            pageBuilder: (context, state) {
              final id = state.pathParameters['id']!;
              return _buildPage(
                context: context,
                state: state,
                title: 'Campaign',
                showBack: true,
                child: CampaignHomeScreen(campaignId: id),
              );
            },
            routes: _campaignRoutes,
          ),
        ],
      ),
    ],
  );
}

/// Production router singleton.
final GoRouter appRouter = createAppRouter();

/// Campaign-level nested routes.
final List<RouteBase> _campaignRoutes = [
  // World Database
  GoRoute(
    path: 'world',
    name: 'worldDatabase',
    pageBuilder: (context, state) {
      final id = state.pathParameters['id']!;
      return _buildPage(
        context: context,
        state: state,
        title: 'World Database',
        showBack: true,
        child: WorldDatabaseScreen(campaignId: id),
      );
    },
    routes: [
      // NPC Detail
      GoRoute(
        path: 'npcs/:npcId',
        name: 'npcDetail',
        pageBuilder: (context, state) {
          final campaignId = state.pathParameters['id']!;
          final npcId = state.pathParameters['npcId']!;
          return _buildPage(
            context: context,
            state: state,
            title: 'NPC',
            showBack: true,
            child: NpcDetailScreen(campaignId: campaignId, npcId: npcId),
          );
        },
      ),
      // Location Detail
      GoRoute(
        path: 'locations/:locationId',
        name: 'locationDetail',
        pageBuilder: (context, state) {
          final campaignId = state.pathParameters['id']!;
          final locationId = state.pathParameters['locationId']!;
          return _buildPage(
            context: context,
            state: state,
            title: 'Location',
            showBack: true,
            child: LocationDetailScreen(
              campaignId: campaignId,
              locationId: locationId,
            ),
          );
        },
      ),
      // Item Detail
      GoRoute(
        path: 'items/:itemId',
        name: 'itemDetail',
        pageBuilder: (context, state) {
          final campaignId = state.pathParameters['id']!;
          final itemId = state.pathParameters['itemId']!;
          return _buildPage(
            context: context,
            state: state,
            title: 'Item',
            showBack: true,
            child: ItemDetailScreen(campaignId: campaignId, itemId: itemId),
          );
        },
      ),
      // Monster Detail
      GoRoute(
        path: 'monsters/:monsterId',
        name: 'monsterDetail',
        pageBuilder: (context, state) {
          final campaignId = state.pathParameters['id']!;
          final monsterId = state.pathParameters['monsterId']!;
          return _buildPage(
            context: context,
            state: state,
            title: 'Monster',
            showBack: true,
            child: MonsterDetailScreen(
              campaignId: campaignId,
              monsterId: monsterId,
            ),
          );
        },
      ),
      // Organisation Detail
      GoRoute(
        path: 'organisations/:organisationId',
        name: 'organisationDetail',
        pageBuilder: (context, state) {
          final campaignId = state.pathParameters['id']!;
          final organisationId = state.pathParameters['organisationId']!;
          return _buildPage(
            context: context,
            state: state,
            title: 'Organisation',
            showBack: true,
            child: OrganisationDetailScreen(
              campaignId: campaignId,
              organisationId: organisationId,
            ),
          );
        },
      ),
    ],
  ),

  // Players
  GoRoute(
    path: 'players',
    name: 'players',
    pageBuilder: (context, state) {
      final id = state.pathParameters['id']!;
      return _buildPage(
        context: context,
        state: state,
        title: 'Players/Characters',
        showBack: true,
        child: PlayersScreen(campaignId: id),
      );
    },
  ),

  // New Player
  GoRoute(
    path: 'players/new',
    name: 'newPlayer',
    pageBuilder: (context, state) {
      final id = state.pathParameters['id']!;
      return _buildPage(
        context: context,
        state: state,
        title: 'Add Player',
        showBack: true,
        child: AddPlayerScreen(campaignId: id),
      );
    },
  ),

  // Characters
  GoRoute(
    path: 'characters',
    name: 'characters',
    pageBuilder: (context, state) {
      final id = state.pathParameters['id']!;
      return _buildPage(
        context: context,
        state: state,
        title: 'Characters',
        showBack: true,
        child: CharactersListScreen(campaignId: id),
      );
    },
    routes: [
      // New Character (must come before :characterId)
      GoRoute(
        path: 'new',
        name: 'newCharacter',
        pageBuilder: (context, state) {
          final id = state.pathParameters['id']!;
          return _buildPage(
            context: context,
            state: state,
            title: 'Add Character',
            showBack: true,
            child: AddCharacterScreen(campaignId: id),
          );
        },
      ),
      // Character Detail
      GoRoute(
        path: ':characterId',
        name: 'characterDetail',
        pageBuilder: (context, state) {
          final campaignId = state.pathParameters['id']!;
          final characterId = state.pathParameters['characterId']!;
          return _buildPage(
            context: context,
            state: state,
            title: 'Character',
            showBack: true,
            child: CharacterDetailScreen(
              campaignId: campaignId,
              characterId: characterId,
            ),
          );
        },
      ),
    ],
  ),

  // Sessions List
  GoRoute(
    path: 'sessions',
    name: 'sessionsList',
    pageBuilder: (context, state) {
      final id = state.pathParameters['id']!;
      return _buildPage(
        context: context,
        state: state,
        title: 'Sessions',
        showBack: true,
        child: SessionsListScreen(campaignId: id),
      );
    },
  ),

  // New Session (Session Setup)
  GoRoute(
    path: 'sessions/new',
    name: 'newSession',
    pageBuilder: (context, state) {
      final id = state.pathParameters['id']!;
      return _buildPage(
        context: context,
        state: state,
        title: 'Session Setup',
        showBack: true,
        child: SessionSetupScreen(campaignId: id),
      );
    },
  ),

  // Manual Session Add
  GoRoute(
    path: 'sessions/add',
    name: 'addSession',
    pageBuilder: (context, state) {
      final id = state.pathParameters['id']!;
      return _buildPage(
        context: context,
        state: state,
        title: 'Add Session',
        showBack: true,
        child: AddSessionScreen(campaignId: id),
      );
    },
  ),

  // Session routes
  GoRoute(
    path: 'sessions/:sessionId',
    name: 'sessionDetail',
    pageBuilder: (context, state) {
      final id = state.pathParameters['id']!;
      final sessionId = state.pathParameters['sessionId']!;
      return _buildPage(
        context: context,
        state: state,
        title: 'Session',
        showBack: true,
        child: SessionDetailScreen(campaignId: id, sessionId: sessionId),
      );
    },
    routes: _sessionRoutes,
  ),
];

/// Session-level nested routes.
final List<RouteBase> _sessionRoutes = [
  // Recording
  GoRoute(
    path: 'record',
    name: 'recording',
    pageBuilder: (context, state) {
      final id = state.pathParameters['id']!;
      final sessionId = state.pathParameters['sessionId']!;
      return _buildPage(
        context: context,
        state: state,
        title: 'Recording',
        showBack: true,
        child: RecordingScreen(campaignId: id, sessionId: sessionId),
      );
    },
  ),

  // Post-Session
  GoRoute(
    path: 'complete',
    name: 'postSession',
    pageBuilder: (context, state) {
      final id = state.pathParameters['id']!;
      final sessionId = state.pathParameters['sessionId']!;
      return _buildPage(
        context: context,
        state: state,
        title: 'Session Complete',
        showBack: true,
        child: PostSessionScreen(campaignId: id, sessionId: sessionId),
      );
    },
  ),

  // Session Summary
  GoRoute(
    path: 'summary',
    name: 'sessionSummary',
    pageBuilder: (context, state) {
      final id = state.pathParameters['id']!;
      final sessionId = state.pathParameters['sessionId']!;
      return _buildPage(
        context: context,
        state: state,
        title: 'Summary',
        showBack: true,
        child: SessionSummaryScreen(campaignId: id, sessionId: sessionId),
      );
    },
  ),

  // Extracted Items
  GoRoute(
    path: 'entities',
    name: 'sessionEntities',
    pageBuilder: (context, state) {
      final id = state.pathParameters['id']!;
      final sessionId = state.pathParameters['sessionId']!;
      return _buildPage(
        context: context,
        state: state,
        title: 'Extracted Items',
        showBack: true,
        child: SessionEntitiesScreen(campaignId: id, sessionId: sessionId),
      );
    },
  ),

  // What's Next
  GoRoute(
    path: 'actions',
    name: 'sessionActions',
    pageBuilder: (context, state) {
      final id = state.pathParameters['id']!;
      final sessionId = state.pathParameters['sessionId']!;
      return _buildPage(
        context: context,
        state: state,
        title: "What's Next",
        showBack: true,
        child: SessionActionsScreen(campaignId: id, sessionId: sessionId),
      );
    },
  ),

  // Transcript
  GoRoute(
    path: 'transcript',
    name: 'sessionTranscript',
    pageBuilder: (context, state) {
      final id = state.pathParameters['id']!;
      final sessionId = state.pathParameters['sessionId']!;
      return _buildPage(
        context: context,
        state: state,
        title: 'Transcript',
        showBack: true,
        child: SessionTranscriptScreen(campaignId: id, sessionId: sessionId),
      );
    },
  ),

  // Player Moments
  GoRoute(
    path: 'players',
    name: 'sessionPlayers',
    pageBuilder: (context, state) {
      final id = state.pathParameters['id']!;
      final sessionId = state.pathParameters['sessionId']!;
      return _buildPage(
        context: context,
        state: state,
        title: 'Player Moments',
        showBack: true,
        child: SessionPlayersScreen(campaignId: id, sessionId: sessionId),
      );
    },
  ),
];

/// Builds a page with fade transition.
CustomTransitionPage<void> _buildPage({
  required BuildContext context,
  required GoRouterState state,
  required String title,
  required Widget child,
  bool showBack = false,
}) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(opacity: animation, child: child);
    },
  );
}
