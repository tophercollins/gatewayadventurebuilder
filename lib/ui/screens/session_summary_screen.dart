import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/scene.dart';
import '../../data/models/session_summary.dart';
import '../../providers/editing_providers.dart';
import '../../providers/session_detail_providers.dart';
import '../../utils/formatters.dart';
import '../theme/spacing.dart';
import '../widgets/editable_paragraph.dart';
import '../widgets/editable_text.dart';
import '../widgets/empty_state.dart';

/// Session Summary drill-down screen.
/// Displays full overall summary and scene-by-scene breakdowns with timestamps.
class SessionSummaryScreen extends ConsumerWidget {
  const SessionSummaryScreen({
    required this.campaignId,
    required this.sessionId,
    super.key,
  });

  final String campaignId;
  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(sessionSummaryDetailProvider(sessionId));
    final editingState = ref.watch(summaryEditingProvider);

    return summaryAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => ErrorState(error: error.toString()),
      data: (data) {
        if (data == null) {
          return const NotFoundState(message: 'Summary not found');
        }
        return Stack(
          children: [
            _SummaryContent(
              sessionId: sessionId,
              summary: data.summary,
              scenes: data.scenes,
            ),
            if (editingState.isLoading)
              const _LoadingOverlay(),
          ],
        );
      },
    );
  }
}

class _LoadingOverlay extends StatelessWidget {
  const _LoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black26,
      child: const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(Spacing.lg),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}

class _SummaryContent extends ConsumerWidget {
  const _SummaryContent({
    required this.sessionId,
    required this.summary,
    required this.scenes,
  });

  final String sessionId;
  final SessionSummary? summary;
  final List<Scene> scenes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: ListView(
          padding: const EdgeInsets.all(Spacing.lg),
          children: [
            _OverallSummarySection(
              sessionId: sessionId,
              summary: summary,
            ),
            const SizedBox(height: Spacing.xl),
            _ScenesSection(scenes: scenes),
          ],
        ),
      ),
    );
  }
}

class _OverallSummarySection extends ConsumerWidget {
  const _OverallSummarySection({
    required this.sessionId,
    required this.summary,
  });

  final String sessionId;
  final SessionSummary? summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overall Summary',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: Spacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(Spacing.cardPadding),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border.all(color: theme.colorScheme.outline),
            borderRadius: BorderRadius.circular(Spacing.cardRadius),
          ),
          child: EditableParagraph(
            text: summary?.overallSummary ?? '',
            placeholder: 'No summary available yet.',
            isEdited: summary?.isEdited ?? false,
            enabled: summary != null,
            textStyle: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
            onSave: (newText) => _onSaveSummary(ref, context, newText),
          ),
        ),
      ],
    );
  }

  Future<void> _onSaveSummary(
    WidgetRef ref,
    BuildContext context,
    String newText,
  ) async {
    if (summary == null) return;

    final notifier = ref.read(summaryEditingProvider.notifier);
    final result = await notifier.updateOverallSummary(summary!.id, newText);

    if (!context.mounted) return;

    if (result != null) {
      ref.invalidate(sessionSummaryDetailProvider(sessionId));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Summary saved'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      final error = ref.read(summaryEditingProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${error ?? "Unknown error"}'),
          backgroundColor: theme(context).colorScheme.error,
        ),
      );
    }
  }

  ThemeData theme(BuildContext context) => Theme.of(context);
}

class _ScenesSection extends StatelessWidget {
  const _ScenesSection({required this.scenes});

  final List<Scene> scenes;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Scene Breakdown',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: Spacing.md),
        if (scenes.isEmpty)
          const EmptyStateCard(
            icon: Icons.description_outlined,
            message: 'No scenes identified yet.',
          )
        else
          ...scenes.map(
            (scene) => Padding(
              padding: const EdgeInsets.only(bottom: Spacing.md),
              child: _SceneCard(scene: scene),
            ),
          ),
      ],
    );
  }
}

class _SceneCard extends ConsumerStatefulWidget {
  const _SceneCard({required this.scene});

  final Scene scene;

  @override
  ConsumerState<_SceneCard> createState() => _SceneCardState();
}

class _SceneCardState extends ConsumerState<_SceneCard> {
  late Scene _localScene;

  @override
  void initState() {
    super.initState();
    _localScene = widget.scene;
  }

  @override
  void didUpdateWidget(_SceneCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.scene != widget.scene) {
      _localScene = widget.scene;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(Spacing.cardPadding),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.outline),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(Spacing.sm),
                ),
                child: Center(
                  child: Text(
                    '${_localScene.sceneIndex + 1}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    InlineEditableText(
                      text: _localScene.title ?? 'Scene ${_localScene.sceneIndex + 1}',
                      placeholder: 'Scene title',
                      isEdited: _localScene.isEdited,
                      textStyle: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      onSave: (newText) => _onSaveTitle(newText),
                    ),
                    if (_localScene.startTimeMs != null) ...[
                      const SizedBox(height: Spacing.xxs),
                      Text(
                        _formatTimestamp(_localScene.startTimeMs!, _localScene.endTimeMs),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm),
          Padding(
            padding: const EdgeInsets.only(left: 40),
            child: EditableParagraph(
              text: _localScene.summary ?? '',
              placeholder: 'No scene description available.',
              isEdited: _localScene.isEdited,
              textStyle: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              editButtonPosition: EditButtonPosition.inline,
              onSave: (newText) => _onSaveSummary(newText),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onSaveTitle(String newText) async {
    final notifier = ref.read(summaryEditingProvider.notifier);
    final result = await notifier.updateScene(_localScene.id, title: newText);

    if (!mounted) return;

    if (result != null) {
      setState(() => _localScene = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scene title saved'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      final error = ref.read(summaryEditingProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${error ?? "Unknown error"}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _onSaveSummary(String newText) async {
    final notifier = ref.read(summaryEditingProvider.notifier);
    final result = await notifier.updateScene(_localScene.id, summary: newText);

    if (!mounted) return;

    if (result != null) {
      setState(() => _localScene = result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Scene description saved'),
          duration: Duration(seconds: 2),
        ),
      );
    } else {
      final error = ref.read(summaryEditingProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${error ?? "Unknown error"}'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  String _formatTimestamp(int startMs, int? endMs) {
    final start = formatDuration(Duration(milliseconds: startMs));
    if (endMs == null) return start;
    final end = formatDuration(Duration(milliseconds: endMs));
    return '$start - $end';
  }
}
