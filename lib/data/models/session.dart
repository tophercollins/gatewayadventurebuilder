/// Session model - one recording session.
class Session {
  const Session({
    required this.id,
    required this.campaignId,
    this.sessionNumber,
    this.title,
    required this.date,
    this.durationSeconds,
    this.status = SessionStatus.recording,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String campaignId;
  final int? sessionNumber;
  final String? title;
  final DateTime date;
  final int? durationSeconds;
  final SessionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory Session.fromMap(Map<String, dynamic> map) {
    return Session(
      id: map['id'] as String,
      campaignId: map['campaign_id'] as String,
      sessionNumber: map['session_number'] as int?,
      title: map['title'] as String?,
      date: DateTime.parse(map['date'] as String),
      durationSeconds: map['duration_seconds'] as int?,
      status: SessionStatus.fromString(map['status'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'campaign_id': campaignId,
      'session_number': sessionNumber,
      'title': title,
      'date': date.toIso8601String(),
      'duration_seconds': durationSeconds,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Session copyWith({
    String? id,
    String? campaignId,
    int? sessionNumber,
    String? title,
    DateTime? date,
    int? durationSeconds,
    SessionStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Session(
      id: id ?? this.id,
      campaignId: campaignId ?? this.campaignId,
      sessionNumber: sessionNumber ?? this.sessionNumber,
      title: title ?? this.title,
      date: date ?? this.date,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum SessionStatus {
  recording('recording'),
  transcribing('transcribing'),
  queued('queued'),
  processing('processing'),
  complete('complete'),
  error('error');

  const SessionStatus(this.value);
  final String value;

  static SessionStatus fromString(String? value) {
    return SessionStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => SessionStatus.recording,
    );
  }
}

/// Session attendee - which player/character was present.
class SessionAttendee {
  const SessionAttendee({
    required this.id,
    required this.sessionId,
    required this.playerId,
    this.characterId,
  });

  final String id;
  final String sessionId;
  final String playerId;
  final String? characterId;

  factory SessionAttendee.fromMap(Map<String, dynamic> map) {
    return SessionAttendee(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      playerId: map['player_id'] as String,
      characterId: map['character_id'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'player_id': playerId,
      'character_id': characterId,
    };
  }
}
