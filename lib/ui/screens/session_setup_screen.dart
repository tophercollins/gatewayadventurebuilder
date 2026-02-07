import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../providers/player_providers.dart';
import '../../providers/recording_providers.dart';
import '../../providers/repository_providers.dart';
import '../theme/spacing.dart';
import '../widgets/attendee_selection_list.dart';

/// Session setup screen for selecting attendees before recording.
/// Per APP_FLOW.md Flow 5: Start a Session (Recording).
class SessionSetupScreen extends ConsumerStatefulWidget {
  const SessionSetupScreen({required this.campaignId, super.key});

  final String campaignId;

  @override
  ConsumerState<SessionSetupScreen> createState() => _SessionSetupScreenState();
}

class _SessionSetupScreenState extends ConsumerState<SessionSetupScreen> {
  bool _isStarting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(attendeeSelectionProvider.notifier).clearAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playersAsync = ref.watch(
      playersWithCharactersProvider(widget.campaignId),
    );
    final selection = ref.watch(attendeeSelectionProvider);

    return Padding(
      padding: const EdgeInsets.all(Spacing.lg),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
          child: playersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _buildErrorState(theme, error.toString()),
            data: (players) {
              if (players.isEmpty) {
                return _buildEmptyState(theme);
              }
              return _buildContent(theme, selection);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme, AttendeeSelectionState selection) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Who is playing today?', style: theme.textTheme.headlineSmall),
        const SizedBox(height: Spacing.sm),
        Text(
          'Select the players and characters present for this session.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.lg),

        // Shared attendee selection widget
        Expanded(
          child: SingleChildScrollView(
            child: AttendeeSelectionList(campaignId: widget.campaignId),
          ),
        ),

        // Error message
        if (_errorMessage != null) ...[
          const SizedBox(height: Spacing.md),
          Container(
            padding: const EdgeInsets.all(Spacing.md),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(Spacing.cardRadius),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: Spacing.sm),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: Spacing.lg),

        // Start Recording button
        SizedBox(
          height: Spacing.buttonHeight,
          child: FilledButton.icon(
            onPressed: selection.selectedCount == 0 || _isStarting
                ? null
                : _startRecording,
            icon: _isStarting
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : const Icon(Icons.mic),
            label: Text(_isStarting ? 'Starting...' : 'Start Recording'),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.people_outline,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: Spacing.md),
          Text('No players yet', style: theme.textTheme.titleLarge),
          const SizedBox(height: Spacing.sm),
          Text(
            'Add players to your campaign before starting a session.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Spacing.lg),
          FilledButton.tonal(
            onPressed: () {
              context.go(Routes.newPlayerPath(widget.campaignId));
            },
            child: const Text('Add Player'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: Spacing.md),
          Text('Failed to load players', style: theme.textTheme.titleLarge),
          const SizedBox(height: Spacing.sm),
          Text(
            error,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Future<void> _startRecording() async {
    setState(() {
      _isStarting = true;
      _errorMessage = null;
    });

    try {
      final sessionRepo = ref.read(sessionRepositoryProvider);
      final selection = ref.read(attendeeSelectionProvider);

      final sessionNumber = await sessionRepo.getNextSessionNumber(
        widget.campaignId,
      );

      final session = await sessionRepo.createSession(
        campaignId: widget.campaignId,
        sessionNumber: sessionNumber,
        date: DateTime.now(),
      );

      // Create attendees from selection map
      for (final entry in selection.selections.entries) {
        await sessionRepo.addAttendee(
          sessionId: session.id,
          playerId: entry.key,
          characterId: entry.value,
        );
      }

      if (mounted) {
        context.go(Routes.recordingPath(widget.campaignId, session.id));
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to start session: ${e.toString()}';
        _isStarting = false;
      });
    }
  }
}
