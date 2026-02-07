import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/campaign.dart';
import '../data/models/character.dart';
import '../data/models/player.dart';
import '../data/models/session.dart';
import '../data/repositories/player_repository.dart';
import 'image_providers.dart';
import 'repository_providers.dart';

/// Revision counter for character-related cache invalidation.
final charactersRevisionProvider = StateProvider<int>((ref) => 0);

/// Revision counter for global players list cache invalidation.
final playersRevisionProvider = StateProvider<int>((ref) => 0);

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

/// Provider for a single player by ID.
final playerDetailProvider = FutureProvider.autoDispose
    .family<Player?, String>((ref, playerId) {
      ref.watch(playersRevisionProvider);
      final playerRepo = ref.watch(playerRepositoryProvider);
      return playerRepo.getPlayerById(playerId);
    });

/// Provider for campaigns a player belongs to.
final playerCampaignsProvider = FutureProvider.autoDispose
    .family<List<Campaign>, String>((ref, playerId) {
      ref.watch(playersRevisionProvider);
      final playerRepo = ref.watch(playerRepositoryProvider);
      return playerRepo.getCampaignsByPlayer(playerId);
    });

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

/// Provider for a single character by ID.
final characterDetailProvider = FutureProvider.autoDispose
    .family<Character?, String>((ref, characterId) {
      ref.watch(charactersRevisionProvider);
      final playerRepo = ref.watch(playerRepositoryProvider);
      return playerRepo.getCharacterById(characterId);
    });

/// Provider for sessions a character attended.
final characterSessionsProvider = FutureProvider.autoDispose
    .family<List<Session>, String>((ref, characterId) {
      ref.watch(charactersRevisionProvider);
      final playerRepo = ref.watch(playerRepositoryProvider);
      return playerRepo.getSessionsByCharacter(characterId);
    });

/// Provider for the player who owns a character.
final characterPlayerProvider = FutureProvider.autoDispose
    .family<Player?, String>((ref, playerId) {
      final playerRepo = ref.watch(playerRepositoryProvider);
      return playerRepo.getPlayerById(playerId);
    });

/// Provider for players not yet linked to a specific campaign.
final availablePlayersForCampaignProvider = FutureProvider.autoDispose
    .family<List<Player>, String>((ref, campaignId) async {
      ref.watch(playersRevisionProvider);
      final user = await ref.watch(currentUserProvider.future);
      final playerRepo = ref.watch(playerRepositoryProvider);
      final allPlayers = await playerRepo.getPlayersByUser(user.id);
      final available = <Player>[];
      for (final player in allPlayers) {
        final inCampaign = await playerRepo.isPlayerInCampaign(
          campaignId: campaignId,
          playerId: player.id,
        );
        if (!inCampaign) {
          available.add(player);
        }
      }
      return available;
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
  /// Returns the new player's ID.
  Future<String> createPlayer({
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
    return player.id;
  }

  /// Creates a player without linking to a campaign.
  /// Returns the new player's ID.
  Future<String> createPlayerGlobal({
    required String name,
    String? notes,
  }) async {
    final user = await _ref.read(currentUserProvider.future);
    final player = await _playerRepo.createPlayer(
      userId: user.id,
      name: name,
      notes: notes,
    );
    _ref.read(playersRevisionProvider.notifier).state++;
    return player.id;
  }

  /// Creates a character for a player.
  /// If [campaignId] is provided, also links the character to that campaign.
  /// Returns the new character's ID.
  Future<String> createCharacter({
    required String playerId,
    required String name,
    String? campaignId,
    String? characterClass,
    String? race,
    int? level,
    String? backstory,
  }) async {
    final character = await _playerRepo.createCharacter(
      playerId: playerId,
      name: name,
      characterClass: characterClass,
      race: race,
      level: level,
      backstory: backstory,
    );
    if (campaignId != null) {
      await _playerRepo.addCharacterToCampaign(
        campaignId: campaignId,
        characterId: character.id,
      );
      _invalidateForCampaign(campaignId);
    }
    _ref.read(charactersRevisionProvider.notifier).state++;
    return character.id;
  }

  /// Updates a player (global context, no campaign).
  Future<void> updatePlayerGlobal(Player player) async {
    await _playerRepo.updatePlayer(player);
    _ref.read(playersRevisionProvider.notifier).state++;
  }

  /// Deletes a player globally: removes all campaign links, image, then player.
  Future<void> deletePlayerGlobal(String playerId) async {
    final campaigns = await _playerRepo.getCampaignsByPlayer(playerId);
    for (final campaign in campaigns) {
      await _playerRepo.removePlayerFromCampaign(
        campaignId: campaign.id,
        playerId: playerId,
      );
    }
    final imageService = _ref.read(imageStorageProvider);
    await imageService.deleteImage(entityType: 'players', entityId: playerId);
    await _playerRepo.deletePlayer(playerId);
    _ref.read(playersRevisionProvider.notifier).state++;
  }

  /// Updates a player.
  Future<void> updatePlayer(Player player, String campaignId) async {
    await _playerRepo.updatePlayer(player);
    _invalidateForCampaign(campaignId);
  }

  /// Updates a character.
  Future<void> updateCharacter(Character character, [String? campaignId]) async {
    await _playerRepo.updateCharacter(character);
    if (campaignId != null) {
      _invalidateForCampaign(campaignId);
    }
    _ref.read(charactersRevisionProvider.notifier).state++;
  }

  /// Links an existing player to a campaign.
  Future<void> linkPlayerToCampaign({
    required String campaignId,
    required String playerId,
  }) async {
    await _playerRepo.addPlayerToCampaign(
      campaignId: campaignId,
      playerId: playerId,
    );
    _invalidateForCampaign(campaignId);
  }

  /// Removes a player from a campaign and deletes them, including image.
  Future<void> deletePlayer(Player player, String campaignId) async {
    final imageService = _ref.read(imageStorageProvider);
    await imageService.deleteImage(entityType: 'players', entityId: player.id);
    await _playerRepo.removePlayerFromCampaign(
      playerId: player.id,
      campaignId: campaignId,
    );
    await _playerRepo.deletePlayer(player.id);
    _invalidateForCampaign(campaignId);
  }

  /// Deletes a character, including image and all campaign links.
  Future<void> deleteCharacter(String characterId, [String? campaignId]) async {
    final imageService = _ref.read(imageStorageProvider);
    await imageService.deleteImage(
      entityType: 'characters',
      entityId: characterId,
    );
    await _playerRepo.deleteCharacter(characterId);
    if (campaignId != null) {
      _invalidateForCampaign(campaignId);
    }
    _ref.read(charactersRevisionProvider.notifier).state++;
  }

  /// Links an existing character to a campaign.
  Future<void> linkCharacterToCampaign({
    required String campaignId,
    required String characterId,
  }) async {
    await _playerRepo.addCharacterToCampaign(
      campaignId: campaignId,
      characterId: characterId,
    );
    _invalidateForCampaign(campaignId);
  }

  /// Removes a character from a campaign (does not delete the character).
  Future<void> unlinkCharacterFromCampaign({
    required String campaignId,
    required String characterId,
  }) async {
    await _playerRepo.removeCharacterFromCampaign(
      campaignId: campaignId,
      characterId: characterId,
    );
    _invalidateForCampaign(campaignId);
  }

  void _invalidateForCampaign(String campaignId) {
    _ref.invalidate(playersWithCharactersProvider(campaignId));
    _ref.invalidate(campaignPlayersProvider(campaignId));
    _ref.invalidate(campaignCharactersProvider(campaignId));
    _ref.read(charactersRevisionProvider.notifier).state++;
    _ref.read(playersRevisionProvider.notifier).state++;
  }
}

/// Provider for campaigns a character belongs to.
final characterCampaignsProvider = FutureProvider.autoDispose
    .family<List<Campaign>, String>((ref, characterId) {
      ref.watch(charactersRevisionProvider);
      final playerRepo = ref.watch(playerRepositoryProvider);
      return playerRepo.getCampaignsByCharacter(characterId);
    });

/// Provider for player CRUD operations.
final playerEditorProvider = Provider<PlayerEditor>((ref) {
  final playerRepo = ref.watch(playerRepositoryProvider);
  return PlayerEditor(playerRepo, ref);
});
