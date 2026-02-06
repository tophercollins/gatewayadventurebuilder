/// Prompt template for generating session summaries.
class SummaryPrompt {
  const SummaryPrompt._();

  /// Builds the prompt for session summary generation.
  static String build({
    required String gameSystem,
    required String campaignName,
    required List<String> attendeeNames,
  }) {
    final attendeeList = attendeeNames.isEmpty
        ? 'No attendee information available'
        : attendeeNames.join(', ');

    return '''
You are an expert TTRPG session summarizer. Analyze the following transcript from a tabletop RPG session and generate a comprehensive summary.

## Context
- Game System: $gameSystem
- Campaign: $campaignName
- Session Attendees: $attendeeList

## Instructions
1. Read the entire transcript carefully
2. Identify the major events, decisions, and outcomes
3. Note any character development or relationship changes
4. Capture the narrative arc of the session
5. Write a summary that would help someone who missed the session catch up

## Output Format
Respond ONLY with valid JSON in this exact format:
```json
{
  "overall_summary": "A comprehensive 2-4 paragraph summary of the session, capturing the key events, decisions, character moments, and overall narrative progression. Write in past tense, third person."
}
```

## Guidelines
- Be specific about character names and locations
- Mention important NPCs encountered
- Note any combat encounters and their outcomes
- Highlight key plot revelations or mysteries introduced
- Keep the summary engaging but factual
- Do not include speculation beyond what's in the transcript
''';
  }
}
