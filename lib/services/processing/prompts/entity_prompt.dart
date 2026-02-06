/// Prompt template for entity extraction (NPCs, locations, items).
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
You are an expert at analyzing TTRPG sessions. Extract all NPCs, locations, and items mentioned in this session transcript.

## Context
- Game System: $gameSystem
- Campaign: $campaignName
- Session Attendees (Player Characters): $attendeeList

## Known Entities from Previous Sessions
These entities already exist in our database. If you encounter them again, use the EXACT same name:
- NPCs: $existingNpcs
- Locations: $existingLocations
- Items: $existingItems

## Instructions
1. Identify all NON-PLAYER CHARACTERS (NPCs) mentioned
   - Include their name, description if available, and role
   - Do NOT include player characters ($attendeeList)
   - Role options: ally, enemy, merchant, quest_giver, neutral, unknown

2. Identify all LOCATIONS mentioned
   - Include name, description if available, and type
   - Type options: city, town, village, dungeon, wilderness, tavern, temple, castle, ship, plane, unknown

3. Identify all significant ITEMS mentioned
   - Focus on named/unique items, magic items, quest items
   - Skip mundane items (regular weapons, basic supplies)
   - Type options: weapon, armor, consumable, quest_item, treasure, artifact, unknown

## Output Format
Respond ONLY with valid JSON in this exact format:
```json
{
  "npcs": [
    {
      "name": "NPC Name",
      "description": "Brief physical or personality description",
      "role": "ally|enemy|merchant|quest_giver|neutral|unknown",
      "context": "What they did or said in this session",
      "timestamp_ms": null
    }
  ],
  "locations": [
    {
      "name": "Location Name",
      "description": "Brief description of the place",
      "location_type": "city|town|village|dungeon|wilderness|tavern|temple|castle|ship|plane|unknown",
      "context": "What happened at this location",
      "timestamp_ms": null
    }
  ],
  "items": [
    {
      "name": "Item Name",
      "description": "Brief description of the item",
      "item_type": "weapon|armor|consumable|quest_item|treasure|artifact|unknown",
      "properties": "Magical or special properties if mentioned",
      "context": "How the item was encountered or used",
      "timestamp_ms": null
    }
  ]
}
```

## Guidelines
- Use exact names from the known entities list when referring to returning characters/places
- Only extract entities that are actually named or clearly identifiable
- Provide context showing how the entity appeared in this session
- Be conservative: only extract what's clearly in the transcript
''';
  }
}
