/// NPC model - world-level entity shared across campaigns.
class Npc {
  const Npc({
    required this.id,
    required this.worldId,
    this.copiedFromId,
    required this.name,
    this.description,
    this.role,
    this.status = NpcStatus.alive,
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
  final String? role;
  final NpcStatus status;
  final String? notes;
  final bool isEdited;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Npc.fromMap(Map<String, dynamic> map) {
    return Npc(
      id: map['id'] as String,
      worldId: map['world_id'] as String,
      copiedFromId: map['copied_from_id'] as String?,
      name: map['name'] as String,
      description: map['description'] as String?,
      role: map['role'] as String?,
      status: NpcStatus.fromString(map['status'] as String?),
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
      'role': role,
      'status': status.value,
      'notes': notes,
      'is_edited': isEdited ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Npc copyWith({
    String? id,
    String? worldId,
    String? copiedFromId,
    String? name,
    String? description,
    String? role,
    NpcStatus? status,
    String? notes,
    bool? isEdited,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Npc(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      copiedFromId: copiedFromId ?? this.copiedFromId,
      name: name ?? this.name,
      description: description ?? this.description,
      role: role ?? this.role,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum NpcStatus {
  alive('alive'),
  dead('dead'),
  unknown('unknown'),
  missing('missing');

  const NpcStatus(this.value);
  final String value;

  static NpcStatus fromString(String? value) {
    return NpcStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => NpcStatus.alive,
    );
  }
}
