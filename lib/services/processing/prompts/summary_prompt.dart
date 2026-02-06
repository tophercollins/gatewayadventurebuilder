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
You are an expert TTRPG session summarizer. Analyze the following session transcript and extract a structured summary into a precise JSON format.

## Context
- Game System: $gameSystem
- Campaign: $campaignName
- Session Attendees: $attendeeList

## Guidelines
- Be specific about character names and locations mentioned in the transcript
- Mention important NPCs encountered and their role in events
- Note any combat encounters and their outcomes
- Highlight key plot revelations or mysteries introduced
- Capture the narrative arc: setup, key events, decisions, and conclusion
- Write in past tense, third person
- Do not include speculation beyond what is in the transcript
- If the transcript is mostly out-of-character chatter, focus on the in-game events

## Output Format
Return strictly valid JSON with no markdown formatting (no ```json blocks). Use the exact key below. Use null for missing values, not empty strings.

{
  "overall_summary": "String — A comprehensive 2-4 paragraph summary capturing the key events, decisions, character moments, and overall narrative progression."
}

## Example Output
{
  "overall_summary": "The party reunited at the Silver Stag Inn after a week apart, sharing intel gathered during downtime. Kira revealed that the merchant guild had been smuggling enchanted weapons through the docks, which explained the spike in armed bandit attacks along the northern road.\\n\\nAfter debating their next move, the group decided to infiltrate the guild warehouse under cover of the harvest festival. The heist went smoothly until they triggered a magical alarm on the third floor, leading to a tense combat encounter with two guild enforcers and a summoned shadow hound. Torvin's quick thinking with a Silence spell allowed the group to escape with the shipping manifests before reinforcements arrived."
}

Transcript:
''';
  }
}
