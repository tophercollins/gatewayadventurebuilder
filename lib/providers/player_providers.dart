import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/character.dart';
import '../data/models/player.dart';
import 'repository_providers.dart';

/// Provider for players in a specific campaign.
final campaignPlayersProvider =
    FutureProvider.family<List<Player>, String>((ref, campaignId) async {
  final playerRepo = ref.watch(playerRepositoryProvider);
  return playerRepo.getPlayersByCampaign(campaignId);
});

/// Provider for characters in a specific campaign.
final campaignCharactersProvider =
    FutureProvider.family<List<Character>, String>((ref, campaignId) async {
  final playerRepo = ref.watch(playerRepositoryProvider);
  return playerRepo.getCharactersByCampaign(campaignId);
});

/// Provider for characters belonging to a specific player.
final playerCharactersProvider =
    FutureProvider.family<List<Character>, String>((ref, playerId) async {
  final playerRepo = ref.watch(playerRepositoryProvider);
  return playerRepo.getCharactersByPlayer(playerId);
});

/// Combined provider that returns players with their characters for a campaign.
final playersWithCharactersProvider = FutureProvider.family<
    List<PlayerWithCharacters>, String>((ref, campaignId) async {
  final players = await ref.watch(campaignPlayersProvider(campaignId).future);
  final characters =
      await ref.watch(campaignCharactersProvider(campaignId).future);

  return players.map((player) {
    final playerCharacters =
        characters.where((c) => c.playerId == player.id).toList();
    return PlayerWithCharacters(player: player, characters: playerCharacters);
  }).toList();
});

/// Data class combining a player with their characters.
class PlayerWithCharacters {
  const PlayerWithCharacters({
    required this.player,
    required this.characters,
  });

  final Player player;
  final List<Character> characters;
}
