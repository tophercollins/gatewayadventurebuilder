/// Database schema definitions for TTRPG Session Tracker.
/// All table and index creation statements per BACKEND_STRUCTURE.md.
abstract final class DatabaseSchema {
  /// All CREATE TABLE statements in dependency order.
  static const List<String> createTableStatements = [
    _createUsers,
    _createWorlds,
    _createCampaigns,
    _createPlayers,
    _createCampaignPlayers,
    _createCharacters,
    _createSessions,
    _createSessionAttendees,
    _createSessionAudio,
    _createSessionTranscripts,
    _createTranscriptSegments,
    _createSessionSummaries,
    _createScenes,
    _createNpcs,
    _createLocations,
    _createItems,
    _createEntityAppearances,
    _createNpcRelationships,
    _createNpcQuotes,
    _createActionItems,
    _createPlayerMoments,
    _createProcessingQueue,
    _createCampaignImports,
  ];

  /// All CREATE INDEX statements.
  static const List<String> createIndexStatements = [
    'CREATE INDEX idx_campaigns_world ON campaigns(world_id)',
    'CREATE INDEX idx_sessions_campaign ON sessions(campaign_id)',
    'CREATE INDEX idx_npcs_world ON npcs(world_id)',
    'CREATE INDEX idx_locations_world ON locations(world_id)',
    'CREATE INDEX idx_items_world ON items(world_id)',
    'CREATE INDEX idx_entity_appearances_session ON entity_appearances(session_id)',
    'CREATE INDEX idx_entity_appearances_entity ON entity_appearances(entity_type, entity_id)',
    'CREATE INDEX idx_action_items_campaign ON action_items(campaign_id)',
    'CREATE INDEX idx_action_items_status ON action_items(status)',
    'CREATE INDEX idx_player_moments_session ON player_moments(session_id)',
    'CREATE INDEX idx_player_moments_player ON player_moments(player_id)',
    'CREATE INDEX idx_processing_queue_status ON processing_queue(status)',
    'CREATE INDEX idx_transcript_segments_transcript ON transcript_segments(transcript_id)',
  ];

  static const String _createUsers = '''
    CREATE TABLE users (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      email TEXT UNIQUE,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String _createWorlds = '''
    CREATE TABLE worlds (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id),
      name TEXT NOT NULL,
      description TEXT,
      game_system TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String _createCampaigns = '''
    CREATE TABLE campaigns (
      id TEXT PRIMARY KEY,
      world_id TEXT NOT NULL REFERENCES worlds(id),
      name TEXT NOT NULL,
      description TEXT,
      game_system TEXT,
      status TEXT DEFAULT 'active',
      start_date TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String _createPlayers = '''
    CREATE TABLE players (
      id TEXT PRIMARY KEY,
      user_id TEXT NOT NULL REFERENCES users(id),
      name TEXT NOT NULL,
      notes TEXT,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String _createCampaignPlayers = '''
    CREATE TABLE campaign_players (
      id TEXT PRIMARY KEY,
      campaign_id TEXT NOT NULL REFERENCES campaigns(id),
      player_id TEXT NOT NULL REFERENCES players(id),
      joined_at TEXT NOT NULL,
      UNIQUE(campaign_id, player_id)
    )
  ''';

  static const String _createCharacters = '''
    CREATE TABLE characters (
      id TEXT PRIMARY KEY,
      player_id TEXT NOT NULL REFERENCES players(id),
      campaign_id TEXT NOT NULL REFERENCES campaigns(id),
      name TEXT NOT NULL,
      character_class TEXT,
      race TEXT,
      level INTEGER,
      backstory TEXT,
      goals TEXT,
      notes TEXT,
      status TEXT DEFAULT 'active',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String _createSessions = '''
    CREATE TABLE sessions (
      id TEXT PRIMARY KEY,
      campaign_id TEXT NOT NULL REFERENCES campaigns(id),
      session_number INTEGER,
      title TEXT,
      date TEXT NOT NULL,
      duration_seconds INTEGER,
      status TEXT DEFAULT 'recording',
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String _createSessionAttendees = '''
    CREATE TABLE session_attendees (
      id TEXT PRIMARY KEY,
      session_id TEXT NOT NULL REFERENCES sessions(id),
      player_id TEXT NOT NULL REFERENCES players(id),
      character_id TEXT REFERENCES characters(id),
      UNIQUE(session_id, player_id)
    )
  ''';

  static const String _createSessionAudio = '''
    CREATE TABLE session_audio (
      id TEXT PRIMARY KEY,
      session_id TEXT NOT NULL UNIQUE REFERENCES sessions(id),
      file_path TEXT NOT NULL,
      file_size_bytes INTEGER,
      format TEXT,
      duration_seconds INTEGER,
      checksum TEXT,
      created_at TEXT NOT NULL
    )
  ''';

  static const String _createSessionTranscripts = '''
    CREATE TABLE session_transcripts (
      id TEXT PRIMARY KEY,
      session_id TEXT NOT NULL REFERENCES sessions(id),
      version INTEGER DEFAULT 1,
      raw_text TEXT NOT NULL,
      whisper_model TEXT,
      language TEXT DEFAULT 'en',
      created_at TEXT NOT NULL
    )
  ''';

  static const String _createTranscriptSegments = '''
    CREATE TABLE transcript_segments (
      id TEXT PRIMARY KEY,
      transcript_id TEXT NOT NULL REFERENCES session_transcripts(id),
      segment_index INTEGER NOT NULL,
      start_time_ms INTEGER NOT NULL,
      end_time_ms INTEGER NOT NULL,
      text TEXT NOT NULL
    )
  ''';

  static const String _createSessionSummaries = '''
    CREATE TABLE session_summaries (
      id TEXT PRIMARY KEY,
      session_id TEXT NOT NULL REFERENCES sessions(id),
      transcript_id TEXT REFERENCES session_transcripts(id),
      overall_summary TEXT,
      is_edited INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String _createScenes = '''
    CREATE TABLE scenes (
      id TEXT PRIMARY KEY,
      session_id TEXT NOT NULL REFERENCES sessions(id),
      scene_index INTEGER NOT NULL,
      title TEXT,
      summary TEXT,
      start_time_ms INTEGER,
      end_time_ms INTEGER,
      is_edited INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String _createNpcs = '''
    CREATE TABLE npcs (
      id TEXT PRIMARY KEY,
      world_id TEXT NOT NULL REFERENCES worlds(id),
      copied_from_id TEXT REFERENCES npcs(id),
      name TEXT NOT NULL,
      description TEXT,
      role TEXT,
      status TEXT DEFAULT 'alive',
      notes TEXT,
      is_edited INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String _createLocations = '''
    CREATE TABLE locations (
      id TEXT PRIMARY KEY,
      world_id TEXT NOT NULL REFERENCES worlds(id),
      copied_from_id TEXT REFERENCES locations(id),
      name TEXT NOT NULL,
      description TEXT,
      location_type TEXT,
      parent_location_id TEXT REFERENCES locations(id),
      notes TEXT,
      is_edited INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String _createItems = '''
    CREATE TABLE items (
      id TEXT PRIMARY KEY,
      world_id TEXT NOT NULL REFERENCES worlds(id),
      copied_from_id TEXT REFERENCES items(id),
      name TEXT NOT NULL,
      description TEXT,
      item_type TEXT,
      properties TEXT,
      current_owner_type TEXT,
      current_owner_id TEXT,
      notes TEXT,
      is_edited INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String _createEntityAppearances = '''
    CREATE TABLE entity_appearances (
      id TEXT PRIMARY KEY,
      session_id TEXT NOT NULL REFERENCES sessions(id),
      entity_type TEXT NOT NULL,
      entity_id TEXT NOT NULL,
      context TEXT,
      first_appearance INTEGER DEFAULT 0,
      timestamp_ms INTEGER,
      created_at TEXT NOT NULL
    )
  ''';

  static const String _createNpcRelationships = '''
    CREATE TABLE npc_relationships (
      id TEXT PRIMARY KEY,
      npc_id TEXT NOT NULL REFERENCES npcs(id),
      character_id TEXT NOT NULL REFERENCES characters(id),
      relationship TEXT,
      sentiment TEXT,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String _createNpcQuotes = '''
    CREATE TABLE npc_quotes (
      id TEXT PRIMARY KEY,
      npc_id TEXT NOT NULL REFERENCES npcs(id),
      session_id TEXT NOT NULL REFERENCES sessions(id),
      quote_text TEXT NOT NULL,
      context TEXT,
      timestamp_ms INTEGER,
      created_at TEXT NOT NULL
    )
  ''';

  static const String _createActionItems = '''
    CREATE TABLE action_items (
      id TEXT PRIMARY KEY,
      session_id TEXT NOT NULL REFERENCES sessions(id),
      campaign_id TEXT NOT NULL REFERENCES campaigns(id),
      title TEXT NOT NULL,
      description TEXT,
      action_type TEXT,
      status TEXT DEFAULT 'open',
      resolved_session_id TEXT REFERENCES sessions(id),
      is_edited INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String _createPlayerMoments = '''
    CREATE TABLE player_moments (
      id TEXT PRIMARY KEY,
      session_id TEXT NOT NULL REFERENCES sessions(id),
      player_id TEXT NOT NULL REFERENCES players(id),
      character_id TEXT REFERENCES characters(id),
      moment_type TEXT,
      description TEXT NOT NULL,
      quote_text TEXT,
      timestamp_ms INTEGER,
      is_edited INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL
    )
  ''';

  static const String _createProcessingQueue = '''
    CREATE TABLE processing_queue (
      id TEXT PRIMARY KEY,
      session_id TEXT NOT NULL REFERENCES sessions(id),
      status TEXT DEFAULT 'pending',
      error_message TEXT,
      attempts INTEGER DEFAULT 0,
      created_at TEXT NOT NULL,
      started_at TEXT,
      completed_at TEXT
    )
  ''';

  static const String _createCampaignImports = '''
    CREATE TABLE campaign_imports (
      id TEXT PRIMARY KEY,
      campaign_id TEXT NOT NULL REFERENCES campaigns(id),
      raw_text TEXT NOT NULL,
      status TEXT DEFAULT 'pending',
      created_at TEXT NOT NULL,
      processed_at TEXT
    )
  ''';
}
