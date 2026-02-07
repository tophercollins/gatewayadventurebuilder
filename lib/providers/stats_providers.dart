import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'repository_providers.dart';

/// Global stats computed from DB data.
class GlobalStats {
  const GlobalStats({
    this.totalCampaigns = 0,
    this.totalSessions = 0,
    this.totalHoursRecorded = 0.0,
    this.totalNpcs = 0,
    this.totalLocations = 0,
    this.totalItems = 0,
    this.totalMonsters = 0,
    this.longestSessionMinutes = 0,
  });

  final int totalCampaigns;
  final int totalSessions;
  final double totalHoursRecorded;
  final int totalNpcs;
  final int totalLocations;
  final int totalItems;
  final int totalMonsters;
  final int longestSessionMinutes;

  int get totalEntities =>
      totalNpcs + totalLocations + totalItems + totalMonsters;
}

/// Stats for a single campaign.
class CampaignStats {
  const CampaignStats({
    required this.campaignName,
    this.totalSessions = 0,
    this.totalHoursPlayed = 0.0,
    this.npcCount = 0,
    this.locationCount = 0,
    this.itemCount = 0,
    this.monsterCount = 0,
    this.playerCount = 0,
    this.firstSessionDate,
    this.lastSessionDate,
  });

  final String campaignName;
  final int totalSessions;
  final double totalHoursPlayed;
  final int npcCount;
  final int locationCount;
  final int itemCount;
  final int monsterCount;
  final int playerCount;
  final DateTime? firstSessionDate;
  final DateTime? lastSessionDate;

  int get totalEntities =>
      npcCount + locationCount + itemCount + monsterCount;
}

/// Stats for a single player across campaigns.
class PlayerStats {
  const PlayerStats({
    required this.playerName,
    this.sessionsAttended = 0,
    this.totalSessions = 0,
    this.campaignsPlayed = 0,
    this.momentsCount = 0,
  });

  final String playerName;
  final int sessionsAttended;
  final int totalSessions;
  final int campaignsPlayed;
  final int momentsCount;

  double get attendanceRate =>
      totalSessions > 0 ? sessionsAttended / totalSessions : 0.0;
}

/// Provider for global stats.
final globalStatsProvider = FutureProvider.autoDispose<GlobalStats>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  final campaignRepo = ref.watch(campaignRepositoryProvider);
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final entityRepo = ref.watch(entityRepositoryProvider);

  final campaigns = await campaignRepo.getCampaignsByUser(user.id);
  final worlds = await campaignRepo.getWorldsByUser(user.id);

  var totalSessions = 0;
  var totalSeconds = 0;
  var longestSeconds = 0;

  for (final campaign in campaigns) {
    final sessions = await sessionRepo.getSessionsByCampaign(campaign.id);
    totalSessions += sessions.length;
    for (final session in sessions) {
      final dur = session.durationSeconds ?? 0;
      totalSeconds += dur;
      if (dur > longestSeconds) longestSeconds = dur;
    }
  }

  var totalNpcs = 0;
  var totalLocations = 0;
  var totalItems = 0;
  var totalMonsters = 0;

  for (final world in worlds) {
    final npcs = await entityRepo.getNpcsByWorld(world.id);
    final locations = await entityRepo.getLocationsByWorld(world.id);
    final items = await entityRepo.getItemsByWorld(world.id);
    final monsters = await entityRepo.getMonstersByWorld(world.id);
    totalNpcs += npcs.length;
    totalLocations += locations.length;
    totalItems += items.length;
    totalMonsters += monsters.length;
  }

  return GlobalStats(
    totalCampaigns: campaigns.length,
    totalSessions: totalSessions,
    totalHoursRecorded: totalSeconds / 3600.0,
    totalNpcs: totalNpcs,
    totalLocations: totalLocations,
    totalItems: totalItems,
    totalMonsters: totalMonsters,
    longestSessionMinutes: (longestSeconds / 60).round(),
  );
});

/// Provider for per-campaign stats.
final campaignStatsListProvider =
    FutureProvider.autoDispose<List<CampaignStats>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  final campaignRepo = ref.watch(campaignRepositoryProvider);
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final entityRepo = ref.watch(entityRepositoryProvider);
  final playerRepo = ref.watch(playerRepositoryProvider);

  final campaigns = await campaignRepo.getCampaignsByUser(user.id);
  final result = <CampaignStats>[];

  for (final campaign in campaigns) {
    final sessions = await sessionRepo.getSessionsByCampaign(campaign.id);
    final players = await playerRepo.getPlayersByCampaign(campaign.id);

    var totalSeconds = 0;
    DateTime? firstDate;
    DateTime? lastDate;

    for (final session in sessions) {
      totalSeconds += session.durationSeconds ?? 0;
      if (firstDate == null || session.date.isBefore(firstDate)) {
        firstDate = session.date;
      }
      if (lastDate == null || session.date.isAfter(lastDate)) {
        lastDate = session.date;
      }
    }

    final campaignWithWorld =
        await campaignRepo.getCampaignWithWorld(campaign.id);
    var npcCount = 0;
    var locationCount = 0;
    var itemCount = 0;
    var monsterCount = 0;

    if (campaignWithWorld != null) {
      final worldId = campaignWithWorld.world.id;
      final npcs = await entityRepo.getNpcsByWorld(worldId);
      final locations = await entityRepo.getLocationsByWorld(worldId);
      final items = await entityRepo.getItemsByWorld(worldId);
      final monsters = await entityRepo.getMonstersByWorld(worldId);
      npcCount = npcs.length;
      locationCount = locations.length;
      itemCount = items.length;
      monsterCount = monsters.length;
    }

    result.add(CampaignStats(
      campaignName: campaign.name,
      totalSessions: sessions.length,
      totalHoursPlayed: totalSeconds / 3600.0,
      npcCount: npcCount,
      locationCount: locationCount,
      itemCount: itemCount,
      monsterCount: monsterCount,
      playerCount: players.length,
      firstSessionDate: firstDate,
      lastSessionDate: lastDate,
    ));
  }

  return result;
});

/// Provider for per-player stats.
final playerStatsListProvider =
    FutureProvider.autoDispose<List<PlayerStats>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  final campaignRepo = ref.watch(campaignRepositoryProvider);
  final sessionRepo = ref.watch(sessionRepositoryProvider);
  final playerRepo = ref.watch(playerRepositoryProvider);
  final momentRepo = ref.watch(playerMomentRepositoryProvider);

  final campaigns = await campaignRepo.getCampaignsByUser(user.id);
  final playerMap = <String, PlayerStats>{};

  for (final campaign in campaigns) {
    final players = await playerRepo.getPlayersByCampaign(campaign.id);
    final sessions = await sessionRepo.getSessionsByCampaign(campaign.id);

    for (final player in players) {
      var attended = 0;
      for (final session in sessions) {
        final attendees =
            await sessionRepo.getAttendeesBySession(session.id);
        if (attendees.any((a) => a.playerId == player.id)) {
          attended++;
        }
      }

      final moments = await momentRepo.getByPlayer(player.id);

      final existing = playerMap[player.id];
      playerMap[player.id] = PlayerStats(
        playerName: player.name,
        sessionsAttended:
            (existing?.sessionsAttended ?? 0) + attended,
        totalSessions:
            (existing?.totalSessions ?? 0) + sessions.length,
        campaignsPlayed: (existing?.campaignsPlayed ?? 0) + 1,
        momentsCount:
            (existing?.momentsCount ?? 0) + moments.length,
      );
    }
  }

  return playerMap.values.toList()
    ..sort((a, b) => b.sessionsAttended.compareTo(a.sessionsAttended));
});
