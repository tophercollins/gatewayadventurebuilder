/// Prompt template for dedicated organisation/faction extraction.
class OrganisationPrompt {
  const OrganisationPrompt._();

  /// Builds the prompt for organisation extraction.
  static String build({
    required String gameSystem,
    required String campaignName,
    required List<String> attendeeNames,
    required List<String> existingOrganisationNames,
  }) {
    final attendeeList = attendeeNames.isEmpty
        ? 'No attendee information available'
        : attendeeNames.join(', ');

    final existingOrganisations = existingOrganisationNames.isEmpty
        ? 'None recorded yet'
        : existingOrganisationNames.join(', ');

    return '''
You are an expert at analyzing TTRPG sessions. Extract all organisations, factions, guilds, and groups mentioned in this session transcript into a precise JSON format.

## Context
- Game System: $gameSystem
- Campaign: $campaignName
- Session Attendees: $attendeeList

## Known Organisations from Previous Sessions
Use the EXACT same name when referring to returning organisations:
$existingOrganisations

## Extraction Rules
- Extract named organisations, factions, guilds, governments, cults, military groups, and other formal groups
- Include any group that has a name and acts as an entity in the world
- Do NOT include informal groups like "the party" or "the adventurers"
- Do NOT include races or species as organisations unless they are a specific named faction

## Type Suggestions
Common types: guild, faction, government, cult, military, mercenary, religious, criminal, noble_house, trade_company. Use whichever fits best.

## Guidelines
- Use exact names from the known organisations list for returning organisations
- Only extract organisations that are actually named or clearly referenced
- Be conservative: only extract what is clearly in the transcript
- Use null for any field where information is not available

## Output Format
Return strictly valid JSON with no markdown formatting (no ```json blocks). Use the exact keys below. Use null for missing values, not empty strings.

{
  "organisations": [
    {
      "name": "String — Organisation name",
      "description": "String or null — Brief description",
      "organisation_type": "String or null — Type (guild, faction, government, etc.)",
      "context": "String or null — How the organisation was referenced",
      "timestamp_ms": "int or null — When first mentioned"
    }
  ]
}

## Example Output
{
  "organisations": [
    {
      "name": "The Zhentarim",
      "description": "A shadowy network of mercenaries and criminals seeking power",
      "organisation_type": "criminal",
      "context": "The party discovered Zhentarim agents operating in the city",
      "timestamp_ms": null
    },
    {
      "name": "Order of the Silver Dawn",
      "description": "A holy order of paladins devoted to destroying undead",
      "organisation_type": "religious",
      "context": "The cleric sought aid from the Order at their temple",
      "timestamp_ms": null
    }
  ]
}

Transcript:
''';
  }
}
