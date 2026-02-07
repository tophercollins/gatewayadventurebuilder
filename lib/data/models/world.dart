/// World model - container for campaigns, NPCs, locations, items.
/// Auto-created when first campaign is made.
class World {
  const World({
    required this.id,
    required this.userId,
    required this.name,
    this.description,
    this.gameSystem,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String userId;
  final String name;
  final String? description;
  final String? gameSystem;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory World.fromMap(Map<String, dynamic> map) {
    return World(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      gameSystem: map['game_system'] as String?,
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
      'description': description,
      'game_system': gameSystem,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  World copyWith({
    String? id,
    String? userId,
    String? name,
    String? description,
    String? gameSystem,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return World(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      description: description ?? this.description,
      gameSystem: gameSystem ?? this.gameSystem,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
