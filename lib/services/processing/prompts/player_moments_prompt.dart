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
        : attendees
              .map((a) {
                if (a.characterName != null) {
                  return '- ${a.playerName} playing ${a.characterName}';
                }
                return '- ${a.playerName}';
              })
              .join('\n');

    return '''
You are an expert at analyzing TTRPG sessions. Extract memorable player moments, highlights, and quotes from this session transcript into a precise JSON format.

## Context
- Game System: $gameSystem
- Campaign: $campaignName
- Session Attendees:
$attendeeDetails

## Types of Moments
- **quote**: A memorable or funny line spoken in or out of character
- **combat**: An impressive combat moment (critical hit, clutch save, tactical genius)
- **roleplay**: A great character moment or interaction
- **decision**: An important choice that affected the story
- **funny**: A humorous moment or joke
- **dramatic**: An emotional or tense moment

## Guidelines
- Focus on moments that stand out from normal play
- Include direct quotes when possible
- Attribute moments to specific players/characters
- Each player should ideally have at least one moment (if they contributed)
- A typical session might have 5-15 notable moments
- Use the EXACT player names from the attendee list above
- Match character names exactly as listed
- Do not attribute moments to players who were not present
- If unsure who said something, skip it rather than guess
- Use null for any field where information is not available

## Output Format
Return strictly valid JSON with no markdown formatting (no ```json blocks). Use the exact keys below. Use null for missing values, not empty strings.

{
  "player_moments": [
    {
      "player_name": "String — Real name of the player (must match attendee list)",
      "character_name": "String or null — Character name if applicable, null if out of character",
      "description": "String — What happened in this moment",
      "moment_type": "String — One of: quote, combat, roleplay, decision, funny, dramatic",
      "quote_text": "String or null — Exact quote if this is a quote moment, null otherwise",
      "timestamp_ms": "int or null — When this moment occurred"
    }
  ]
}

## Example Output
{
  "player_moments": [
    {
      "player_name": "Sarah",
      "character_name": "Kira Shadowmend",
      "description": "Rolled a natural 20 on her Persuasion check, convincing the guard captain to let them into the restricted archives.",
      "moment_type": "combat",
      "quote_text": null,
      "timestamp_ms": null
    },
    {
      "player_name": "Mike",
      "character_name": "Torvin Ashbeard",
      "description": "Delivered a heartfelt speech about his fallen clan while standing in the ruins of their ancestral forge.",
      "moment_type": "roleplay",
      "quote_text": null,
      "timestamp_ms": null
    },
    {
      "player_name": "Jake",
      "character_name": "Zeph",
      "description": "Announced his plan to solve the puzzle by casting Fireball centered on himself, causing the entire table to panic before revealing it was a bluff.",
      "moment_type": "funny",
      "quote_text": "I cast Fireball... centered on myself.",
      "timestamp_ms": null
    }
  ]
}

Transcript:
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
