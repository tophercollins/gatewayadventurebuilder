/// Prompt template for dedicated item extraction.
class ItemPrompt {
  const ItemPrompt._();

  /// Builds the prompt for item extraction.
  static String build({
    required String gameSystem,
    required String campaignName,
    required List<String> attendeeNames,
    required List<String> existingItemNames,
  }) {
    final attendeeList = attendeeNames.isEmpty
        ? 'No attendee information available'
        : attendeeNames.join(', ');

    final existingItems = existingItemNames.isEmpty
        ? 'None recorded yet'
        : existingItemNames.join(', ');

    return '''
You are an expert at analyzing TTRPG sessions. Extract all significant items mentioned in this session transcript into a precise JSON format.

## Context
- Game System: $gameSystem
- Campaign: $campaignName
- Session Attendees: $attendeeList

## Known Items from Previous Sessions
Use the EXACT same name when referring to returning items:
$existingItems

## Extraction Rules
- Extract named, unique, or significant items: magic items, quest items, artifacts, important documents, keys, maps
- Skip mundane equipment: regular weapons, basic armor, torches, rations, rope, standard adventuring gear
- Include items that are acquired, lost, used in a notable way, or discussed as quest objectives
- Note magical or special properties when mentioned

## Type Suggestions
Common types: weapon, armor, consumable, quest_item, treasure, artifact, tool, document, key, potion, scroll, wondrous_item. Use whichever fits best.

## Guidelines
- Use exact names from the known items list for returning items
- Only extract items that are actually named or clearly significant
- Be conservative: only extract what is clearly in the transcript
- Use null for any field where information is not available

## Output Format
Return strictly valid JSON with no markdown formatting (no ```json blocks). Use the exact keys below. Use null for missing values, not empty strings.

{
  "items": [
    {
      "name": "String — Item name",
      "description": "String or null — Brief description",
      "item_type": "String or null — Type (weapon, armor, quest_item, artifact, etc.)",
      "properties": "String or null — Magical or special properties if mentioned",
      "context": "String or null — How the item was encountered or used",
      "timestamp_ms": "int or null — When first mentioned"
    }
  ]
}

## Example Output
{
  "items": [
    {
      "name": "Voss's Signet Ring",
      "description": "An iron ring bearing the city watch emblem",
      "item_type": "quest_item",
      "properties": null,
      "context": "Given to the party as proof of authority for their investigation",
      "timestamp_ms": null
    },
    {
      "name": "Shadowstone Amulet",
      "description": "A black gemstone on a silver chain that pulses with faint energy",
      "item_type": "artifact",
      "properties": "Glows when within 30 feet of undead creatures",
      "context": "Found on the body of a missing miner in the collapsed tunnel",
      "timestamp_ms": null
    }
  ]
}

Transcript:
''';
  }
}
