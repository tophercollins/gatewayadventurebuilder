/// Transcript segment model - IMMUTABLE timestamped portions of transcript.
/// Enables linking to audio positions.
class TranscriptSegment {
  const TranscriptSegment({
    required this.id,
    required this.transcriptId,
    required this.segmentIndex,
    required this.startTimeMs,
    required this.endTimeMs,
    required this.text,
  });

  final String id;
  final String transcriptId;
  final int segmentIndex;
  final int startTimeMs;
  final int endTimeMs;
  final String text;

  factory TranscriptSegment.fromMap(Map<String, dynamic> map) {
    return TranscriptSegment(
      id: map['id'] as String,
      transcriptId: map['transcript_id'] as String,
      segmentIndex: map['segment_index'] as int,
      startTimeMs: map['start_time_ms'] as int,
      endTimeMs: map['end_time_ms'] as int,
      text: map['text'] as String,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'transcript_id': transcriptId,
      'segment_index': segmentIndex,
      'start_time_ms': startTimeMs,
      'end_time_ms': endTimeMs,
      'text': text,
    };
  }

  // Note: No copyWith() - this model is immutable after creation
}
