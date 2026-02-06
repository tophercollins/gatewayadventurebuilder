import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/podcast_providers.dart';
import '../theme/spacing.dart';

/// A card widget that displays a podcast-style recap script for a session.
/// Allows generating, viewing, and regenerating the script via AI.
class PodcastCard extends ConsumerStatefulWidget {
  const PodcastCard({
    required this.sessionId,
    required this.campaignId,
    super.key,
  });

  final String sessionId;
  final String campaignId;

  @override
  ConsumerState<PodcastCard> createState() => _PodcastCardState();
}

class _PodcastCardState extends ConsumerState<PodcastCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scriptAsync = ref.watch(podcastScriptProvider(widget.sessionId));
    final genState = ref.watch(podcastGenerationStateProvider);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(Spacing.cardRadius),
      child: Container(
        padding: const EdgeInsets.all(Spacing.cardPadding),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.outline),
          borderRadius: BorderRadius.circular(Spacing.cardRadius),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(theme),
            const SizedBox(height: Spacing.sm),
            scriptAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(Spacing.md),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (error, _) => Text(
                'Error loading script: $error',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
                ),
              ),
              data: (script) => _buildBody(theme, script, genState),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(Spacing.sm),
          ),
          child: Icon(
            Icons.podcasts_outlined,
            color: theme.colorScheme.primary,
            size: Spacing.iconSizeCompact,
          ),
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
            'Podcast Recap',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(
    ThemeData theme,
    String? script,
    PodcastGenerationState genState,
  ) {
    if (genState.isGenerating) {
      return _buildGeneratingState(theme);
    }

    if (genState.error != null) {
      return _buildErrorState(theme, genState.error!, script);
    }

    if (script == null || script.isEmpty) {
      return _buildEmptyState(theme);
    }

    return _buildScriptContent(theme, script);
  }

  Widget _buildGeneratingState(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.md),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            'Generating podcast script...',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(
    ThemeData theme,
    String error,
    String? existingScript,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(Spacing.sm),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer,
            borderRadius: BorderRadius.circular(Spacing.cardRadius),
          ),
          child: Row(
            children: [
              Icon(
                Icons.error_outline,
                size: Spacing.iconSizeCompact,
                color: theme.colorScheme.onErrorContainer,
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: Text(
                  error,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: Spacing.sm),
        if (existingScript != null && existingScript.isNotEmpty)
          _buildScriptContent(theme, existingScript)
        else
          _buildGenerateButton(theme, isRegenerate: false),
      ],
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Generate an entertaining podcast-style recap of this session.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        _buildGenerateButton(theme, isRegenerate: false),
      ],
    );
  }

  Widget _buildScriptContent(ThemeData theme, String script) {
    final displayText =
        _isExpanded ? script : _truncate(script, 200);
    final needsToggle = script.length > 200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayText,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.6,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Row(
          children: [
            if (needsToggle)
              TextButton(
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _isExpanded ? 'Show less' : 'Show more',
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                    const SizedBox(width: Spacing.xs),
                    Icon(
                      _isExpanded ? Icons.expand_less : Icons.expand_more,
                      size: Spacing.iconSizeCompact,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.copy_outlined),
              iconSize: Spacing.iconSizeCompact,
              color: theme.colorScheme.onSurfaceVariant,
              tooltip: 'Copy to clipboard',
              onPressed: () => _copyToClipboard(context, script),
            ),
            _buildGenerateButton(theme, isRegenerate: true),
          ],
        ),
      ],
    );
  }

  Widget _buildGenerateButton(ThemeData theme, {required bool isRegenerate}) {
    return isRegenerate
        ? TextButton.icon(
            onPressed: () => _generate(ref),
            icon: Icon(
              Icons.refresh,
              size: Spacing.iconSizeCompact,
              color: theme.colorScheme.primary,
            ),
            label: Text(
              'Regenerate',
              style: TextStyle(color: theme.colorScheme.primary),
            ),
          )
        : FilledButton.icon(
            onPressed: () => _generate(ref),
            icon: const Icon(
              Icons.auto_awesome,
              size: Spacing.iconSizeCompact,
            ),
            label: const Text('Generate Podcast Recap'),
          );
  }

  void _generate(WidgetRef ref) {
    ref.read(podcastGenerationStateProvider.notifier).generate(
      sessionId: widget.sessionId,
      campaignId: widget.campaignId,
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Podcast script copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _truncate(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}
