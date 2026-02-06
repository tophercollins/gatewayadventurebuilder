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
You are an expert at analyzing TTRPG sessions. Extract all plot threads, quests, action items, and hooks from this session transcript.

## Context
- Game System: $gameSystem
- Campaign: $campaignName
- Session Attendees: $attendeeList

## Currently Open Items from Previous Sessions
$openItems

## What to Extract

### Plot Threads
Ongoing story elements that span multiple sessions:
- Main quest objectives
- Mysteries to solve
- Villain schemes to thwart
- Political conflicts to navigate

### Action Items
Specific tasks the party has committed to:
- Promises made to NPCs
- Missions accepted
- Items to retrieve
- People to find or rescue

### Follow-ups
Things mentioned that might need attention:
- Unfinished business
- Loose ends from this session
- Things the party said they'd do "later"

### Hooks
New opportunities or leads introduced:
- Rumors heard
- Potential quests offered
- Hints about future adventures
- Foreshadowing from the GM

## Output Format
Respond ONLY with valid JSON in this exact format:
```json
{
  "action_items": [
    {
      "title": "Brief title (5-10 words)",
      "description": "1-2 sentence description of the item",
      "action_type": "plot_thread|action_item|follow_up|hook"
    }
  ]
}
```

## Guidelines
- Check against open items: note if any existing items were resolved or advanced
- Don't duplicate items from the open items list unless there's new information
- Be specific about names and places
- Focus on actionable or narratively significant items
- A typical session might have 3-8 new items
''';
  }
}
