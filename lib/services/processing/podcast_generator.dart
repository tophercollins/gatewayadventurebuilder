import 'llm_service.dart';

/// Generates podcast-style recap scripts from session data using AI.
class PodcastGenerator {
  PodcastGenerator({required LLMService llmService}) : _llmService = llmService;

  final LLMService _llmService;

  /// Generates a short (~2-3 minute read) podcast-style recap script
  /// from a session summary and transcript.
  ///
  /// The script is written in a radio host/narrator style, hitting key
  /// story beats, dramatic moments, and player highlights.
  Future<LLMResult<String>> generateScript({
    required String summary,
    required String transcript,
    required String campaignName,
    List<String>? attendeeNames,
  }) async {
    final attendeeSection = attendeeNames != null && attendeeNames.isNotEmpty
        ? '\nPlayers at this session: ${attendeeNames.join(', ')}'
        : '';

    final prompt = '''
You are a charismatic radio host narrating a recap of a tabletop RPG session. Write a short podcast-style script (roughly 2-3 minutes when read aloud, about 350-500 words) that recaps this session of "$campaignName".$attendeeSection

Guidelines:
- Open with an engaging hook that draws listeners in.
- Hit the key story beats and dramatic moments from the session.
- Call out specific player highlights and memorable actions by name.
- Use vivid, energetic language — think "actual play podcast recap" tone.
- Include natural transitions between story beats.
- Close with a teaser or cliffhanger for what might come next.
- Write it as a single narrator script (no dialogue tags or speaker labels).
- Do NOT include any stage directions, sound effects notes, or production cues.
- Output ONLY the script text, no titles, headers, or metadata.

Session Summary:
$summary

Full Transcript:
$transcript
''';

    return await _llmService.generateText(prompt: prompt);
  }
}
