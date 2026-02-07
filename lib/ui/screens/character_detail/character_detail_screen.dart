import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/routes.dart';
import '../../../data/models/character.dart';
import '../../../data/models/player.dart';
import '../../../data/models/session.dart';
import '../../../providers/player_providers.dart';
import '../../theme/spacing.dart';
import '../../widgets/character_edit_form.dart';
import '../../widgets/empty_state.dart';
import 'character_detail_widgets.dart';
import 'character_sessions_section.dart';

/// Character detail screen showing info, backstory, goals, notes,
/// session history, and edit/delete capabilities.
class CharacterDetailScreen extends ConsumerStatefulWidget {
  const CharacterDetailScreen({
    this.campaignId,
    required this.characterId,
    super.key,
  });

  final String? campaignId;
  final String characterId;

  @override
  ConsumerState<CharacterDetailScreen> createState() =>
      _CharacterDetailScreenState();
}

class _CharacterDetailScreenState extends ConsumerState<CharacterDetailScreen> {
  bool _isEditing = false;

  @override
  Widget build(BuildContext context) {
    final characterAsync = ref.watch(
      characterDetailProvider(widget.characterId),
    );
    final sessionsAsync = ref.watch(
      characterSessionsProvider(widget.characterId),
    );

    return characterAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorState(error: error.toString()),
      data: (character) {
        if (character == null) {
          return const NotFoundState(message: 'Character not found');
        }

        final playerAsync = ref.watch(
          characterPlayerProvider(character.playerId),
        );

        return _CharacterDetailContent(
          character: character,
          playerAsync: playerAsync,
          sessionsAsync: sessionsAsync,
          campaignId: widget.campaignId,
          isEditing: _isEditing,
          onEditToggle: () => setState(() => _isEditing = !_isEditing),
          onSave: _handleSave,
          onDelete: _handleDelete,
        );
      },
    );
  }

  Future<void> _handleSave(Character updated) async {
    await ref
        .read(playerEditorProvider)
        .updateCharacter(updated, widget.campaignId);
    setState(() => _isEditing = false);
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Character updated')));
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Character'),
        content: const Text(
          'Are you sure you want to delete this character? '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref
          .read(playerEditorProvider)
          .deleteCharacter(widget.characterId, widget.campaignId);
      if (mounted) {
        if (widget.campaignId != null) {
          context.go(Routes.charactersPath(widget.campaignId!));
        } else {
          context.go(Routes.allCharacters);
        }
      }
    }
  }
}

class _CharacterDetailContent extends StatelessWidget {
  const _CharacterDetailContent({
    required this.character,
    required this.playerAsync,
    required this.sessionsAsync,
    required this.campaignId,
    required this.isEditing,
    required this.onEditToggle,
    required this.onSave,
    required this.onDelete,
  });

  final Character character;
  final AsyncValue<Player?> playerAsync;
  final AsyncValue<List<Session>> sessionsAsync;
  final String? campaignId;
  final bool isEditing;
  final VoidCallback onEditToggle;
  final ValueChanged<Character> onSave;
  final VoidCallback onDelete;

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
              CharacterHeader(
                character: character,
                onEdit: onEditToggle,
                onDelete: onDelete,
              ),
              const SizedBox(height: Spacing.lg),
              if (isEditing)
                CharacterEditForm(
                  character: character,
                  onSave: onSave,
                  onCancel: onEditToggle,
                )
              else ...[
                CharacterInfoSection(
                  character: character,
                  playerAsync: playerAsync,
                ),
                const SizedBox(height: Spacing.lg),
                CharacterSessionsSection(
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
