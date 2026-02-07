import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/spacing.dart';

/// Displays an entity's image with fallback to icon or custom widget.
class EntityImage extends StatelessWidget {
  /// Square avatar with rounded corners.
  const EntityImage.avatar({
    required this.imagePath,
    required this.fallbackIcon,
    this.size = 56,
    this.borderRadius,
    this.fallbackChild,
    super.key,
  }) : isBanner = false;

  /// Wide 16:9 banner image.
  const EntityImage.banner({
    required this.imagePath,
    required this.fallbackIcon,
    this.fallbackChild,
    super.key,
  }) : size = 0,
       borderRadius = null,
       isBanner = true;

  final String? imagePath;
  final IconData fallbackIcon;
  final double size;
  final double? borderRadius;
  final Widget? fallbackChild;
  final bool isBanner;

  @override
  Widget build(BuildContext context) {
    if (isBanner) return _buildBanner(context);
    return _buildAvatar(context);
  }

  Widget _buildAvatar(BuildContext context) {
    final theme = Theme.of(context);
    final radius = borderRadius ?? Spacing.sm;

    if (imagePath != null && imagePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Image.file(
          File(imagePath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _avatarFallback(theme, radius),
        ),
      );
    }

    return _avatarFallback(theme, radius);
  }

  Widget _avatarFallback(ThemeData theme, double radius) {
    if (fallbackChild != null) return fallbackChild!;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(
        fallbackIcon,
        color: theme.colorScheme.primary,
        size: size > 40 ? 32 : Spacing.iconSize,
      ),
    );
  }

  Widget _buildBanner(BuildContext context) {
    final theme = Theme.of(context);

    if (imagePath != null && imagePath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: Image.file(
            File(imagePath!),
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _bannerFallback(theme),
          ),
        ),
      );
    }

    // No banner displayed when no image is set
    return const SizedBox.shrink();
  }

  Widget _bannerFallback(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(Spacing.cardRadius),
      ),
      child: Center(
        child: Icon(fallbackIcon, color: theme.colorScheme.primary, size: 48),
      ),
    );
  }
}
