/// Prompt template for scene identification.
class ScenePrompt {
  const ScenePrompt._();

  /// Builds the prompt for scene extraction.
  static String build({
    required String gameSystem,
    required String campaignName,
    required List<String> attendeeNames,
    required int? sessionDurationMs,
  }) {
    final attendeeList = attendeeNames.isEmpty
        ? 'No attendee information available'
        : attendeeNames.join(', ');

    final durationHint = sessionDurationMs != null
        ? 'Session duration: approximately ${(sessionDurationMs / 60000).round()} minutes'
        : 'Session duration: unknown';

    return '''
You are an expert at analyzing TTRPG sessions. Identify distinct scenes or segments within this session transcript and extract them into a precise JSON format.

## Context
- Game System: $gameSystem
- Campaign: $campaignName
- Session Attendees: $attendeeList
- $durationHint

## What Constitutes a Scene
A scene is a distinct segment of play with a consistent location or setting, a clear beginning and natural endpoint, and a unified dramatic purpose (combat, roleplay, exploration, puzzle).

Common scene boundaries include:
- Location changes (entering a new area)
- Time skips
- Transitions between roleplay and combat
- New NPC introductions
- Major decisions or turning points

## Guidelines
- Identify 3-8 scenes for a typical 3-4 hour session
- Scenes should be in chronological order
- Each scene title should be unique and descriptive (3-6 words)
- Scene summaries should capture the key events in 2-3 sentences
- Do not create scenes shorter than a few minutes of play
- If timestamps are visible in the transcript (like [00:15:23]), convert them to milliseconds. Otherwise use null.

## Output Format
Return strictly valid JSON with no markdown formatting (no ```json blocks). Use the exact keys below. Use null for missing values, not empty strings.

{
  "scenes": [
    {
      "title": "String — Brief descriptive title (3-6 words)",
      "summary": "String — 2-3 sentence description of what happened",
      "start_time_ms": "int or null — Start timestamp in milliseconds",
      "end_time_ms": "int or null — End timestamp in milliseconds"
    }
  ]
}

## Example Output
{
  "scenes": [
    {
      "title": "Planning at the Silver Stag",
      "summary": "The party gathered at the inn to discuss their next move. Kira shared intelligence about the merchant guild's smuggling operation, and the group debated whether to confront them directly or gather more evidence.",
      "start_time_ms": null,
      "end_time_ms": null
    },
    {
      "title": "Warehouse Infiltration",
      "summary": "Under cover of the harvest festival, the party snuck into the guild warehouse. They navigated past guards and magical wards, searching for evidence of the weapon smuggling ring.",
      "start_time_ms": null,
      "end_time_ms": null
    },
    {
      "title": "Shadow Hound Ambush",
      "summary": "A magical alarm triggered on the third floor, summoning guild enforcers and a shadow hound. The party fought their way out, with Torvin's Silence spell providing critical cover for their escape.",
      "start_time_ms": null,
      "end_time_ms": null
    }
  ]
}

Transcript:
''';
  }
}
