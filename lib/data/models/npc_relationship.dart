/// NPC relationship model - relationships between NPCs and player characters.
class NpcRelationship {
  const NpcRelationship({
    required this.id,
    required this.npcId,
    required this.characterId,
    this.relationship,
    this.sentiment = RelationshipSentiment.neutral,
    required this.updatedAt,
  });

  final String id;
  final String npcId;
  final String characterId;
  final String? relationship;
  final RelationshipSentiment sentiment;
  final DateTime updatedAt;

  factory NpcRelationship.fromMap(Map<String, dynamic> map) {
    return NpcRelationship(
      id: map['id'] as String,
      npcId: map['npc_id'] as String,
      characterId: map['character_id'] as String,
      relationship: map['relationship'] as String?,
      sentiment: RelationshipSentiment.fromString(map['sentiment'] as String?),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'npc_id': npcId,
      'character_id': characterId,
      'relationship': relationship,
      'sentiment': sentiment.value,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  NpcRelationship copyWith({
    String? id,
    String? npcId,
    String? characterId,
    String? relationship,
    RelationshipSentiment? sentiment,
    DateTime? updatedAt,
  }) {
    return NpcRelationship(
      id: id ?? this.id,
      npcId: npcId ?? this.npcId,
      characterId: characterId ?? this.characterId,
      relationship: relationship ?? this.relationship,
      sentiment: sentiment ?? this.sentiment,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum RelationshipSentiment {
  friendly('friendly'),
  hostile('hostile'),
  neutral('neutral'),
  unknown('unknown');

  const RelationshipSentiment(this.value);
  final String value;

  static RelationshipSentiment fromString(String? value) {
    return RelationshipSentiment.values.firstWhere(
      (s) => s.value == value,
      orElse: () => RelationshipSentiment.neutral,
    );
  }

  String get displayName {
    switch (this) {
      case RelationshipSentiment.friendly:
        return 'Friendly';
      case RelationshipSentiment.hostile:
        return 'Hostile';
      case RelationshipSentiment.neutral:
        return 'Neutral';
      case RelationshipSentiment.unknown:
        return 'Unknown';
    }
  }
}
