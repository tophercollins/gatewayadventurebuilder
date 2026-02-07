/// Player model - real people who play across campaigns.
class Player {
  const Player({
    required this.id,
    required this.userId,
    required this.name,
    this.notes,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? notes;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      notes: map['notes'] as String?,
      imagePath: map['image_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'notes': notes,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Player copyWith({
    String? id,
    String? userId,
    String? name,
    String? notes,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Player(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Campaign-Character link for many-to-many relationship.
class CampaignCharacter {
  const CampaignCharacter({
    required this.id,
    required this.campaignId,
    required this.characterId,
    required this.joinedAt,
  });

  final String id;
  final String campaignId;
  final String characterId;
  final DateTime joinedAt;

  factory CampaignCharacter.fromMap(Map<String, dynamic> map) {
    return CampaignCharacter(
      id: map['id'] as String,
      campaignId: map['campaign_id'] as String,
      characterId: map['character_id'] as String,
      joinedAt: DateTime.parse(map['joined_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'campaign_id': campaignId,
      'character_id': characterId,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}

/// Campaign-Player link for many-to-many relationship.
class CampaignPlayer {
  const CampaignPlayer({
    required this.id,
    required this.campaignId,
    required this.playerId,
    required this.joinedAt,
  });

  final String id;
  final String campaignId;
  final String playerId;
  final DateTime joinedAt;

  factory CampaignPlayer.fromMap(Map<String, dynamic> map) {
    return CampaignPlayer(
      id: map['id'] as String,
      campaignId: map['campaign_id'] as String,
      playerId: map['player_id'] as String,
      joinedAt: DateTime.parse(map['joined_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'campaign_id': campaignId,
      'player_id': playerId,
      'joined_at': joinedAt.toIso8601String(),
    };
  }
}
