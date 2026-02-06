import 'dart:convert';

import 'json_utils.dart';
import 'llm_response_models.dart';

/// Response model for dedicated NPC extraction.
class NpcsResponse {
  const NpcsResponse({required this.npcs});

  final List<NpcData> npcs;

  factory NpcsResponse.fromJson(Map<String, dynamic> json) {
    final npcList = json['npcs'] as List<dynamic>? ?? [];
    return NpcsResponse(
      npcs: npcList
          .map((e) => NpcData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static NpcsResponse? tryParse(String text) {
    try {
      final json = jsonDecode(extractJson(text)) as Map<String, dynamic>;
      return NpcsResponse.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}

/// Response model for dedicated location extraction.
class LocationsResponse {
  const LocationsResponse({required this.locations});

  final List<LocationData> locations;

  factory LocationsResponse.fromJson(Map<String, dynamic> json) {
    final locList = json['locations'] as List<dynamic>? ?? [];
    return LocationsResponse(
      locations: locList
          .map((e) => LocationData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static LocationsResponse? tryParse(String text) {
    try {
      final json = jsonDecode(extractJson(text)) as Map<String, dynamic>;
      return LocationsResponse.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}

/// Response model for dedicated item extraction.
class ItemsResponse {
  const ItemsResponse({required this.items});

  final List<ItemData> items;

  factory ItemsResponse.fromJson(Map<String, dynamic> json) {
    final itemList = json['items'] as List<dynamic>? ?? [];
    return ItemsResponse(
      items: itemList
          .map((e) => ItemData.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  static ItemsResponse? tryParse(String text) {
    try {
      final json = jsonDecode(extractJson(text)) as Map<String, dynamic>;
      return ItemsResponse.fromJson(json);
    } catch (_) {
      return null;
    }
  }
}
