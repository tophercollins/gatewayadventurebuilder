import '../../data/models/campaign.dart';
import '../../data/models/character.dart';
import '../../data/models/item.dart';
import '../../data/models/location.dart';
import '../../data/models/monster.dart';
import '../../data/models/npc.dart';
import '../../data/models/organisation.dart';
import '../../data/models/player.dart';
import '../../data/models/session.dart';
import '../../data/models/session_transcript.dart';
import '../../data/models/world.dart';
import '../../data/repositories/campaign_repository.dart';
import '../../data/repositories/entity_repository.dart';
import '../../data/repositories/player_repository.dart';
import '../../data/repositories/session_repository.dart';
import 'prompts/player_moments_prompt.dart';

/// Context data loaded for session processing.
class SessionContext {
  const SessionContext({
    required this.session,
    required this.campaign,
    required this.world,
    required this.transcript,
    required this.attendees,
    required this.players,
    required this.characters,
    required this.existingNpcs,
    required this.existingLocations,
    required this.existingItems,
    required this.existingMonsters,
    required this.existingOrganisations,
  });

  final Session session;
  final Campaign campaign;
  final World world;
  final SessionTranscript transcript;
  final List<SessionAttendee> attendees;
  final List<Player> players;
  final List<Character> characters;
  final List<Npc> existingNpcs;
  final List<Location> existingLocations;
  final List<Item> existingItems;
  final List<Monster> existingMonsters;
  final List<Organisation> existingOrganisations;

  /// Get player names for attendees.
  List<String> get attendeeNames {
    return attendees.map((a) {
      final player = players.firstWhere(
        (p) => p.id == a.playerId,
        orElse: () => Player(
          id: '',
          userId: '',
          name: 'Unknown',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      return player.name;
    }).toList();
  }

  /// Get attendee info for prompts.
  List<AttendeeInfo> get attendeeInfo {
    return attendees.map((a) {
      final player = players.firstWhere(
        (p) => p.id == a.playerId,
        orElse: () => Player(
          id: '',
          userId: '',
          name: 'Unknown',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      Character? character;
      if (a.characterId != null) {
        character = characters.where((c) => c.id == a.characterId).firstOrNull;
      }

      return AttendeeInfo(
        playerId: a.playerId,
        playerName: player.name,
        characterId: a.characterId,
        characterName: character?.name,
      );
    }).toList();
  }

  /// Get names of existing NPCs.
  List<String> get existingNpcNames => existingNpcs.map((n) => n.name).toList();

  /// Get names of existing locations.
  List<String> get existingLocationNames =>
      existingLocations.map((l) => l.name).toList();

  /// Get names of existing items.
  List<String> get existingItemNames =>
      existingItems.map((i) => i.name).toList();

  /// Get names of existing monsters.
  List<String> get existingMonsterNames =>
      existingMonsters.map((m) => m.name).toList();

  /// Get names of existing organisations.
  List<String> get existingOrganisationNames =>
      existingOrganisations.map((o) => o.name).toList();

  /// Get game system (from campaign or world).
  String get gameSystem =>
      campaign.gameSystem ?? world.gameSystem ?? 'Unknown System';
}

/// Loads context data required for session processing.
class SessionContextLoader {
  SessionContextLoader({
    required SessionRepository sessionRepo,
    required CampaignRepository campaignRepo,
    required PlayerRepository playerRepo,
    required EntityRepository entityRepo,
  }) : _sessionRepo = sessionRepo,
       _campaignRepo = campaignRepo,
       _playerRepo = playerRepo,
       _entityRepo = entityRepo;

  final SessionRepository _sessionRepo;
  final CampaignRepository _campaignRepo;
  final PlayerRepository _playerRepo;
  final EntityRepository _entityRepo;

  /// Load all context needed for processing a session.
  Future<SessionContext?> load(String sessionId) async {
    // Load session
    final session = await _sessionRepo.getSessionById(sessionId);
    if (session == null) return null;

    // Load campaign and world
    final campaignWithWorld = await _campaignRepo.getCampaignWithWorld(
      session.campaignId,
    );
    if (campaignWithWorld == null) return null;

    // Load transcript
    final transcript = await _sessionRepo.getLatestTranscript(sessionId);
    if (transcript == null) return null;

    // Load attendees
    final attendees = await _sessionRepo.getAttendeesBySession(sessionId);

    // Load players and characters
    final players = await _playerRepo.getPlayersByCampaign(session.campaignId);
    final characters = await _playerRepo.getCharactersByCampaign(
      session.campaignId,
    );

    // Load existing entities
    final worldId = campaignWithWorld.world.id;
    final existingNpcs = await _entityRepo.getNpcsByWorld(worldId);
    final existingLocations = await _entityRepo.getLocationsByWorld(worldId);
    final existingItems = await _entityRepo.getItemsByWorld(worldId);
    final existingMonsters = await _entityRepo.getMonstersByWorld(worldId);
    final existingOrganisations = await _entityRepo.getOrganisationsByWorld(
      worldId,
    );

    return SessionContext(
      session: session,
      campaign: campaignWithWorld.campaign,
      world: campaignWithWorld.world,
      transcript: transcript,
      attendees: attendees,
      players: players,
      characters: characters,
      existingNpcs: existingNpcs,
      existingLocations: existingLocations,
      existingItems: existingItems,
      existingMonsters: existingMonsters,
      existingOrganisations: existingOrganisations,
    );
  }
}
