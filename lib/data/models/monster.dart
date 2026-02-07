/// Monster model - world-level entity shared across campaigns.
/// Represents types of enemies/creatures (e.g., "Goblin", "Shadow Wolf").
class Monster {
  const Monster({
    required this.id,
    required this.worldId,
    this.copiedFromId,
    required this.name,
    this.description,
    this.monsterType,
    this.notes,
    this.isEdited = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String worldId;
  final String? copiedFromId;
  final String name;
  final String? description;
  final String? monsterType;
  final String? notes;
  final bool isEdited;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Monster.fromMap(Map<String, dynamic> map) {
    return Monster(
      id: map['id'] as String,
      worldId: map['world_id'] as String,
      copiedFromId: map['copied_from_id'] as String?,
      name: map['name'] as String,
      description: map['description'] as String?,
      monsterType: map['monster_type'] as String?,
      notes: map['notes'] as String?,
      isEdited: (map['is_edited'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'world_id': worldId,
      'copied_from_id': copiedFromId,
      'name': name,
      'description': description,
      'monster_type': monsterType,
      'notes': notes,
      'is_edited': isEdited ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Monster copyWith({
    String? id,
    String? worldId,
    String? copiedFromId,
    String? name,
    String? description,
    String? monsterType,
    String? notes,
    bool? isEdited,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Monster(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      copiedFromId: copiedFromId ?? this.copiedFromId,
      name: name ?? this.name,
      description: description ?? this.description,
      monsterType: monsterType ?? this.monsterType,
      notes: notes ?? this.notes,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
