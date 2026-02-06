/// Session transcript model.
/// `rawText` is IMMUTABLE — the original Whisper/Gemini output.
/// `editedText` is the user's editable copy (null until first edit).
class SessionTranscript {
  const SessionTranscript({
    required this.id,
    required this.sessionId,
    this.version = 1,
    required this.rawText,
    this.editedText,
    this.whisperModel,
    this.language = 'en',
    required this.createdAt,
  });

  final String id;
  final String sessionId;
  final int version;
  final String rawText;
  final String? editedText;
  final String? whisperModel;
  final String language;
  final DateTime createdAt;

  /// The text the user should see — edited version if available, raw otherwise.
  String get displayText => editedText ?? rawText;

  /// Whether the user has edited this transcript.
  bool get isEdited => editedText != null;

  factory SessionTranscript.fromMap(Map<String, dynamic> map) {
    return SessionTranscript(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      version: (map['version'] as int?) ?? 1,
      rawText: map['raw_text'] as String,
      editedText: map['edited_text'] as String?,
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
      'edited_text': editedText,
      'whisper_model': whisperModel,
      'language': language,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
