/// Player moment model - player/character highlights per session.
class PlayerMoment {
  const PlayerMoment({
    required this.id,
    required this.sessionId,
    required this.playerId,
    this.characterId,
    this.momentType,
    required this.description,
    this.quoteText,
    this.timestampMs,
    this.isEdited = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sessionId;
  final String playerId;
  final String? characterId;
  final String? momentType;
  final String description;
  final String? quoteText;
  final int? timestampMs;
  final bool isEdited;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory PlayerMoment.fromMap(Map<String, dynamic> map) {
    return PlayerMoment(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      playerId: map['player_id'] as String,
      characterId: map['character_id'] as String?,
      momentType: map['moment_type'] as String?,
      description: map['description'] as String,
      quoteText: map['quote_text'] as String?,
      timestampMs: map['timestamp_ms'] as int?,
      isEdited: (map['is_edited'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'player_id': playerId,
      'character_id': characterId,
      'moment_type': momentType,
      'description': description,
      'quote_text': quoteText,
      'timestamp_ms': timestampMs,
      'is_edited': isEdited ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  PlayerMoment copyWith({
    String? id,
    String? sessionId,
    String? playerId,
    String? characterId,
    String? momentType,
    String? description,
    String? quoteText,
    int? timestampMs,
    bool? isEdited,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return PlayerMoment(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      playerId: playerId ?? this.playerId,
      characterId: characterId ?? this.characterId,
      momentType: momentType ?? this.momentType,
      description: description ?? this.description,
      quoteText: quoteText ?? this.quoteText,
      timestampMs: timestampMs ?? this.timestampMs,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
