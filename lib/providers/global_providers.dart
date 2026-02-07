import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/campaign.dart';
import '../data/models/character.dart';
import '../data/models/player.dart';
import '../data/models/world.dart';
import 'player_providers.dart';
import 'repository_providers.dart';

/// Data class for a world with entity counts and linked campaign IDs.
class WorldSummary {
  const WorldSummary({
    required this.world,
    required this.npcCount,
    required this.locationCount,
    required this.itemCount,
    required this.campaigns,
  });

  final World world;
  final int npcCount;
  final int locationCount;
  final int itemCount;
  final List<Campaign> campaigns;
}

/// Data class for a player with their campaign count.
class PlayerSummary {
  const PlayerSummary({required this.player, required this.campaignCount});

  final Player player;
  final int campaignCount;
}

/// Revision counter to force worlds list refresh.
final worldsRevisionProvider = StateProvider<int>((ref) => 0);

/// Provider fetching all worlds for the current user with entity counts.
final allWorldsProvider = FutureProvider.autoDispose<List<WorldSummary>>((
  ref,
) async {
  ref.watch(worldsRevisionProvider);
  final user = await ref.watch(currentUserProvider.future);
  final campaignRepo = ref.watch(campaignRepositoryProvider);
  final entityRepo = ref.watch(entityRepositoryProvider);

  final worlds = await campaignRepo.getWorldsByUser(user.id);
  final result = <WorldSummary>[];

  for (final world in worlds) {
    final npcs = await entityRepo.getNpcsByWorld(world.id);
    final locations = await entityRepo.getLocationsByWorld(world.id);
    final items = await entityRepo.getItemsByWorld(world.id);
    final campaigns = await campaignRepo.getCampaignsByWorld(world.id);

    result.add(
      WorldSummary(
        world: world,
        npcCount: npcs.length,
        locationCount: locations.length,
        itemCount: items.length,
        campaigns: campaigns,
      ),
    );
  }

  return result;
});

/// Data class for a character with its campaign name.
class CharacterSummary {
  const CharacterSummary({
    required this.character,
    required this.campaignName,
  });

  final Character character;
  final String campaignName;
}

/// Provider fetching all characters for the current user with campaign names.
final allCharactersProvider =
    FutureProvider.autoDispose<List<CharacterSummary>>((ref) async {
  final user = await ref.watch(currentUserProvider.future);
  final playerRepo = ref.watch(playerRepositoryProvider);
  final campaignRepo = ref.watch(campaignRepositoryProvider);

  final characters = await playerRepo.getCharactersByUser(user.id);
  final campaigns = await campaignRepo.getCampaignsByUser(user.id);
  final campaignMap = {for (final c in campaigns) c.id: c.name};

  return characters
      .map(
        (ch) => CharacterSummary(
          character: ch,
          campaignName: campaignMap[ch.campaignId] ?? 'Unknown',
        ),
      )
      .toList();
});

/// Provider fetching all players for the current user with campaign counts.
final allPlayersProvider = FutureProvider.autoDispose<List<PlayerSummary>>((
  ref,
) async {
  ref.watch(playersRevisionProvider);
  final user = await ref.watch(currentUserProvider.future);
  final playerRepo = ref.watch(playerRepositoryProvider);
  final campaignRepo = ref.watch(campaignRepositoryProvider);

  final players = await playerRepo.getPlayersByUser(user.id);
  final campaigns = await campaignRepo.getCampaignsByUser(user.id);

  final result = <PlayerSummary>[];
  for (final player in players) {
    var count = 0;
    for (final campaign in campaigns) {
      final inCampaign = await playerRepo.isPlayerInCampaign(
        campaignId: campaign.id,
        playerId: player.id,
      );
      if (inCampaign) count++;
    }
    result.add(PlayerSummary(player: player, campaignCount: count));
  }

  return result;
});
