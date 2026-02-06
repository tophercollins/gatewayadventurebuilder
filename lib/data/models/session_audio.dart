/// Session audio model - IMMUTABLE raw audio file reference.
/// Never modified or deleted (unless user requests for privacy).
class SessionAudio {
  const SessionAudio({
    required this.id,
    required this.sessionId,
    required this.filePath,
    this.fileSizeBytes,
    this.format,
    this.durationSeconds,
    this.checksum,
    required this.createdAt,
  });

  final String id;
  final String sessionId;
  final String filePath;
  final int? fileSizeBytes;
  final String? format;
  final int? durationSeconds;
  final String? checksum;
  final DateTime createdAt;

  factory SessionAudio.fromMap(Map<String, dynamic> map) {
    return SessionAudio(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      filePath: map['file_path'] as String,
      fileSizeBytes: map['file_size_bytes'] as int?,
      format: map['format'] as String?,
      durationSeconds: map['duration_seconds'] as int?,
      checksum: map['checksum'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'file_path': filePath,
      'file_size_bytes': fileSizeBytes,
      'format': format,
      'duration_seconds': durationSeconds,
      'checksum': checksum,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Note: No copyWith() - this model is immutable after creation
}
