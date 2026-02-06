import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/repositories/action_item_repository.dart';
import '../data/repositories/campaign_repository.dart';
import '../data/repositories/entity_repository.dart';
import '../data/repositories/player_moment_repository.dart';
import '../data/repositories/player_repository.dart';
import '../data/repositories/session_repository.dart';
import '../data/repositories/user_repository.dart';
import 'database_provider.dart';

/// Provider for UserRepository.
final userRepositoryProvider = Provider<UserRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return UserRepository(db);
});

/// Provider for CampaignRepository.
final campaignRepositoryProvider = Provider<CampaignRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return CampaignRepository(db);
});

/// Provider for PlayerRepository.
final playerRepositoryProvider = Provider<PlayerRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PlayerRepository(db);
});

/// Provider for SessionRepository.
final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return SessionRepository(db);
});

/// Provider for EntityRepository.
final entityRepositoryProvider = Provider<EntityRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return EntityRepository(db);
});

/// Provider for ActionItemRepository.
final actionItemRepositoryProvider = Provider<ActionItemRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return ActionItemRepository(db);
});

/// Provider for PlayerMomentRepository.
final playerMomentRepositoryProvider = Provider<PlayerMomentRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return PlayerMomentRepository(db);
});

/// Provider for the current user (MVP: single default user).
final currentUserProvider = FutureProvider((ref) async {
  final userRepo = ref.watch(userRepositoryProvider);
  return await userRepo.getOrCreateDefaultUser();
});
