/// Organisation model - world-level entity shared across campaigns.
/// Represents factions, guilds, governments, cults, etc.
class Organisation {
  const Organisation({
    required this.id,
    required this.worldId,
    this.copiedFromId,
    required this.name,
    this.description,
    this.organisationType,
    this.notes,
    this.isEdited = false,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String worldId;
  final String? copiedFromId;
  final String name;
  final String? description;
  final String? organisationType;
  final String? notes;
  final bool isEdited;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Organisation.fromMap(Map<String, dynamic> map) {
    return Organisation(
      id: map['id'] as String,
      worldId: map['world_id'] as String,
      copiedFromId: map['copied_from_id'] as String?,
      name: map['name'] as String,
      description: map['description'] as String?,
      organisationType: map['organisation_type'] as String?,
      notes: map['notes'] as String?,
      isEdited: (map['is_edited'] as int?) == 1,
      imagePath: map['image_path'] as String?,
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
      'organisation_type': organisationType,
      'notes': notes,
      'is_edited': isEdited ? 1 : 0,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Organisation copyWith({
    String? id,
    String? worldId,
    String? copiedFromId,
    String? name,
    String? description,
    String? organisationType,
    String? notes,
    bool? isEdited,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Organisation(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      copiedFromId: copiedFromId ?? this.copiedFromId,
      name: name ?? this.name,
      description: description ?? this.description,
      organisationType: organisationType ?? this.organisationType,
      notes: notes ?? this.notes,
      isEdited: isEdited ?? this.isEdited,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
