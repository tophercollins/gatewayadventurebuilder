/// Entity appearance model - links entities to sessions where they appeared.
class EntityAppearance {
  const EntityAppearance({
    required this.id,
    required this.sessionId,
    required this.entityType,
    required this.entityId,
    this.context,
    this.firstAppearance = false,
    this.timestampMs,
    required this.createdAt,
  });

  final String id;
  final String sessionId;
  final EntityType entityType;
  final String entityId;
  final String? context;
  final bool firstAppearance;
  final int? timestampMs;
  final DateTime createdAt;

  factory EntityAppearance.fromMap(Map<String, dynamic> map) {
    return EntityAppearance(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      entityType: EntityType.fromString(map['entity_type'] as String),
      entityId: map['entity_id'] as String,
      context: map['context'] as String?,
      firstAppearance: (map['first_appearance'] as int?) == 1,
      timestampMs: map['timestamp_ms'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'entity_type': entityType.value,
      'entity_id': entityId,
      'context': context,
      'first_appearance': firstAppearance ? 1 : 0,
      'timestamp_ms': timestampMs,
      'created_at': createdAt.toIso8601String(),
    };
  }

  EntityAppearance copyWith({
    String? id,
    String? sessionId,
    EntityType? entityType,
    String? entityId,
    String? context,
    bool? firstAppearance,
    int? timestampMs,
    DateTime? createdAt,
  }) {
    return EntityAppearance(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      context: context ?? this.context,
      firstAppearance: firstAppearance ?? this.firstAppearance,
      timestampMs: timestampMs ?? this.timestampMs,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

enum EntityType {
  npc('npc'),
  location('location'),
  item('item');

  const EntityType(this.value);
  final String value;

  static EntityType fromString(String value) {
    return EntityType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EntityType.npc,
    );
  }
}
