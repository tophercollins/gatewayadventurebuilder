/// Prompt template for resync operations.
/// Used when the GM edits content and wants to propagate changes.
const resyncPrompt = '''
You are analyzing a tabletop RPG session that has been partially edited by the Game Master.
Your task is to update related content to maintain consistency with the edits.

## Context
The following content has been EDITED by the GM (preserve these edits exactly):

### Edited Entities
{edited_entities}

### Edited Summary
{edited_summary}

### Edited Scenes
{edited_scenes}

### Edited Action Items
{edited_action_items}

### Edited Player Moments
{edited_player_moments}

## Current Unedited Content (may need updates)

### Current Summary
{current_summary}

### Current Scenes
{current_scenes}

### Current Entities
{current_entities}

### Current Action Items
{current_action_items}

## Instructions
1. Review the edited content marked above
2. Identify any UNEDITED content that references or should reflect the edits
3. Propose updates ONLY to unedited content that needs to change for consistency
4. DO NOT modify any content that was edited by the GM
5. Focus on:
   - If an NPC name was changed, update references in unedited summaries
   - If a summary was edited, ensure unedited entities match the narrative
   - If an action item was resolved, ensure it's reflected in unedited summaries

## Response Format
Return a JSON object with the following structure:
```json
{
  "summary_updates": {
    "overall_summary": "updated summary text (or null if no change needed)"
  },
  "scene_updates": [
    {
      "scene_index": 0,
      "title": "updated title (or null)",
      "summary": "updated summary (or null)"
    }
  ],
  "entity_updates": {
    "npcs": [
      {
        "name": "NPC name to update",
        "description": "updated description (or null)",
        "role": "updated role (or null)"
      }
    ],
    "locations": [],
    "items": []
  },
  "action_item_updates": [
    {
      "title": "item title to match",
      "new_title": "updated title (or null)",
      "new_description": "updated description (or null)"
    }
  ]
}
```

Only include fields that need updates. Omit fields with no changes.
Return an empty JSON object {} if no updates are needed.
''';

/// Builds the resync prompt with actual content.
String buildResyncPrompt({
  required String editedEntities,
  required String editedSummary,
  required String editedScenes,
  required String editedActionItems,
  required String editedPlayerMoments,
  required String currentSummary,
  required String currentScenes,
  required String currentEntities,
  required String currentActionItems,
}) {
  return resyncPrompt
      .replaceAll('{edited_entities}', editedEntities)
      .replaceAll('{edited_summary}', editedSummary)
      .replaceAll('{edited_scenes}', editedScenes)
      .replaceAll('{edited_action_items}', editedActionItems)
      .replaceAll('{edited_player_moments}', editedPlayerMoments)
      .replaceAll('{current_summary}', currentSummary)
      .replaceAll('{current_scenes}', currentScenes)
      .replaceAll('{current_entities}', currentEntities)
      .replaceAll('{current_action_items}', currentActionItems);
}
