import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/character.dart';
import '../data/models/player.dart';
import '../data/repositories/player_repository.dart';
import 'repository_providers.dart';

/// Provider for players in a specific campaign.
final campaignPlayersProvider = FutureProvider.family<List<Player>, String>((
  ref,
  campaignId,
) async {
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
final playerCharactersProvider = FutureProvider.family<List<Character>, String>(
  (ref, playerId) async {
    final playerRepo = ref.watch(playerRepositoryProvider);
    return playerRepo.getCharactersByPlayer(playerId);
  },
);

/// Combined provider that returns players with their characters for a campaign.
final playersWithCharactersProvider =
    FutureProvider.family<List<PlayerWithCharacters>, String>((
      ref,
      campaignId,
    ) async {
      final players = await ref.watch(
        campaignPlayersProvider(campaignId).future,
      );
      final characters = await ref.watch(
        campaignCharactersProvider(campaignId).future,
      );

      return players.map((player) {
        final playerCharacters = characters
            .where((c) => c.playerId == player.id)
            .toList();
        return PlayerWithCharacters(
          player: player,
          characters: playerCharacters,
        );
      }).toList();
    });

/// Data class combining a player with their characters.
class PlayerWithCharacters {
  const PlayerWithCharacters({required this.player, required this.characters});

  final Player player;
  final List<Character> characters;
}

/// Service for player and character CRUD operations.
class PlayerEditor {
  PlayerEditor(this._playerRepo, this._ref);

  final PlayerRepository _playerRepo;
  final Ref _ref;

  /// Creates a player and adds them to a campaign.
  Future<void> createPlayer({
    required String campaignId,
    required String name,
    String? notes,
  }) async {
    final user = await _ref.read(currentUserProvider.future);
    final player = await _playerRepo.createPlayer(
      userId: user.id,
      name: name,
      notes: notes,
    );
    await _playerRepo.addPlayerToCampaign(
      campaignId: campaignId,
      playerId: player.id,
    );
    _invalidateForCampaign(campaignId);
  }

  /// Creates a character for a player.
  Future<void> createCharacter({
    required String playerId,
    required String campaignId,
    required String name,
    String? characterClass,
    String? race,
    int? level,
    String? backstory,
  }) async {
    await _playerRepo.createCharacter(
      playerId: playerId,
      campaignId: campaignId,
      name: name,
      characterClass: characterClass,
      race: race,
      level: level,
      backstory: backstory,
    );
    _invalidateForCampaign(campaignId);
  }

  /// Updates a player.
  Future<void> updatePlayer(Player player, String campaignId) async {
    await _playerRepo.updatePlayer(player);
    _invalidateForCampaign(campaignId);
  }

  /// Updates a character.
  Future<void> updateCharacter(Character character, String campaignId) async {
    await _playerRepo.updateCharacter(character);
    _invalidateForCampaign(campaignId);
  }

  /// Removes a player from a campaign and deletes them.
  Future<void> deletePlayer(Player player, String campaignId) async {
    await _playerRepo.removePlayerFromCampaign(
      playerId: player.id,
      campaignId: campaignId,
    );
    await _playerRepo.deletePlayer(player.id);
    _invalidateForCampaign(campaignId);
  }

  /// Deletes a character.
  Future<void> deleteCharacter(String characterId, String campaignId) async {
    await _playerRepo.deleteCharacter(characterId);
    _invalidateForCampaign(campaignId);
  }

  void _invalidateForCampaign(String campaignId) {
    _ref.invalidate(playersWithCharactersProvider(campaignId));
    _ref.invalidate(campaignPlayersProvider(campaignId));
    _ref.invalidate(campaignCharactersProvider(campaignId));
  }
}

/// Provider for player CRUD operations.
final playerEditorProvider = Provider<PlayerEditor>((ref) {
  final playerRepo = ref.watch(playerRepositoryProvider);
  return PlayerEditor(playerRepo, ref);
});
