/// Prompt template for entity extraction (NPCs, locations, items).
/// Used as fallback when dedicated per-entity prompts are not available.
class EntityPrompt {
  const EntityPrompt._();

  /// Builds the prompt for entity extraction.
  static String build({
    required String gameSystem,
    required String campaignName,
    required List<String> attendeeNames,
    required List<String> existingNpcNames,
    required List<String> existingLocationNames,
    required List<String> existingItemNames,
  }) {
    final attendeeList = attendeeNames.isEmpty
        ? 'No attendee information available'
        : attendeeNames.join(', ');

    final existingNpcs = existingNpcNames.isEmpty
        ? 'None recorded yet'
        : existingNpcNames.join(', ');

    final existingLocations = existingLocationNames.isEmpty
        ? 'None recorded yet'
        : existingLocationNames.join(', ');

    final existingItems = existingItemNames.isEmpty
        ? 'None recorded yet'
        : existingItemNames.join(', ');

    return '''
You are an expert at analyzing TTRPG sessions. Extract all NPCs, locations, and items mentioned in this session transcript into a precise JSON format.

## Context
- Game System: $gameSystem
- Campaign: $campaignName
- Session Attendees (Player Characters — do NOT extract these as NPCs): $attendeeList

## Known Entities from Previous Sessions
Use the EXACT same name when referring to returning entities:
- NPCs: $existingNpcs
- Locations: $existingLocations
- Items: $existingItems

## Extraction Rules
1. **NPCs**: All non-player characters mentioned by name or clearly identifiable title. Do NOT include player characters ($attendeeList). Provide role if apparent.
2. **Locations**: Named places where events occur. Include type if apparent.
3. **Items**: Significant named or unique items, magic items, quest items. Skip mundane equipment (regular weapons, basic supplies, rations).

## Guidelines
- Use exact names from the known entities list for returning characters/places
- Only extract entities that are actually named or clearly identifiable
- Provide context showing how the entity appeared in this session
- Be conservative: only extract what is clearly in the transcript
- Use null for any field where information is not available

## Output Format
Return strictly valid JSON with no markdown formatting (no ```json blocks). Use the exact keys below. Use null for missing values, not empty strings.

{
  "npcs": [
    {
      "name": "String — NPC name",
      "description": "String or null — Brief physical or personality description",
      "role": "String or null — e.g. ally, enemy, merchant, quest_giver, neutral",
      "context": "String or null — What they did or said in this session",
      "timestamp_ms": "int or null — When they first appeared"
    }
  ],
  "locations": [
    {
      "name": "String — Location name",
      "description": "String or null — Brief description of the place",
      "location_type": "String or null — e.g. city, town, village, dungeon, wilderness, tavern, temple, castle, ship, plane",
      "context": "String or null — What happened at this location",
      "timestamp_ms": "int or null — When first mentioned"
    }
  ],
  "items": [
    {
      "name": "String — Item name",
      "description": "String or null — Brief description",
      "item_type": "String or null — e.g. weapon, armor, consumable, quest_item, treasure, artifact",
      "properties": "String or null — Magical or special properties if mentioned",
      "context": "String or null — How the item was encountered or used",
      "timestamp_ms": "int or null — When first mentioned"
    }
  ]
}

## Example Output
{
  "npcs": [
    {
      "name": "Captain Voss",
      "description": "Scarred half-orc woman in battered plate armor",
      "role": "quest_giver",
      "context": "Hired the party to investigate disappearances in the mining district",
      "timestamp_ms": null
    }
  ],
  "locations": [
    {
      "name": "The Blind Basilisk",
      "description": "A dimly lit tavern in the dock ward, known for shady dealings",
      "location_type": "tavern",
      "context": "Where the party met Captain Voss and accepted the job",
      "timestamp_ms": null
    }
  ],
  "items": [
    {
      "name": "Voss's Signet Ring",
      "description": "An iron ring bearing the city watch emblem",
      "item_type": "quest_item",
      "properties": null,
      "context": "Given to the party as proof of authority for their investigation",
      "timestamp_ms": null
    }
  ]
}

Transcript:
''';
  }
}
