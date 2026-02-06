/// Prompt template for player moments extraction.
class PlayerMomentsPrompt {
  const PlayerMomentsPrompt._();

  /// Builds the prompt for player moment extraction.
  static String build({
    required String gameSystem,
    required String campaignName,
    required List<AttendeeInfo> attendees,
  }) {
    final attendeeDetails = attendees.isEmpty
        ? 'No attendee information available'
        : attendees.map((a) {
            if (a.characterName != null) {
              return '- ${a.playerName} playing ${a.characterName}';
            }
            return '- ${a.playerName}';
          }).join('\n');

    return '''
You are an expert at analyzing TTRPG sessions. Extract memorable player moments, highlights, and quotes from this session transcript.

## Context
- Game System: $gameSystem
- Campaign: $campaignName
- Session Attendees:
$attendeeDetails

## What to Extract

### Types of Moments
- **quote**: A memorable or funny line spoken in or out of character
- **combat**: An impressive combat moment (critical hit, clutch save, tactical genius)
- **roleplay**: A great character moment or interaction
- **decision**: An important choice that affected the story
- **funny**: A humorous moment or joke
- **dramatic**: An emotional or tense moment

### Guidelines for Selection
- Focus on moments that stand out from normal play
- Include direct quotes when possible
- Attribute moments to specific players/characters
- Each player should ideally have at least one moment (if they contributed)
- A typical session might have 5-15 notable moments

## Output Format
Respond ONLY with valid JSON in this exact format:
```json
{
  "player_moments": [
    {
      "player_name": "Real name of the player",
      "character_name": "Character name if applicable (null if out of character)",
      "description": "What happened in this moment",
      "moment_type": "quote|combat|roleplay|decision|funny|dramatic",
      "quote_text": "Exact quote if this is a quote moment (null otherwise)",
      "timestamp_ms": null
    }
  ]
}
```

## Examples of Good Moments
- "Sarah rolled a natural 20 on her Persuasion check, convincing the dragon to let them pass peacefully"
- "Mike's character Thorin delivered a heartfelt speech about his fallen clan"
- "'I cast Fireball... centered on myself' - Jake, causing the entire table to panic"
- "Emily's character Luna made the difficult choice to spare the bandit leader, showing mercy"

## Important
- Use the EXACT player names from the attendee list above
- Match character names exactly as listed
- Don't attribute moments to players who weren't there
- If unsure who said something, skip it rather than guess
''';
  }
}

/// Information about a session attendee for prompt building.
class AttendeeInfo {
  const AttendeeInfo({
    required this.playerId,
    required this.playerName,
    this.characterId,
    this.characterName,
  });

  final String playerId;
  final String playerName;
  final String? characterId;
  final String? characterName;
}
