/// Splits long transcripts into overlapping chunks for processing.
///
/// Gemini 2.5 Flash supports ~1M tokens (~4M chars), but very long
/// transcripts benefit from chunking for reliability. The threshold
/// is set conservatively at 1.5M characters (~40 hours of transcript).
class TranscriptChunker {
  const TranscriptChunker._();

  /// Maximum characters per chunk before splitting.
  static const int maxChunkChars = 1500000;

  /// Overlap between chunks to avoid missing entities at boundaries.
  static const int overlapChars = 25000;

  /// Returns the transcript as-is if under threshold, or split into
  /// overlapping chunks on paragraph boundaries.
  static List<String> chunkIfNeeded(String transcript) {
    if (transcript.length <= maxChunkChars) {
      return [transcript];
    }

    final chunks = <String>[];
    var start = 0;

    while (start < transcript.length) {
      var end = start + maxChunkChars;
      if (end >= transcript.length) {
        chunks.add(transcript.substring(start));
        break;
      }

      // Find a paragraph boundary near the end
      final boundary = _findParagraphBoundary(transcript, end);
      chunks.add(transcript.substring(start, boundary));

      // Next chunk starts with overlap
      start = boundary - overlapChars;
      if (start < 0) start = 0;
    }

    return chunks;
  }

  /// Finds the nearest paragraph break (double newline) near [position].
  /// Searches backwards up to 10000 chars to find a clean break.
  static int _findParagraphBoundary(String text, int position) {
    final searchStart = (position - 10000).clamp(0, text.length);
    final searchRegion = text.substring(searchStart, position);
    final lastBreak = searchRegion.lastIndexOf('\n\n');
    if (lastBreak != -1) {
      return searchStart + lastBreak + 2;
    }
    // Fall back to single newline
    final lastNewline = searchRegion.lastIndexOf('\n');
    if (lastNewline != -1) {
      return searchStart + lastNewline + 1;
    }
    // No good boundary — just split at position
    return position;
  }
}
