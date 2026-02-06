import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/notification_providers.dart';
import '../../../providers/theme_provider.dart';
import '../../theme/spacing.dart';
import 'notification_settings_widgets.dart';

/// Screen for managing notification settings.
class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Sync controller with current value.
      final settings = ref.read(notificationSettingsProvider);
      _emailController.text = settings.emailAddress ?? '';
      // Keep controller in sync when settings load or change externally.
      ref.listenManual(notificationSettingsProvider, (prev, next) {
        if (!_isEditing && next.emailAddress != prev?.emailAddress) {
          _emailController.text = next.emailAddress ?? '';
        }
      });
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(notificationSettingsProvider);
    final emailAvailable = ref.watch(emailServiceAvailableProvider);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Spacing.maxContentWidth),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(Spacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Spacing.xl),

              // Appearance Section
              _ThemeSection(),
              const SizedBox(height: Spacing.xl),

              // Notifications Header
              Text(
                'Notifications',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: Spacing.sm),
              Text(
                'Configure how you want to be notified when sessions are processed.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: Spacing.lg),

              // Email Service Status
              emailAvailable.when(
                data: (available) =>
                    NotificationServiceStatus(available: available),
                loading: () => const SizedBox.shrink(),
                error: (error, stack) =>
                    const NotificationServiceStatus(available: false),
              ),
              const SizedBox(height: Spacing.lg),

              // Email Notifications Section
              NotificationSection(
                title: 'Email Notifications',
                child: Column(
                  children: [
                    NotificationToggleRow(
                      title: 'Enable email notifications',
                      subtitle: 'Receive emails when processing completes',
                      value: settings.emailEnabled,
                      onChanged: (value) {
                        ref
                            .read(notificationSettingsProvider.notifier)
                            .setEmailEnabled(value);
                      },
                    ),
                    if (settings.emailEnabled) ...[
                      const Divider(height: Spacing.lg),
                      _buildEmailInput(context, settings.emailAddress),
                      const Divider(height: Spacing.lg),
                      NotificationToggleRow(
                        title: 'Session processing complete',
                        subtitle: 'Notify when AI analysis finishes',
                        value: settings.notifyOnProcessingComplete,
                        onChanged: (value) {
                          ref
                              .read(notificationSettingsProvider.notifier)
                              .setNotifyOnProcessingComplete(value);
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: Spacing.lg),

              // Status Summary
              if (settings.emailEnabled)
                NotificationStatusSummary(isConfigured: settings.isConfigured),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmailInput(BuildContext context, String? currentEmail) {
    final theme = Theme.of(context);

    if (!_isEditing) {
      return Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Email address',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: Spacing.xs),
                Text(
                  currentEmail?.isNotEmpty == true ? currentEmail! : 'Not set',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: currentEmail?.isNotEmpty == true
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () {
              setState(() {
                _isEditing = true;
                _emailController.text = currentEmail ?? '';
              });
            },
            icon: const Icon(Icons.edit, size: Spacing.iconSizeCompact),
            label: const Text('Edit'),
          ),
        ],
      );
    }

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Email address',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          TextFormField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              hintText: 'Enter your email address',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Email is required';
              }
              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
              if (!emailRegex.hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                  });
                },
                child: const Text('Cancel'),
              ),
              const SizedBox(width: Spacing.sm),
              FilledButton(
                onPressed: () {
                  if (_formKey.currentState?.validate() == true) {
                    ref
                        .read(notificationSettingsProvider.notifier)
                        .setEmailAddress(_emailController.text);
                    setState(() {
                      _isEditing = false;
                    });
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Theme appearance section for the settings screen.
class _ThemeSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeMode = ref.watch(themeModeProvider);

    return NotificationSection(
      title: 'Appearance',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode, size: 18),
                label: Text('Light'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode, size: 18),
                label: Text('Dark'),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (selected) {
              ref
                  .read(themeModeProvider.notifier)
                  .setThemeMode(selected.first);
            },
          ),
        ],
      ),
    );
  }
}
