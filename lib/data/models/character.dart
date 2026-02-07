/// Character model - fictional characters played by players in a campaign.
class Character {
  const Character({
    required this.id,
    required this.playerId,
    required this.name,
    this.characterClass,
    this.race,
    this.level,
    this.backstory,
    this.goals,
    this.notes,
    this.status = CharacterStatus.active,
    this.imagePath,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String playerId;
  final String name;
  final String? characterClass;
  final String? race;
  final int? level;
  final String? backstory;
  final String? goals;
  final String? notes;
  final CharacterStatus status;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Character.fromMap(Map<String, dynamic> map) {
    return Character(
      id: map['id'] as String,
      playerId: map['player_id'] as String,
      name: map['name'] as String,
      characterClass: map['character_class'] as String?,
      race: map['race'] as String?,
      level: map['level'] as int?,
      backstory: map['backstory'] as String?,
      goals: map['goals'] as String?,
      notes: map['notes'] as String?,
      status: CharacterStatus.fromString(map['status'] as String?),
      imagePath: map['image_path'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'player_id': playerId,
      'name': name,
      'character_class': characterClass,
      'race': race,
      'level': level,
      'backstory': backstory,
      'goals': goals,
      'notes': notes,
      'status': status.value,
      'image_path': imagePath,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Character copyWith({
    String? id,
    String? playerId,
    String? name,
    String? characterClass,
    String? race,
    int? level,
    String? backstory,
    String? goals,
    String? notes,
    CharacterStatus? status,
    String? imagePath,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Character(
      id: id ?? this.id,
      playerId: playerId ?? this.playerId,
      name: name ?? this.name,
      characterClass: characterClass ?? this.characterClass,
      race: race ?? this.race,
      level: level ?? this.level,
      backstory: backstory ?? this.backstory,
      goals: goals ?? this.goals,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum CharacterStatus {
  active('active'),
  retired('retired'),
  dead('dead');

  const CharacterStatus(this.value);
  final String value;

  static CharacterStatus fromString(String? value) {
    return CharacterStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => CharacterStatus.active,
    );
  }
}
