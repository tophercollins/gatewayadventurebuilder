import 'dart:convert';

/// Response model for session summary extraction.
class SummaryResponse {
  const SummaryResponse({
    required this.overallSummary,
  });

  final String overallSummary;

  factory SummaryResponse.fromJson(Map<String, dynamic> json) {
    return SummaryResponse(
      overallSummary: json['overall_summary'] as String? ?? '',
    );
  }

  static SummaryResponse? tryParse(String text) {
    try {
      final json = jsonDecode(_extractJson(text)) as Map<String, dynamic>;
      return SummaryResponse.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}

/// Response model for scene extraction.
class ScenesResponse {
  const ScenesResponse({required this.scenes});

  final List<SceneData> scenes;

  factory ScenesResponse.fromJson(Map<String, dynamic> json) {
    final sceneList = json['scenes'] as List<dynamic>? ?? [];
    return ScenesResponse(
      scenes: sceneList.map((e) => SceneData.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  static ScenesResponse? tryParse(String text) {
    try {
      final json = jsonDecode(_extractJson(text)) as Map<String, dynamic>;
      return ScenesResponse.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}

class SceneData {
  const SceneData({
    required this.title,
    required this.summary,
    this.startTimeMs,
    this.endTimeMs,
  });

  final String title;
  final String summary;
  final int? startTimeMs;
  final int? endTimeMs;

  factory SceneData.fromJson(Map<String, dynamic> json) {
    return SceneData(
      title: json['title'] as String? ?? 'Untitled Scene',
      summary: json['summary'] as String? ?? '',
      startTimeMs: json['start_time_ms'] as int?,
      endTimeMs: json['end_time_ms'] as int?,
    );
  }
}

/// Response model for entity extraction.
class EntitiesResponse {
  const EntitiesResponse({
    required this.npcs,
    required this.locations,
    required this.items,
  });

  final List<NpcData> npcs;
  final List<LocationData> locations;
  final List<ItemData> items;

  factory EntitiesResponse.fromJson(Map<String, dynamic> json) {
    final npcList = json['npcs'] as List<dynamic>? ?? [];
    final locList = json['locations'] as List<dynamic>? ?? [];
    final itemList = json['items'] as List<dynamic>? ?? [];
    return EntitiesResponse(
      npcs: npcList.map((e) => NpcData.fromJson(e as Map<String, dynamic>)).toList(),
      locations: locList.map((e) => LocationData.fromJson(e as Map<String, dynamic>)).toList(),
      items: itemList.map((e) => ItemData.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  static EntitiesResponse? tryParse(String text) {
    try {
      final json = jsonDecode(_extractJson(text)) as Map<String, dynamic>;
      return EntitiesResponse.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}

class NpcData {
  const NpcData({
    required this.name,
    this.description,
    this.role,
    this.context,
    this.timestampMs,
  });

  final String name;
  final String? description;
  final String? role;
  final String? context;
  final int? timestampMs;

  factory NpcData.fromJson(Map<String, dynamic> json) {
    return NpcData(
      name: json['name'] as String? ?? 'Unknown',
      description: json['description'] as String?,
      role: json['role'] as String?,
      context: json['context'] as String?,
      timestampMs: json['timestamp_ms'] as int?,
    );
  }
}

class LocationData {
  const LocationData({
    required this.name,
    this.description,
    this.locationType,
    this.context,
    this.timestampMs,
  });

  final String name;
  final String? description;
  final String? locationType;
  final String? context;
  final int? timestampMs;

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      name: json['name'] as String? ?? 'Unknown',
      description: json['description'] as String?,
      locationType: json['location_type'] as String?,
      context: json['context'] as String?,
      timestampMs: json['timestamp_ms'] as int?,
    );
  }
}

class ItemData {
  const ItemData({
    required this.name,
    this.description,
    this.itemType,
    this.properties,
    this.context,
    this.timestampMs,
  });

  final String name;
  final String? description;
  final String? itemType;
  final String? properties;
  final String? context;
  final int? timestampMs;

  factory ItemData.fromJson(Map<String, dynamic> json) {
    return ItemData(
      name: json['name'] as String? ?? 'Unknown',
      description: json['description'] as String?,
      itemType: json['item_type'] as String?,
      properties: json['properties'] as String?,
      context: json['context'] as String?,
      timestampMs: json['timestamp_ms'] as int?,
    );
  }
}

/// Response model for action items extraction.
class ActionItemsResponse {
  const ActionItemsResponse({required this.actionItems});

  final List<ActionItemData> actionItems;

  factory ActionItemsResponse.fromJson(Map<String, dynamic> json) {
    final items = json['action_items'] as List<dynamic>? ?? [];
    return ActionItemsResponse(
      actionItems: items.map((e) => ActionItemData.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  static ActionItemsResponse? tryParse(String text) {
    try {
      final json = jsonDecode(_extractJson(text)) as Map<String, dynamic>;
      return ActionItemsResponse.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}

class ActionItemData {
  const ActionItemData({
    required this.title,
    this.description,
    this.actionType,
  });

  final String title;
  final String? description;
  final String? actionType;

  factory ActionItemData.fromJson(Map<String, dynamic> json) {
    return ActionItemData(
      title: json['title'] as String? ?? 'Untitled',
      description: json['description'] as String?,
      actionType: json['action_type'] as String?,
    );
  }
}

/// Response model for player moments extraction.
class PlayerMomentsResponse {
  const PlayerMomentsResponse({required this.moments});

  final List<PlayerMomentData> moments;

  factory PlayerMomentsResponse.fromJson(Map<String, dynamic> json) {
    final items = json['player_moments'] as List<dynamic>? ?? [];
    return PlayerMomentsResponse(
      moments: items.map((e) => PlayerMomentData.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }

  static PlayerMomentsResponse? tryParse(String text) {
    try {
      final json = jsonDecode(_extractJson(text)) as Map<String, dynamic>;
      return PlayerMomentsResponse.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}

class PlayerMomentData {
  const PlayerMomentData({
    required this.playerName,
    this.characterName,
    required this.description,
    this.momentType,
    this.quoteText,
    this.timestampMs,
  });

  final String playerName;
  final String? characterName;
  final String description;
  final String? momentType;
  final String? quoteText;
  final int? timestampMs;

  factory PlayerMomentData.fromJson(Map<String, dynamic> json) {
    return PlayerMomentData(
      playerName: json['player_name'] as String? ?? 'Unknown',
      characterName: json['character_name'] as String?,
      description: json['description'] as String? ?? '',
      momentType: json['moment_type'] as String?,
      quoteText: json['quote_text'] as String?,
      timestampMs: json['timestamp_ms'] as int?,
    );
  }
}

/// Extracts JSON from LLM response text (handles markdown code blocks).
String _extractJson(String text) {
  // Try to extract JSON from markdown code blocks
  final codeBlockPattern = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
  final match = codeBlockPattern.firstMatch(text);
  if (match != null) {
    return match.group(1)!.trim();
  }
  // Otherwise assume the entire text is JSON
  return text.trim();
}
