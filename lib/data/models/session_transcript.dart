/// Session transcript model - IMMUTABLE raw transcript from Whisper.
/// Reprocessing creates a new version, never modifies existing.
class SessionTranscript {
  const SessionTranscript({
    required this.id,
    required this.sessionId,
    this.version = 1,
    required this.rawText,
    this.whisperModel,
    this.language = 'en',
    required this.createdAt,
  });

  final String id;
  final String sessionId;
  final int version;
  final String rawText;
  final String? whisperModel;
  final String language;
  final DateTime createdAt;

  factory SessionTranscript.fromMap(Map<String, dynamic> map) {
    return SessionTranscript(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      version: (map['version'] as int?) ?? 1,
      rawText: map['raw_text'] as String,
      whisperModel: map['whisper_model'] as String?,
      language: (map['language'] as String?) ?? 'en',
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'version': version,
      'raw_text': rawText,
      'whisper_model': whisperModel,
      'language': language,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Note: No copyWith() - this model is immutable after creation
}
