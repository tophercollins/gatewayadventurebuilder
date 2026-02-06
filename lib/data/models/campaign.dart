/// Campaign model - a specific adventure within a world.
class Campaign {
  const Campaign({
    required this.id,
    required this.worldId,
    required this.name,
    this.description,
    this.gameSystem,
    this.status = CampaignStatus.active,
    this.startDate,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String worldId;
  final String name;
  final String? description;
  final String? gameSystem;
  final CampaignStatus status;
  final DateTime? startDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Campaign.fromMap(Map<String, dynamic> map) {
    return Campaign(
      id: map['id'] as String,
      worldId: map['world_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      gameSystem: map['game_system'] as String?,
      status: CampaignStatus.fromString(map['status'] as String?),
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'] as String)
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'world_id': worldId,
      'name': name,
      'description': description,
      'game_system': gameSystem,
      'status': status.value,
      'start_date': startDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Campaign copyWith({
    String? id,
    String? worldId,
    String? name,
    String? description,
    String? gameSystem,
    CampaignStatus? status,
    DateTime? startDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Campaign(
      id: id ?? this.id,
      worldId: worldId ?? this.worldId,
      name: name ?? this.name,
      description: description ?? this.description,
      gameSystem: gameSystem ?? this.gameSystem,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum CampaignStatus {
  active('active'),
  paused('paused'),
  completed('completed');

  const CampaignStatus(this.value);
  final String value;

  static CampaignStatus fromString(String? value) {
    return CampaignStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => CampaignStatus.active,
    );
  }
}
