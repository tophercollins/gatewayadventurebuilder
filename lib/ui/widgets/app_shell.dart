import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../theme/spacing.dart';
import 'app_sidebar.dart';
import 'breadcrumb.dart';
import 'connectivity_indicator.dart';

/// Shell widget that provides the app layout with sidebar and content area.
/// Used by ShellRoute to wrap all screens.
class AppShell extends StatefulWidget {
  const AppShell({
    required this.child,
    required this.currentPath,
    this.campaignId,
    this.title,
    this.breadcrumbs,
    this.showBackButton = false,
    super.key,
  });

  final Widget child;
  final String currentPath;
  final String? campaignId;
  final String? title;
  final List<BreadcrumbItem>? breadcrumbs;
  final bool showBackButton;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  bool _isSidebarCollapsed = false;
  bool _userToggledSidebar = false;

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
      _userToggledSidebar = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;

    // Auto-collapse when window is narrow, unless user explicitly expanded
    final autoCollapse = screenWidth < Spacing.breakpointTablet;
    final collapsed = _userToggledSidebar ? _isSidebarCollapsed : autoCollapse;

    return Row(
      children: [
        AppSidebar(
          isCollapsed: collapsed,
          onToggleCollapse: _toggleSidebar,
          currentPath: widget.currentPath,
          campaignId: widget.campaignId,
        ),
        Expanded(
          child: _ContentArea(
            title: widget.title,
            breadcrumbs: widget.breadcrumbs,
            showBackButton: widget.showBackButton,
            child: widget.child,
          ),
        ),
      ],
    );
  }
}

class _ContentArea extends ConsumerWidget {
  const _ContentArea({
    required this.child,
    this.title,
    this.breadcrumbs,
    this.showBackButton = false,
  });

  final Widget child;
  final String? title;
  final List<BreadcrumbItem>? breadcrumbs;
  final bool showBackButton;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final hasBreadcrumbs = breadcrumbs != null && breadcrumbs!.isNotEmpty;
    final currentPath = GoRouterState.of(context).uri.path;

    // Calculate parent path for back navigation
    final parentPath = _getParentPath(currentPath);

    return Scaffold(
      appBar: AppBar(
        leading: parentPath != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.go(parentPath),
                tooltip: 'Back',
              )
            : null,
        automaticallyImplyLeading: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasBreadcrumbs) ...[
              Breadcrumb(items: breadcrumbs!),
              const SizedBox(height: Spacing.xxs),
            ],
            if (title != null)
              Text(
                title!,
                style: hasBreadcrumbs
                    ? theme.textTheme.titleLarge
                    : theme.textTheme.headlineSmall,
              ),
          ],
        ),
        toolbarHeight: hasBreadcrumbs ? 72 : kToolbarHeight,
        actions: const [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: Spacing.md),
            child: ConnectivityIndicator(compact: true),
          ),
        ],
      ),
      body: Column(
        children: [
          // Show offline or processing banners
          const OfflineBanner(),
          const ProcessingBanner(),
          // Main content
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// Path segments that only serve as prefixes for nested routes and have
/// no standalone route definition (e.g. `/campaigns/:id/sessions` has no page).
const _intermediateSegments = {'sessions', 'characters'};

/// Calculates the parent path for back navigation.
/// Returns null if already at root. Skips intermediate segments that
/// have no matching route so the back button always lands on a valid page.
String? _getParentPath(String currentPath) {
  if (currentPath == '/' || currentPath.isEmpty) {
    return null;
  }

  // Remove trailing slash if present
  var path = currentPath;
  if (path.endsWith('/') && path.length > 1) {
    path = path.substring(0, path.length - 1);
  }

  // Strip the last segment
  var lastSlashIndex = path.lastIndexOf('/');
  if (lastSlashIndex <= 0) {
    return '/';
  }
  var parent = path.substring(0, lastSlashIndex);

  // If the resulting parent ends with an intermediate-only segment, strip
  // that segment too so we land on the nearest routable ancestor.
  final parentLastSegment = parent.substring(parent.lastIndexOf('/') + 1);
  if (_intermediateSegments.contains(parentLastSegment)) {
    final idx = parent.lastIndexOf('/');
    parent = idx <= 0 ? '/' : parent.substring(0, idx);
  }

  return parent;
}

/// Extracts campaign ID from the current route path.
String? extractCampaignId(String path) {
  final regex = RegExp(r'/campaigns/([^/]+)');
  final match = regex.firstMatch(path);
  return match?.group(1);
}

/// Builds breadcrumb items from the current route.
List<BreadcrumbItem> buildBreadcrumbs({
  required String currentPath,
  required BuildContext context,
  String? campaignName,
  String? sessionName,
}) {
  final items = <BreadcrumbItem>[];

  // Always start with Home
  if (currentPath != '/') {
    items.add(BreadcrumbItem(label: 'Home', onTap: () => context.go('/')));
  }

  // Check if we're in campaigns
  if (currentPath.startsWith('/campaigns')) {
    if (currentPath != '/campaigns') {
      items.add(
        BreadcrumbItem(
          label: 'Campaigns',
          onTap: () => context.go('/campaigns'),
        ),
      );
    }

    // Check if we're in a specific campaign
    final campaignId = extractCampaignId(currentPath);
    if (campaignId != null) {
      final campaignPath = '/campaigns/$campaignId';

      // Only add campaign breadcrumb if we're deeper than campaign home
      if (currentPath != campaignPath) {
        items.add(
          BreadcrumbItem(
            label: campaignName ?? 'Campaign',
            onTap: () => context.go(campaignPath),
          ),
        );
      }

      // Check for session paths
      final sessionRegex = RegExp(r'/sessions/([^/]+)');
      final sessionMatch = sessionRegex.firstMatch(currentPath);
      if (sessionMatch != null) {
        final sessionId = sessionMatch.group(1);
        final sessionPath = '$campaignPath/sessions/$sessionId';

        // Only add session breadcrumb if we're deeper than session detail
        if (currentPath != sessionPath && sessionId != 'new') {
          items.add(
            BreadcrumbItem(
              label: sessionName ?? 'Session',
              onTap: () => context.go(sessionPath),
            ),
          );
        }
      }
    }
  }

  return items;
}
