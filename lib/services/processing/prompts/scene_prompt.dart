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
You are an expert at analyzing TTRPG sessions. Identify distinct scenes or segments within this session transcript.

## Context
- Game System: $gameSystem
- Campaign: $campaignName
- Session Attendees: $attendeeList
- $durationHint

## What Constitutes a Scene
A scene is a distinct segment of play that has:
- A consistent location or setting
- A clear beginning and natural endpoint
- A unified dramatic purpose (e.g., combat, roleplay, exploration, puzzle)

Common scene boundaries include:
- Location changes (entering a new area)
- Time skips
- Transitions between roleplay and combat
- New NPC introductions
- Major decisions or turning points

## Output Format
Respond ONLY with valid JSON in this exact format:
```json
{
  "scenes": [
    {
      "title": "Brief descriptive title (3-6 words)",
      "summary": "2-3 sentence description of what happened in this scene",
      "start_time_ms": null,
      "end_time_ms": null
    }
  ]
}
```

Note: If timestamps are visible in the transcript (like [00:15:23]), convert them to milliseconds for start_time_ms and end_time_ms. Otherwise, leave them as null.

## Guidelines
- Identify 3-8 scenes for a typical 3-4 hour session
- Scenes should be in chronological order
- Each scene title should be unique and descriptive
- Scene summaries should capture the key events
- Don't create scenes shorter than a few minutes of play
''';
  }
}
