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

  void _toggleSidebar() {
    setState(() {
      _isSidebarCollapsed = !_isSidebarCollapsed;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isDesktop = screenWidth > Spacing.breakpointTablet;

    // On smaller screens, don't show sidebar
    if (!isDesktop) {
      return _ContentArea(
        title: widget.title,
        breadcrumbs: widget.breadcrumbs,
        showBackButton: widget.showBackButton,
        child: widget.child,
      );
    }

    return Row(
      children: [
        AppSidebar(
          isCollapsed: _isSidebarCollapsed,
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
    final canPop = GoRouter.of(context).canPop();

    return Scaffold(
      appBar: AppBar(
        leading: showBackButton && canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
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
    items.add(BreadcrumbItem(
      label: 'Home',
      onTap: () => context.go('/'),
    ));
  }

  // Check if we're in campaigns
  if (currentPath.startsWith('/campaigns')) {
    if (currentPath != '/campaigns') {
      items.add(BreadcrumbItem(
        label: 'Campaigns',
        onTap: () => context.go('/campaigns'),
      ));
    }

    // Check if we're in a specific campaign
    final campaignId = extractCampaignId(currentPath);
    if (campaignId != null) {
      final campaignPath = '/campaigns/$campaignId';

      // Only add campaign breadcrumb if we're deeper than campaign home
      if (currentPath != campaignPath) {
        items.add(BreadcrumbItem(
          label: campaignName ?? 'Campaign',
          onTap: () => context.go(campaignPath),
        ));
      }

      // Check for session paths
      final sessionRegex = RegExp(r'/sessions/([^/]+)');
      final sessionMatch = sessionRegex.firstMatch(currentPath);
      if (sessionMatch != null) {
        final sessionId = sessionMatch.group(1);
        final sessionPath = '$campaignPath/sessions/$sessionId';

        // Only add session breadcrumb if we're deeper than session detail
        if (currentPath != sessionPath && sessionId != 'new') {
          items.add(BreadcrumbItem(
            label: sessionName ?? 'Session',
            onTap: () => context.go(sessionPath),
          ));
        }
      }
    }
  }

  return items;
}
