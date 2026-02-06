/// Item model - world-level entity shared across campaigns.
class Item {
  const Item({
    required this.id,
    required this.worldId,
    this.copiedFromId,
    required this.name,
    this.description,
    this.itemType,
    this.properties,
    this.currentOwnerType,
    this.currentOwnerId,
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
  final String? itemType;
  final String? properties;
  final String? currentOwnerType;
  final String? currentOwnerId;
  final String? notes;
  final bool isEdited;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] as String,
      worldId: map['world_id'] as String,
      copiedFromId: map['copied_from_id'] as String?,
      name: map['name'] as String,
      description: map['description'] as String?,
      itemType: map['item_type'] as String?,
      properties: map['properties'] as String?,
      currentOwnerType: map['current_owner_type'] as String?,
      currentOwnerId: map['current_owner_id'] as String?,
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
      'item_type': itemType,
      'properties': properties,
      'current_owner_type': currentOwnerType,
      'current_owner_id': currentOwnerId,
      'notes': notes,
      'is_edited': isEdited ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Item copyWith({
    String? id,
    String? worldId,
    String? copiedFromId,
    String? name,
    String? description,
    String? itemType,
    String? properties,
    String? currentOwnerType,
    String? currentOwnerId,
    String? notes,
    bool? isEdited,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      copiedFromId: copiedFromId ?? this.copiedFromId,
      name: name ?? this.name,
      description: description ?? this.description,
      itemType: itemType ?? this.itemType,
      properties: properties ?? this.properties,
      currentOwnerType: currentOwnerType ?? this.currentOwnerType,
      currentOwnerId: currentOwnerId ?? this.currentOwnerId,
      notes: notes ?? this.notes,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
