import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/campaign.dart';
import '../data/models/session.dart';
import '../data/models/world.dart';
import '../data/repositories/campaign_repository.dart';
import 'global_providers.dart';
import 'image_providers.dart';
import 'processing_providers.dart';
import 'repository_providers.dart';

/// Revision counter to force campaign list refresh.
final campaignsRevisionProvider = StateProvider<int>((ref) => 0);

/// Revision counter to force session list refresh.
final sessionsRevisionProvider = StateProvider<int>((ref) => 0);

/// Provider for campaigns list with session counts.
final campaignsListProvider =
    FutureProvider.autoDispose<List<CampaignWithSessionCount>>((ref) async {
      ref.watch(campaignsRevisionProvider);
      final user = await ref.watch(currentUserProvider.future);
      final campaignRepo = ref.watch(campaignRepositoryProvider);
      final sessionRepo = ref.watch(sessionRepositoryProvider);

      final campaigns = await campaignRepo.getCampaignsByUser(user.id);

      final result = <CampaignWithSessionCount>[];
      for (final campaign in campaigns) {
        final sessions = await sessionRepo.getSessionsByCampaign(campaign.id);
        result.add(
          CampaignWithSessionCount(
            campaign: campaign,
            sessionCount: sessions.length,
            lastSessionDate: sessions.isNotEmpty ? sessions.first.date : null,
          ),
        );
      }

      // Sort by most recent session activity (campaigns with sessions first)
      result.sort((a, b) {
        if (a.lastSessionDate != null && b.lastSessionDate != null) {
          return b.lastSessionDate!.compareTo(a.lastSessionDate!);
        }
        if (a.lastSessionDate != null) return -1;
        if (b.lastSessionDate != null) return 1;
        return b.campaign.updatedAt.compareTo(a.campaign.updatedAt);
      });

      return result;
    });

/// Campaign with session count for display.
class CampaignWithSessionCount {
  const CampaignWithSessionCount({
    required this.campaign,
    required this.sessionCount,
    this.lastSessionDate,
  });

  final Campaign campaign;
  final int sessionCount;
  final DateTime? lastSessionDate;
}

/// Provider for campaign details.
final campaignDetailProvider = FutureProvider.autoDispose
    .family<CampaignDetail?, String>((ref, campaignId) async {
      ref.watch(campaignsRevisionProvider);
      ref.watch(sessionsRevisionProvider);
      final campaignRepo = ref.watch(campaignRepositoryProvider);
      final sessionRepo = ref.watch(sessionRepositoryProvider);
      final playerRepo = ref.watch(playerRepositoryProvider);

      final result = await campaignRepo.getCampaignWithWorld(campaignId);
      if (result == null) return null;

      final sessions = await sessionRepo.getSessionsByCampaign(campaignId);
      final players = await playerRepo.getPlayersByCampaign(campaignId);

      return CampaignDetail(
        campaign: result.campaign,
        world: result.world,
        sessions: sessions,
        playerCount: players.length,
      );
    });

/// Campaign detail data.
class CampaignDetail {
  const CampaignDetail({
    required this.campaign,
    required this.world,
    required this.sessions,
    required this.playerCount,
  });

  final Campaign campaign;
  final World world;
  final List<Session> sessions;
  final int playerCount;
}

/// Service for campaign CRUD operations.
/// Centralizes repo access and revision bumping.
class CampaignEditor {
  CampaignEditor(this._campaignRepo, this._ref);

  final CampaignRepository _campaignRepo;
  final Ref _ref;

  /// Creates a campaign with an optional import text.
  /// If [worldId] is provided, uses that world. Otherwise auto-creates one.
  /// Returns the new campaign's ID.
  Future<String> createCampaign({
    required String name,
    String? worldId,
    String? gameSystem,
    String? description,
    String? importText,
  }) async {
    final user = await _ref.read(currentUserProvider.future);
    final campaign = await _campaignRepo.createCampaign(
      userId: user.id,
      name: name,
      worldId: worldId,
      gameSystem: gameSystem,
      description: description,
    );

    if (importText != null && importText.isNotEmpty) {
      final importRepo = _ref.read(campaignImportRepositoryProvider);
      await importRepo.create(campaignId: campaign.id, rawText: importText);
    }

    _ref.read(campaignsRevisionProvider.notifier).state++;
    _ref.read(worldsRevisionProvider.notifier).state++;
    return campaign.id;
  }

  /// Updates a campaign.
  Future<void> updateCampaign(Campaign updated) async {
    await _campaignRepo.updateCampaign(updated);
    _ref.read(campaignsRevisionProvider.notifier).state++;
  }

  /// Deletes a campaign and all its data, including image.
  Future<void> deleteCampaign(String campaignId) async {
    final imageService = _ref.read(imageStorageProvider);
    await imageService.deleteImage(
      entityType: 'campaigns',
      entityId: campaignId,
    );
    await _campaignRepo.deleteCampaign(campaignId);
    _ref.read(campaignsRevisionProvider.notifier).state++;
  }
}

/// Provider for campaign editor operations.
final campaignEditorProvider = Provider<CampaignEditor>((ref) {
  final campaignRepo = ref.watch(campaignRepositoryProvider);
  return CampaignEditor(campaignRepo, ref);
});

/// Service for world CRUD operations.
class WorldEditor {
  WorldEditor(this._campaignRepo, this._ref);

  final CampaignRepository _campaignRepo;
  final Ref _ref;

  /// Creates a standalone world. Returns the new world.
  Future<World> createWorld({
    required String name,
    String? description,
    String? gameSystem,
  }) async {
    final user = await _ref.read(currentUserProvider.future);
    final world = await _campaignRepo.createWorld(
      userId: user.id,
      name: name,
      description: description,
      gameSystem: gameSystem,
    );
    _ref.read(worldsRevisionProvider.notifier).state++;
    return world;
  }

  /// Updates a world's name, description, or game system.
  Future<void> updateWorld(World updated) async {
    await _campaignRepo.updateWorld(updated);
    _ref.read(worldsRevisionProvider.notifier).state++;
  }

  /// Deletes a world and its campaigns, including image.
  Future<void> deleteWorld(String worldId) async {
    final imageService = _ref.read(imageStorageProvider);
    await imageService.deleteImage(
      entityType: 'worlds',
      entityId: worldId,
    );
    await _campaignRepo.deleteWorld(worldId);
    _ref.read(worldsRevisionProvider.notifier).state++;
    _ref.read(campaignsRevisionProvider.notifier).state++;
  }
}

/// Provider for world editor operations.
final worldEditorProvider = Provider<WorldEditor>((ref) {
  final campaignRepo = ref.watch(campaignRepositoryProvider);
  return WorldEditor(campaignRepo, ref);
});
