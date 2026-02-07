import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/action_item.dart';
import '../data/models/item.dart';
import '../data/models/location.dart';
import '../data/models/monster.dart';
import '../data/models/npc.dart';
import '../data/models/organisation.dart';
import '../data/models/player_moment.dart';
import '../data/models/scene.dart';
import '../data/models/session_summary.dart';
import '../services/processing/resync_service.dart';
import 'processing_providers.dart';
import 'repository_providers.dart';

/// State for tracking editing operations.
class EditingState {
  const EditingState({this.isLoading = false, this.error});

  final bool isLoading;
  final String? error;

  EditingState copyWith({bool? isLoading, String? error}) {
    return EditingState(isLoading: isLoading ?? this.isLoading, error: error);
  }
}

/// Notifier for managing session summary edits.
class SummaryEditingNotifier extends StateNotifier<EditingState> {
  SummaryEditingNotifier(this._ref) : super(const EditingState());

  final Ref _ref;

  /// Update overall summary text.
  Future<SessionSummary?> updateOverallSummary(
    String summaryId,
    String newText,
  ) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = _ref.read(summaryRepositoryProvider);
      final summary = await repo.getSummaryById(summaryId);
      if (summary == null) {
        state = state.copyWith(isLoading: false, error: 'Summary not found');
        return null;
      }

      final updated = summary.copyWith(
        overallSummary: newText,
        updatedAt: DateTime.now(),
      );
      await repo.updateSummary(updated, markEdited: true);

      state = const EditingState();
      return updated.copyWith(isEdited: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Update scene content.
  Future<Scene?> updateScene(
    String sceneId, {
    String? title,
    String? summary,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = _ref.read(summaryRepositoryProvider);
      final scene = await repo.getSceneById(sceneId);
      if (scene == null) {
        state = state.copyWith(isLoading: false, error: 'Scene not found');
        return null;
      }

      final updated = scene.copyWith(
        title: title ?? scene.title,
        summary: summary ?? scene.summary,
        updatedAt: DateTime.now(),
      );
      await repo.updateScene(updated, markEdited: true);

      state = const EditingState();
      return updated.copyWith(isEdited: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for summary editing notifier.
final summaryEditingProvider =
    StateNotifierProvider<SummaryEditingNotifier, EditingState>((ref) {
      return SummaryEditingNotifier(ref);
    });

/// Notifier for managing entity edits (NPCs, locations, items).
class EntityEditingNotifier extends StateNotifier<EditingState> {
  EntityEditingNotifier(this._ref) : super(const EditingState());

  final Ref _ref;

  /// Update NPC fields.
  Future<Npc?> updateNpc(
    String npcId, {
    String? name,
    String? description,
    String? role,
    String? notes,
    NpcStatus? status,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = _ref.read(entityRepositoryProvider);
      final npc = await repo.getNpcById(npcId);
      if (npc == null) {
        state = state.copyWith(isLoading: false, error: 'NPC not found');
        return null;
      }

      final updated = npc.copyWith(
        name: name ?? npc.name,
        description: description ?? npc.description,
        role: role ?? npc.role,
        notes: notes ?? npc.notes,
        status: status ?? npc.status,
        updatedAt: DateTime.now(),
      );
      await repo.updateNpc(updated, markEdited: true);

      state = const EditingState();
      return updated.copyWith(isEdited: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Update location fields.
  Future<Location?> updateLocation(
    String locationId, {
    String? name,
    String? description,
    String? locationType,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = _ref.read(entityRepositoryProvider);
      final location = await repo.getLocationById(locationId);
      if (location == null) {
        state = state.copyWith(isLoading: false, error: 'Location not found');
        return null;
      }

      final updated = location.copyWith(
        name: name ?? location.name,
        description: description ?? location.description,
        locationType: locationType ?? location.locationType,
        notes: notes ?? location.notes,
        updatedAt: DateTime.now(),
      );
      await repo.updateLocation(updated, markEdited: true);

      state = const EditingState();
      return updated.copyWith(isEdited: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Update item fields.
  Future<Item?> updateItem(
    String itemId, {
    String? name,
    String? description,
    String? itemType,
    String? properties,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = _ref.read(entityRepositoryProvider);
      final item = await repo.getItemById(itemId);
      if (item == null) {
        state = state.copyWith(isLoading: false, error: 'Item not found');
        return null;
      }

      final updated = item.copyWith(
        name: name ?? item.name,
        description: description ?? item.description,
        itemType: itemType ?? item.itemType,
        properties: properties ?? item.properties,
        notes: notes ?? item.notes,
        updatedAt: DateTime.now(),
      );
      await repo.updateItem(updated, markEdited: true);

      state = const EditingState();
      return updated.copyWith(isEdited: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Update monster fields.
  Future<Monster?> updateMonster(
    String monsterId, {
    String? name,
    String? description,
    String? monsterType,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = _ref.read(entityRepositoryProvider);
      final monster = await repo.getMonsterById(monsterId);
      if (monster == null) {
        state = state.copyWith(isLoading: false, error: 'Monster not found');
        return null;
      }

      final updated = monster.copyWith(
        name: name ?? monster.name,
        description: description ?? monster.description,
        monsterType: monsterType ?? monster.monsterType,
        notes: notes ?? monster.notes,
        updatedAt: DateTime.now(),
      );
      await repo.updateMonster(updated, markEdited: true);

      state = const EditingState();
      return updated.copyWith(isEdited: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  /// Update organisation fields.
  Future<Organisation?> updateOrganisation(
    String organisationId, {
    String? name,
    String? description,
    String? organisationType,
    String? notes,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = _ref.read(entityRepositoryProvider);
      final organisation = await repo.getOrganisationById(organisationId);
      if (organisation == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Organisation not found',
        );
        return null;
      }

      final updated = organisation.copyWith(
        name: name ?? organisation.name,
        description: description ?? organisation.description,
        organisationType: organisationType ?? organisation.organisationType,
        notes: notes ?? organisation.notes,
        updatedAt: DateTime.now(),
      );
      await repo.updateOrganisation(updated, markEdited: true);

      state = const EditingState();
      return updated.copyWith(isEdited: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for entity editing notifier.
final entityEditingProvider =
    StateNotifierProvider<EntityEditingNotifier, EditingState>((ref) {
      return EntityEditingNotifier(ref);
    });

/// Notifier for managing action item edits.
class ActionItemEditingNotifier extends StateNotifier<EditingState> {
  ActionItemEditingNotifier(this._ref) : super(const EditingState());

  final Ref _ref;

  /// Update action item fields.
  Future<ActionItem?> updateActionItem(
    String itemId, {
    String? title,
    String? description,
    ActionItemStatus? status,
    String? actionType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = _ref.read(actionItemRepositoryProvider);
      final item = await repo.getById(itemId);
      if (item == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Action item not found',
        );
        return null;
      }

      final updated = item.copyWith(
        title: title ?? item.title,
        description: description ?? item.description,
        status: status ?? item.status,
        actionType: actionType ?? item.actionType,
        updatedAt: DateTime.now(),
      );
      await repo.update(updated, markEdited: true);

      state = const EditingState();
      return updated.copyWith(isEdited: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for action item editing notifier.
final actionItemEditingProvider =
    StateNotifierProvider<ActionItemEditingNotifier, EditingState>((ref) {
      return ActionItemEditingNotifier(ref);
    });

/// Notifier for managing player moment edits.
class PlayerMomentEditingNotifier extends StateNotifier<EditingState> {
  PlayerMomentEditingNotifier(this._ref) : super(const EditingState());

  final Ref _ref;

  /// Update player moment fields.
  Future<PlayerMoment?> updateMoment(
    String momentId, {
    String? description,
    String? quoteText,
    String? momentType,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final repo = _ref.read(playerMomentRepositoryProvider);
      final moment = await repo.getById(momentId);
      if (moment == null) {
        state = state.copyWith(isLoading: false, error: 'Moment not found');
        return null;
      }

      final updated = moment.copyWith(
        description: description ?? moment.description,
        quoteText: quoteText ?? moment.quoteText,
        momentType: momentType ?? moment.momentType,
        updatedAt: DateTime.now(),
      );
      await repo.update(updated, markEdited: true);

      state = const EditingState();
      return updated.copyWith(isEdited: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Provider for player moment editing notifier.
final playerMomentEditingProvider =
    StateNotifierProvider<PlayerMomentEditingNotifier, EditingState>((ref) {
      return PlayerMomentEditingNotifier(ref);
    });

/// Provider for ResyncService.
final resyncServiceProvider = Provider<ResyncService>((ref) {
  return ResyncService(
    llmService: ref.watch(llmServiceProvider),
    summaryRepo: ref.watch(summaryRepositoryProvider),
    entityRepo: ref.watch(entityRepositoryProvider),
    actionItemRepo: ref.watch(actionItemRepositoryProvider),
  );
});

/// State for resync operations.
class ResyncState {
  const ResyncState({this.isResyncing = false, this.lastResult, this.error});

  final bool isResyncing;
  final ResyncResult? lastResult;
  final String? error;

  ResyncState copyWith({
    bool? isResyncing,
    ResyncResult? lastResult,
    String? error,
  }) {
    return ResyncState(
      isResyncing: isResyncing ?? this.isResyncing,
      lastResult: lastResult ?? this.lastResult,
      error: error,
    );
  }
}

/// Notifier for managing resync operations.
class ResyncNotifier extends StateNotifier<ResyncState> {
  ResyncNotifier(this._ref) : super(const ResyncState());

  final Ref _ref;

  /// Resync a session's content after edits.
  Future<ResyncResult> resyncSession({
    required String sessionId,
    required String worldId,
  }) async {
    state = state.copyWith(isResyncing: true, error: null);

    try {
      final service = _ref.read(resyncServiceProvider);
      final result = await service.resyncSession(
        sessionId: sessionId,
        worldId: worldId,
      );

      state = ResyncState(lastResult: result);
      return result;
    } catch (e) {
      final error = e.toString();
      state = ResyncState(error: error);
      return ResyncResult.failure(error);
    }
  }

  void clearState() {
    state = const ResyncState();
  }
}

/// Provider for resync notifier.
final resyncProvider = StateNotifierProvider<ResyncNotifier, ResyncState>((
  ref,
) {
  return ResyncNotifier(ref);
});
