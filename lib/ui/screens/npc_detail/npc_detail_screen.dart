import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/models/entity_appearance.dart';
import '../../../data/models/npc.dart';
import '../../../data/models/npc_quote.dart';
import '../../../data/models/npc_relationship.dart';
import '../../../data/models/session.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/world_providers.dart';
import '../../theme/spacing.dart';
import '../../widgets/empty_state.dart';
import 'npc_appearances_section.dart';
import 'npc_detail_widgets.dart';
import 'npc_edit_form.dart';
import 'npc_quotes_section.dart';
import 'npc_relationships_section.dart';

/// NPC detail screen showing all NPC information, relationships, and quotes.
class NpcDetailScreen extends ConsumerStatefulWidget {
  const NpcDetailScreen({
    required this.campaignId,
    required this.npcId,
    super.key,
  });

  final String campaignId;
  final String npcId;

  @override
  ConsumerState<NpcDetailScreen> createState() => _NpcDetailScreenState();
}

class _NpcDetailScreenState extends ConsumerState<NpcDetailScreen> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final npcAsync = ref.watch(npcByIdProvider(widget.npcId));
    final relationshipsAsync = ref.watch(npcRelationshipsProvider(widget.npcId));
    final quotesAsync = ref.watch(npcQuotesProvider(widget.npcId));
    final sessionsAsync = ref.watch(
      entitySessionsProvider((type: EntityType.npc, entityId: widget.npcId)),
    );

    return npcAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorState(error: error.toString()),
      data: (npc) {
        if (npc == null) {
          return const NotFoundState(message: 'NPC not found');
        }
        return _NpcDetailContent(
          npc: npc,
          campaignId: widget.campaignId,
          relationshipsAsync: relationshipsAsync,
          quotesAsync: quotesAsync,
          sessionsAsync: sessionsAsync,
          isEditing: _isEditing,
          onEditToggle: () => setState(() => _isEditing = !_isEditing),
          onSave: _handleSave,
        );
      },
    );
  }

  Future<void> _handleSave(Npc updatedNpc) async {
    final entityRepo = ref.read(entityRepositoryProvider);
    await entityRepo.updateNpc(updatedNpc, markEdited: true);
    ref.invalidate(npcByIdProvider(widget.npcId));
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NPC updated')),
      );
    }
  }
}

class _NpcDetailContent extends StatelessWidget {
  const _NpcDetailContent({
    required this.npc,
    required this.campaignId,
    required this.relationshipsAsync,
    required this.quotesAsync,
    required this.sessionsAsync,
    required this.isEditing,
    required this.onEditToggle,
    required this.onSave,
  });

  final Npc npc;
  final String campaignId;
  final AsyncValue<List<NpcRelationship>> relationshipsAsync;
  final AsyncValue<List<NpcQuote>> quotesAsync;
  final AsyncValue<List<Session>> sessionsAsync;
  final bool isEditing;
  final VoidCallback onEditToggle;
  final ValueChanged<Npc> onSave;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              NpcHeader(npc: npc, onEdit: onEditToggle),
              const SizedBox(height: Spacing.lg),
              if (isEditing)
                NpcEditForm(
                  npc: npc,
                  onSave: onSave,
                  onCancel: onEditToggle,
                )
              else ...[
                NpcInfoSection(npc: npc),
                const SizedBox(height: Spacing.lg),
                NpcRelationshipsSection(relationshipsAsync: relationshipsAsync),
                const SizedBox(height: Spacing.lg),
                NpcQuotesSection(quotesAsync: quotesAsync),
                const SizedBox(height: Spacing.lg),
                NpcAppearancesSection(
                  sessionsAsync: sessionsAsync,
                  campaignId: campaignId,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
