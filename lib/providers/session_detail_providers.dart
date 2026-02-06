import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/action_item.dart';
import '../data/models/entity_appearance.dart';
import '../data/models/item.dart';
import '../data/models/location.dart';
import '../data/models/npc.dart';
import '../data/models/player.dart';
import '../data/models/player_moment.dart';
import '../data/models/scene.dart';
import '../data/models/session.dart';
import '../data/models/session_summary.dart';
import 'processing_providers.dart';
import 'repository_providers.dart';

/// Aggregated session detail data for the Session Detail screen.
class SessionDetailData {
  const SessionDetailData({
    required this.session,
    this.summary,
    required this.scenes,
    required this.npcs,
    required this.locations,
    required this.items,
    required this.actionItems,
    required this.playerMoments,
    required this.players,
  });

  final Session session;
  final SessionSummary? summary;
  final List<Scene> scenes;
  final List<Npc> npcs;
  final List<Location> locations;
  final List<Item> items;
  final List<ActionItem> actionItems;
  final List<PlayerMoment> playerMoments;
  final Map<String, Player> players;

  int get entityCount => npcs.length + locations.length + items.length;

  String get summarySnippet {
    if (summary?.overallSummary == null) return 'No summary available';
    final text = summary!.overallSummary!;
    if (text.length <= 150) return text;
    return '${text.substring(0, 147)}...';
  }

  String get actionItemsSnippet {
    if (actionItems.isEmpty) return 'No action items';
    final openItems = actionItems
        .where((a) => a.status == ActionItemStatus.open)
        .toList();
    if (openItems.isEmpty) return 'All items resolved';
    if (openItems.length == 1) return openItems.first.title;
    return '${openItems.first.title} (+${openItems.length - 1} more)';
  }

  String get playerMomentsSnippet {
    if (playerMoments.isEmpty) return 'No highlights recorded';
    final first = playerMoments.first;
    final playerName = players[first.playerId]?.name ?? 'Unknown';
    if (playerMoments.length == 1) {
      return '$playerName: ${_truncate(first.description, 100)}';
    }
    return '$playerName: ${_truncate(first.description, 80)} (+${playerMoments.length - 1} more)';
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength - 3)}...';
  }
}

/// Provider for session detail data including all related entities.
final sessionDetailProvider = FutureProvider.autoDispose
    .family<SessionDetailData?, ({String campaignId, String sessionId})>((
      ref,
      params,
    ) async {
      final sessionRepo = ref.watch(sessionRepositoryProvider);
      final summaryRepo = ref.watch(summaryRepositoryProvider);
      final entityRepo = ref.watch(entityRepositoryProvider);
      final actionRepo = ref.watch(actionItemRepositoryProvider);
      final momentRepo = ref.watch(playerMomentRepositoryProvider);
      final playerRepo = ref.watch(playerRepositoryProvider);
      final campaignRepo = ref.watch(campaignRepositoryProvider);

      // Get session
      final session = await sessionRepo.getSessionById(params.sessionId);
      if (session == null) return null;

      // Get campaign's world for entity lookup
      final campaignWithWorld = await campaignRepo.getCampaignWithWorld(
        params.campaignId,
      );
      if (campaignWithWorld == null) return null;
      final worldId = campaignWithWorld.world.id;

      // Get summary and scenes
      final summary = await summaryRepo.getSummaryBySession(params.sessionId);
      final scenes = await summaryRepo.getScenesBySession(params.sessionId);

      // Get entity appearances for this session
      final appearances = await entityRepo.getAppearancesBySession(
        params.sessionId,
      );

      // Fetch entities by type
      final npcIds = appearances
          .where((a) => a.entityType == EntityType.npc)
          .map((a) => a.entityId)
          .toSet();
      final locationIds = appearances
          .where((a) => a.entityType == EntityType.location)
          .map((a) => a.entityId)
          .toSet();
      final itemIds = appearances
          .where((a) => a.entityType == EntityType.item)
          .map((a) => a.entityId)
          .toSet();

      // Fetch all entities from world that appeared in this session
      final allNpcs = await entityRepo.getNpcsByWorld(worldId);
      final allLocations = await entityRepo.getLocationsByWorld(worldId);
      final allItems = await entityRepo.getItemsByWorld(worldId);

      final npcs = allNpcs.where((n) => npcIds.contains(n.id)).toList();
      final locations = allLocations
          .where((l) => locationIds.contains(l.id))
          .toList();
      final items = allItems.where((i) => itemIds.contains(i.id)).toList();

      // Get action items and player moments
      final actionItems = await actionRepo.getBySession(params.sessionId);
      final playerMoments = await momentRepo.getBySession(params.sessionId);

      // Get players for this campaign (for player moment display)
      final campaignPlayers = await playerRepo.getPlayersByCampaign(
        params.campaignId,
      );
      final playersMap = {for (final p in campaignPlayers) p.id: p};

      return SessionDetailData(
        session: session,
        summary: summary,
        scenes: scenes,
        npcs: npcs,
        locations: locations,
        items: items,
        actionItems: actionItems,
        playerMoments: playerMoments,
        players: playersMap,
      );
    });

/// Provider for just the summary and scenes for the summary drill-down.
final sessionSummaryDetailProvider = FutureProvider.autoDispose
    .family<({SessionSummary? summary, List<Scene> scenes})?, String>((
      ref,
      sessionId,
    ) async {
      final summaryRepo = ref.watch(summaryRepositoryProvider);

      final summary = await summaryRepo.getSummaryBySession(sessionId);
      final scenes = await summaryRepo.getScenesBySession(sessionId);

      return (summary: summary, scenes: scenes);
    });

/// Provider for entities appearing in a session.
final sessionEntitiesProvider = FutureProvider.autoDispose
    .family<
      ({List<Npc> npcs, List<Location> locations, List<Item> items})?,
      ({String campaignId, String sessionId})
    >((ref, params) async {
      final entityRepo = ref.watch(entityRepositoryProvider);
      final campaignRepo = ref.watch(campaignRepositoryProvider);

      // Get world ID
      final campaignWithWorld = await campaignRepo.getCampaignWithWorld(
        params.campaignId,
      );
      if (campaignWithWorld == null) return null;
      final worldId = campaignWithWorld.world.id;

      // Get appearances
      final appearances = await entityRepo.getAppearancesBySession(
        params.sessionId,
      );

      final npcIds = appearances
          .where((a) => a.entityType == EntityType.npc)
          .map((a) => a.entityId)
          .toSet();
      final locationIds = appearances
          .where((a) => a.entityType == EntityType.location)
          .map((a) => a.entityId)
          .toSet();
      final itemIds = appearances
          .where((a) => a.entityType == EntityType.item)
          .map((a) => a.entityId)
          .toSet();

      final allNpcs = await entityRepo.getNpcsByWorld(worldId);
      final allLocations = await entityRepo.getLocationsByWorld(worldId);
      final allItems = await entityRepo.getItemsByWorld(worldId);

      return (
        npcs: allNpcs.where((n) => npcIds.contains(n.id)).toList(),
        locations: allLocations
            .where((l) => locationIds.contains(l.id))
            .toList(),
        items: allItems.where((i) => itemIds.contains(i.id)).toList(),
      );
    });

/// Provider for action items in a session.
final sessionActionItemsProvider = FutureProvider.autoDispose
    .family<List<ActionItem>, String>((ref, sessionId) async {
      final actionRepo = ref.watch(actionItemRepositoryProvider);
      return await actionRepo.getBySession(sessionId);
    });

/// Provider for player moments grouped by player.
final sessionPlayerMomentsProvider = FutureProvider.autoDispose
    .family<
      Map<Player, List<PlayerMoment>>,
      ({String campaignId, String sessionId})
    >((ref, params) async {
      final momentRepo = ref.watch(playerMomentRepositoryProvider);
      final playerRepo = ref.watch(playerRepositoryProvider);

      final moments = await momentRepo.getBySession(params.sessionId);
      final players = await playerRepo.getPlayersByCampaign(params.campaignId);
      final playersMap = {for (final p in players) p.id: p};

      final result = <Player, List<PlayerMoment>>{};
      for (final moment in moments) {
        final player = playersMap[moment.playerId];
        if (player != null) {
          result.putIfAbsent(player, () => []).add(moment);
        }
      }

      return result;
    });

/// Provider for all sessions in a campaign (for past sessions list).
final campaignSessionsProvider = FutureProvider.autoDispose
    .family<List<Session>, String>((ref, campaignId) async {
      final sessionRepo = ref.watch(sessionRepositoryProvider);
      return await sessionRepo.getSessionsByCampaign(campaignId);
    });
