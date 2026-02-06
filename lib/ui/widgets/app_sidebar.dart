import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../config/routes.dart';
import '../../providers/theme_provider.dart';
import '../theme/spacing.dart';

/// Navigation item for the sidebar.
class SidebarItem {
  const SidebarItem({
    required this.icon,
    required this.label,
    required this.path,
  });

  final IconData icon;
  final String label;
  final String path;
}

/// Collapsible sidebar navigation for desktop.
/// Shows on screens > 1024px width.
class AppSidebar extends ConsumerWidget {
  const AppSidebar({
    required this.isCollapsed,
    required this.onToggleCollapse,
    required this.currentPath,
    this.campaignId,
    super.key,
  });

  final bool isCollapsed;
  final VoidCallback onToggleCollapse;
  final String currentPath;
  final String? campaignId;

  static const double expandedWidth = 240;
  static const double collapsedWidth = 64;

  List<SidebarItem> get _mainItems => [
    const SidebarItem(
      icon: Icons.home_outlined,
      label: 'Home',
      path: Routes.home,
    ),
    const SidebarItem(
      icon: Icons.folder_outlined,
      label: 'Campaigns',
      path: Routes.campaigns,
    ),
    const SidebarItem(
      icon: Icons.bar_chart_outlined,
      label: 'Stats',
      path: Routes.stats,
    ),
  ];

  List<SidebarItem> get _campaignItems {
    if (campaignId == null) return [];
    return [
      SidebarItem(
        icon: Icons.dashboard_outlined,
        label: 'Campaign',
        path: Routes.campaignPath(campaignId!),
      ),
      SidebarItem(
        icon: Icons.public_outlined,
        label: 'World',
        path: Routes.worldDatabasePath(campaignId!),
      ),
      SidebarItem(
        icon: Icons.people_outlined,
        label: 'Players',
        path: Routes.playersPath(campaignId!),
      ),
    ];
  }

  bool _isActive(String itemPath) {
    if (itemPath == Routes.home) {
      return currentPath == Routes.home;
    }
    return currentPath.startsWith(itemPath);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isCollapsed ? collapsedWidth : expandedWidth,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(right: BorderSide(color: colorScheme.outline)),
      ),
      child: Column(
        children: [
          // Header with collapse toggle
          _SidebarHeader(
            isCollapsed: isCollapsed,
            onToggleCollapse: onToggleCollapse,
          ),
          const Divider(height: 1),

          // Main navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
              children: [
                ..._mainItems.map(
                  (item) => _SidebarNavItem(
                    item: item,
                    isCollapsed: isCollapsed,
                    isActive: _isActive(item.path),
                    onTap: () => context.go(item.path),
                  ),
                ),

                // Campaign section (if in campaign context)
                if (_campaignItems.isNotEmpty) ...[
                  const SizedBox(height: Spacing.sm),
                  const Divider(height: 1),
                  const SizedBox(height: Spacing.sm),
                  if (!isCollapsed)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.md,
                        vertical: Spacing.xs,
                      ),
                      child: Text(
                        'CAMPAIGN',
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ..._campaignItems.map(
                    (item) => _SidebarNavItem(
                      item: item,
                      isCollapsed: isCollapsed,
                      isActive: _isActive(item.path),
                      onTap: () => context.go(item.path),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Theme toggle
          if (!isCollapsed)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.xs,
              ),
              child: _ThemeToggle(),
            ),
          // Settings at bottom
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
            child: _SidebarNavItem(
              item: const SidebarItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                path: Routes.notificationSettings,
              ),
              isCollapsed: isCollapsed,
              isActive: _isActive(Routes.notificationSettings),
              onTap: () => context.go(Routes.notificationSettings),
            ),
          ),
        ],
      ),
    );
  }
}

class _SidebarHeader extends StatelessWidget {
  const _SidebarHeader({
    required this.isCollapsed,
    required this.onToggleCollapse,
  });

  final bool isCollapsed;
  final VoidCallback onToggleCollapse;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      height: 56,
      child: Row(
        children: [
          if (!isCollapsed) ...[
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                'TTRPG Tracker',
                style: theme.textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          IconButton(
            icon: Icon(isCollapsed ? Icons.chevron_right : Icons.chevron_left),
            onPressed: onToggleCollapse,
            tooltip: isCollapsed ? 'Expand sidebar' : 'Collapse sidebar',
          ),
        ],
      ),
    );
  }
}

class _SidebarNavItem extends StatelessWidget {
  const _SidebarNavItem({
    required this.item,
    required this.isCollapsed,
    required this.isActive,
    required this.onTap,
  });

  final SidebarItem item;
  final bool isCollapsed;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Spacing.sm,
        vertical: Spacing.xxs,
      ),
      child: Material(
        color: isActive
            ? colorScheme.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(Spacing.cardRadius),
          child: Container(
            height: Spacing.buttonHeight,
            padding: EdgeInsets.symmetric(
              horizontal: isCollapsed ? Spacing.sm : Spacing.md,
            ),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                Icon(
                  item.icon,
                  size: Spacing.iconSize,
                  color: isActive ? colorScheme.primary : colorScheme.onSurface,
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: Spacing.sm),
                  Expanded(
                    child: Text(
                      item.label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: isActive
                            ? colorScheme.primary
                            : colorScheme.onSurface,
                        fontWeight: isActive
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ThemeToggle extends ConsumerWidget {
  const _ThemeToggle();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(
          _iconForMode(themeMode),
          size: Spacing.iconSize,
          color: theme.colorScheme.onSurfaceVariant,
        ),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<ThemeMode>(
              value: themeMode,
              isExpanded: true,
              isDense: true,
              style: theme.textTheme.bodySmall,
              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('System'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Light'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Dark'),
                ),
              ],
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeModeProvider.notifier).setThemeMode(mode);
                }
              },
            ),
          ),
        ),
      ],
    );
  }

  IconData _iconForMode(ThemeMode mode) {
    return switch (mode) {
      ThemeMode.system => Icons.brightness_auto,
      ThemeMode.light => Icons.light_mode,
      ThemeMode.dark => Icons.dark_mode,
    };
  }
}
