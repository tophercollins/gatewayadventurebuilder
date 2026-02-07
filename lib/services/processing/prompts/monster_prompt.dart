/// Prompt template for dedicated monster/creature extraction.
class MonsterPrompt {
  const MonsterPrompt._();

  /// Builds the prompt for monster extraction.
  static String build({
    required String gameSystem,
    required String campaignName,
    required List<String> attendeeNames,
    required List<String> existingMonsterNames,
  }) {
    final attendeeList = attendeeNames.isEmpty
        ? 'No attendee information available'
        : attendeeNames.join(', ');

    final existingMonsters = existingMonsterNames.isEmpty
        ? 'None recorded yet'
        : existingMonsterNames.join(', ');

    return '''
You are an expert at analyzing TTRPG sessions. Extract all monsters, creatures, and enemies mentioned in this session transcript into a precise JSON format.

## Context
- Game System: $gameSystem
- Campaign: $campaignName
- Session Attendees: $attendeeList

## Known Monsters from Previous Sessions
Use the EXACT same name when referring to returning monsters:
$existingMonsters

## Extraction Rules
- Extract named or notable monsters, creatures, and enemy types
- Include bosses, minions, wild creatures, summoned beings, and hostile entities
- Do NOT include player characters, friendly NPCs, or allied creatures
- Treat monster names as types (e.g., "Goblin", "Shadow Wolf") not individuals
- If a specific named monster is encountered (e.g., "Strahd"), still extract it

## Type Suggestions
Common types: dragon, undead, beast, aberration, construct, elemental, fey, fiend, giant, humanoid, monstrosity, ooze, plant, celestial, swarm. Use whichever fits best.

## Guidelines
- Use exact names from the known monsters list for returning monsters
- Only extract monsters that are actually named or clearly referenced
- Be conservative: only extract what is clearly in the transcript
- Use null for any field where information is not available

## Output Format
Return strictly valid JSON with no markdown formatting (no ```json blocks). Use the exact keys below. Use null for missing values, not empty strings.

{
  "monsters": [
    {
      "name": "String — Monster/creature name",
      "description": "String or null — Brief description",
      "monster_type": "String or null — Type (dragon, undead, beast, etc.)",
      "context": "String or null — How the monster was encountered",
      "timestamp_ms": "int or null — When first mentioned"
    }
  ]
}

## Example Output
{
  "monsters": [
    {
      "name": "Shadow Wolf",
      "description": "A wolf made of living shadow with glowing red eyes",
      "monster_type": "monstrosity",
      "context": "Pack of shadow wolves ambushed the party on the forest road",
      "timestamp_ms": null
    },
    {
      "name": "Bone Golem",
      "description": "A massive construct assembled from the bones of fallen warriors",
      "monster_type": "construct",
      "context": "Guardian of the necromancer's inner sanctum",
      "timestamp_ms": null
    }
  ]
}

Transcript:
''';
  }
}
