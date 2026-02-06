/// Prompt template for dedicated location extraction.
class LocationPrompt {
  const LocationPrompt._();

  /// Builds the prompt for location extraction.
  static String build({
    required String gameSystem,
    required String campaignName,
    required List<String> attendeeNames,
    required List<String> existingLocationNames,
  }) {
    final attendeeList = attendeeNames.isEmpty
        ? 'No attendee information available'
        : attendeeNames.join(', ');

    final existingLocations = existingLocationNames.isEmpty
        ? 'None recorded yet'
        : existingLocationNames.join(', ');

    return '''
You are an expert at analyzing TTRPG sessions. Extract all locations mentioned in this session transcript into a precise JSON format.

## Context
- Game System: $gameSystem
- Campaign: $campaignName
- Session Attendees: $attendeeList

## Known Locations from Previous Sessions
Use the EXACT same name when referring to returning locations:
$existingLocations

## Extraction Rules
- Extract every named place, region, or area where events occur or that is meaningfully referenced
- Include both visited locations and locations that are discussed or planned as destinations
- Provide a location type based on the description in the transcript

## Type Suggestions
Common types: city, town, village, dungeon, wilderness, tavern, temple, castle, ship, plane, cave, forest, mountain, ruins, shop, guild_hall, camp. Use whichever fits best.

## Guidelines
- Use exact names from the known locations list for returning places
- Only extract locations that are actually named or clearly identifiable
- Be conservative: only extract what is clearly in the transcript
- Use null for any field where information is not available

## Output Format
Return strictly valid JSON with no markdown formatting (no ```json blocks). Use the exact keys below. Use null for missing values, not empty strings.

{
  "locations": [
    {
      "name": "String — Location name",
      "description": "String or null — Brief description of the place",
      "location_type": "String or null — Type (city, town, dungeon, tavern, wilderness, etc.)",
      "context": "String or null — What happened at or regarding this location",
      "timestamp_ms": "int or null — When first mentioned"
    }
  ]
}

## Example Output
{
  "locations": [
    {
      "name": "The Blind Basilisk",
      "description": "A dimly lit tavern in the dock ward, known for shady dealings",
      "location_type": "tavern",
      "context": "Where the party met Captain Voss and accepted the investigation job",
      "timestamp_ms": null
    },
    {
      "name": "Ironhold Mines",
      "description": "An active mining complex north of town, recently plagued by disappearances",
      "location_type": "dungeon",
      "context": "The party's destination for their investigation mission",
      "timestamp_ms": null
    }
  ]
}

Transcript:
''';
  }
}
