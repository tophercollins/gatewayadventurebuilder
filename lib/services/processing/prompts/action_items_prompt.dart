/// Prompt template for action items and plot threads extraction.
class ActionItemsPrompt {
  const ActionItemsPrompt._();

  /// Builds the prompt for action item extraction.
  static String build({
    required String gameSystem,
    required String campaignName,
    required List<String> attendeeNames,
    required List<String> existingOpenItems,
  }) {
    final attendeeList = attendeeNames.isEmpty
        ? 'No attendee information available'
        : attendeeNames.join(', ');

    final openItems = existingOpenItems.isEmpty
        ? 'None'
        : existingOpenItems.map((e) => '- $e').join('\n');

    return '''
You are an expert at analyzing TTRPG sessions. Extract all plot threads, quests, action items, and hooks from this session transcript into a precise JSON format.

## Context
- Game System: $gameSystem
- Campaign: $campaignName
- Session Attendees: $attendeeList

## Currently Open Items from Previous Sessions
$openItems

## What to Extract
- **plot_thread**: Ongoing story elements spanning multiple sessions (main quest objectives, mysteries, villain schemes, political conflicts)
- **action_item**: Specific tasks the party committed to (promises to NPCs, accepted missions, items to retrieve, people to find)
- **follow_up**: Unfinished business or loose ends from this session, things the party said they would do "later"
- **hook**: New opportunities or leads introduced (rumors heard, potential quests offered, hints about future adventures, GM foreshadowing)

## Guidelines
- Check against open items: note if any existing items were resolved or advanced
- Do not duplicate items from the open items list unless there is new information
- Be specific about names and places
- Focus on actionable or narratively significant items
- A typical session might have 3-8 new items
- Use null for any field where information is not available

## Output Format
Return strictly valid JSON with no markdown formatting (no ```json blocks). Use the exact keys below. Use null for missing values, not empty strings.

{
  "action_items": [
    {
      "title": "String — Brief title (5-10 words)",
      "description": "String or null — 1-2 sentence description",
      "action_type": "String — One of: plot_thread, action_item, follow_up, hook"
    }
  ]
}

## Example Output
{
  "action_items": [
    {
      "title": "Investigate disappearances in the mining district",
      "description": "Captain Voss hired the party to find out why miners have been vanishing. Three have gone missing in the last two weeks.",
      "action_type": "plot_thread"
    },
    {
      "title": "Return Voss's signet ring after the investigation",
      "description": "The party promised to return the ring once they no longer need it as proof of authority.",
      "action_type": "action_item"
    },
    {
      "title": "Strange sounds from the deep tunnels",
      "description": "A miner mentioned hearing chanting from a sealed-off section of the mine. The party noted it but did not investigate yet.",
      "action_type": "hook"
    }
  ]
}

Transcript:
''';
  }
}
