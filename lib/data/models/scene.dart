/// Scene model - AI-identified scenes within a session.
class Scene {
  const Scene({
    required this.id,
    required this.sessionId,
    required this.sceneIndex,
    this.title,
    this.summary,
    this.startTimeMs,
    this.endTimeMs,
    this.isEdited = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sessionId;
  final int sceneIndex;
  final String? title;
  final String? summary;
  final int? startTimeMs;
  final int? endTimeMs;
  final bool isEdited;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Scene.fromMap(Map<String, dynamic> map) {
    return Scene(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      sceneIndex: map['scene_index'] as int,
      title: map['title'] as String?,
      summary: map['summary'] as String?,
      startTimeMs: map['start_time_ms'] as int?,
      endTimeMs: map['end_time_ms'] as int?,
      isEdited: (map['is_edited'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'scene_index': sceneIndex,
      'title': title,
      'summary': summary,
      'start_time_ms': startTimeMs,
      'end_time_ms': endTimeMs,
      'is_edited': isEdited ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Scene copyWith({
    String? id,
    String? sessionId,
    int? sceneIndex,
    String? title,
    String? summary,
    int? startTimeMs,
    int? endTimeMs,
    bool? isEdited,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Scene(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      sceneIndex: sceneIndex ?? this.sceneIndex,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      startTimeMs: startTimeMs ?? this.startTimeMs,
      endTimeMs: endTimeMs ?? this.endTimeMs,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
