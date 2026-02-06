/// Prompt template for dedicated NPC extraction.
class NpcPrompt {
  const NpcPrompt._();

  /// Builds the prompt for NPC extraction.
  static String build({
    required String gameSystem,
    required String campaignName,
    required List<String> attendeeNames,
    required List<String> existingNpcNames,
  }) {
    final attendeeList = attendeeNames.isEmpty
        ? 'No attendee information available'
        : attendeeNames.join(', ');

    final existingNpcs = existingNpcNames.isEmpty
        ? 'None recorded yet'
        : existingNpcNames.join(', ');

    return '''
You are an expert at analyzing TTRPG sessions. Extract all non-player characters (NPCs) mentioned in this session transcript into a precise JSON format.

## Context
- Game System: $gameSystem
- Campaign: $campaignName
- Session Attendees (Player Characters — do NOT extract these): $attendeeList

## Known NPCs from Previous Sessions
Use the EXACT same name when referring to returning NPCs:
$existingNpcs

## Extraction Rules
- Extract every NPC mentioned by name or clearly identifiable title
- Do NOT include player characters: $attendeeList
- Include unnamed but significant NPCs with a descriptive identifier (e.g. "The Hooded Stranger", "Guard Captain")
- Provide a role suggestion based on their behavior in the session

## Role Suggestions
Common roles: ally, enemy, merchant, quest_giver, neutral, informant, authority, rival, patron. Use whichever fits best, or use a custom role if none fit.

## Guidelines
- Use exact names from the known NPCs list for returning characters
- Only extract NPCs who are actually present or meaningfully referenced
- Be conservative: only extract what is clearly in the transcript
- Use null for any field where information is not available

## Output Format
Return strictly valid JSON with no markdown formatting (no ```json blocks). Use the exact keys below. Use null for missing values, not empty strings.

{
  "npcs": [
    {
      "name": "String — NPC name or identifying title",
      "description": "String or null — Brief physical or personality description",
      "role": "String or null — Their role (ally, enemy, merchant, quest_giver, neutral, etc.)",
      "context": "String or null — What they did or said in this session",
      "timestamp_ms": "int or null — When they first appeared"
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
    },
    {
      "name": "Old Meg",
      "description": "Elderly halfling herbalist with a knowing smile",
      "role": "informant",
      "context": "Warned the party about strange lights in the mine at night",
      "timestamp_ms": null
    }
  ]
}

Transcript:
''';
  }
}
