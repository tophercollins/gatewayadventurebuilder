/// NPC quote model - key quotes from NPCs extracted from sessions.
class NpcQuote {
  const NpcQuote({
    required this.id,
    required this.npcId,
    required this.sessionId,
    required this.quoteText,
    this.context,
    this.timestampMs,
    required this.createdAt,
  });

  final String id;
  final String npcId;
  final String sessionId;
  final String quoteText;
  final String? context;
  final int? timestampMs;
  final DateTime createdAt;

  factory NpcQuote.fromMap(Map<String, dynamic> map) {
    return NpcQuote(
      id: map['id'] as String,
      npcId: map['npc_id'] as String,
      sessionId: map['session_id'] as String,
      quoteText: map['quote_text'] as String,
      context: map['context'] as String?,
      timestampMs: map['timestamp_ms'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'npc_id': npcId,
      'session_id': sessionId,
      'quote_text': quoteText,
      'context': context,
      'timestamp_ms': timestampMs,
      'created_at': createdAt.toIso8601String(),
    };
  }

  NpcQuote copyWith({
    String? id,
    String? npcId,
    String? sessionId,
    String? quoteText,
    String? context,
    int? timestampMs,
    DateTime? createdAt,
  }) {
    return NpcQuote(
      id: id ?? this.id,
      npcId: npcId ?? this.npcId,
      sessionId: sessionId ?? this.sessionId,
      quoteText: quoteText ?? this.quoteText,
      context: context ?? this.context,
      timestampMs: timestampMs ?? this.timestampMs,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
