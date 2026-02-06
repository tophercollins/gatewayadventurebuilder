import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/campaign.dart';
import '../data/models/session.dart';
import '../data/models/world.dart';
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
          ),
        );
      }
      return result;
    });

/// Campaign with session count for display.
class CampaignWithSessionCount {
  const CampaignWithSessionCount({
    required this.campaign,
    required this.sessionCount,
  });

  final Campaign campaign;
  final int sessionCount;
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
