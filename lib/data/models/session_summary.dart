/// Session summary model - AI-generated, GM-editable summary.
class SessionSummary {
  const SessionSummary({
    required this.id,
    required this.sessionId,
    this.transcriptId,
    this.overallSummary,
    this.isEdited = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sessionId;
  final String? transcriptId;
  final String? overallSummary;
  final bool isEdited;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory SessionSummary.fromMap(Map<String, dynamic> map) {
    return SessionSummary(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      transcriptId: map['transcript_id'] as String?,
      overallSummary: map['overall_summary'] as String?,
      isEdited: (map['is_edited'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'transcript_id': transcriptId,
      'overall_summary': overallSummary,
      'is_edited': isEdited ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  SessionSummary copyWith({
    String? id,
    String? sessionId,
    String? transcriptId,
    String? overallSummary,
    bool? isEdited,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SessionSummary(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      transcriptId: transcriptId ?? this.transcriptId,
      overallSummary: overallSummary ?? this.overallSummary,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
