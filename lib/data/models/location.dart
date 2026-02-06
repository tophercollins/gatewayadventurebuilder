/// Location model - world-level entity shared across campaigns.
class Location {
  const Location({
    required this.id,
    required this.worldId,
    this.copiedFromId,
    required this.name,
    this.description,
    this.locationType,
    this.parentLocationId,
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
  final String? locationType;
  final String? parentLocationId;
  final String? notes;
  final bool isEdited;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      id: map['id'] as String,
      worldId: map['world_id'] as String,
      copiedFromId: map['copied_from_id'] as String?,
      name: map['name'] as String,
      description: map['description'] as String?,
      locationType: map['location_type'] as String?,
      parentLocationId: map['parent_location_id'] as String?,
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
      'location_type': locationType,
      'parent_location_id': parentLocationId,
      'notes': notes,
      'is_edited': isEdited ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Location copyWith({
    String? id,
    String? worldId,
    String? copiedFromId,
    String? name,
    String? description,
    String? locationType,
    String? parentLocationId,
    String? notes,
    bool? isEdited,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Location(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      copiedFromId: copiedFromId ?? this.copiedFromId,
      name: name ?? this.name,
      description: description ?? this.description,
      locationType: locationType ?? this.locationType,
      parentLocationId: parentLocationId ?? this.parentLocationId,
      notes: notes ?? this.notes,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
