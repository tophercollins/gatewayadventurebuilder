import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../theme/spacing.dart';
import 'campaign_stats_tab.dart';
import 'character_stats_tab.dart';
import 'global_stats_tab.dart';
import 'player_stats_tab.dart';
import 'world_stats_tab.dart';

/// Stats dashboard showing global, campaign, player, world, and character
/// statistics.
class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 5,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
          child: const Column(
            children: [
              TabBar(
                tabs: [
                  Tab(text: 'Overview'),
                  Tab(text: 'Worlds'),
                  Tab(text: 'Campaigns'),
                  Tab(text: 'Players'),
                  Tab(text: 'Characters'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    GlobalStatsTab(),
                    WorldStatsTab(),
                    CampaignStatsTab(),
                    PlayerStatsTab(),
                    CharacterStatsTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
