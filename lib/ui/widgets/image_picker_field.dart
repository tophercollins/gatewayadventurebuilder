import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/image_providers.dart';
import '../theme/spacing.dart';
import 'entity_image.dart';

/// A form field for picking and previewing an entity image.
/// Calls [onImageSelected] with the source file path when an image is picked.
/// Calls [onImageRemoved] when the user removes the current image.
class ImagePickerField extends ConsumerWidget {
  const ImagePickerField({
    required this.currentImagePath,
    required this.pendingImagePath,
    required this.fallbackIcon,
    required this.onImageSelected,
    required this.onImageRemoved,
    this.isBanner = false,
    this.avatarSize = 80,
    super.key,
  });

  final String? currentImagePath;
  final String? pendingImagePath;
  final IconData fallbackIcon;
  final ValueChanged<String> onImageSelected;
  final VoidCallback onImageRemoved;
  final bool isBanner;
  final double avatarSize;

  String? get _displayPath => pendingImagePath ?? currentImagePath;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isBanner ? 'Banner Image' : 'Image',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Stack(
          children: [
            GestureDetector(
              onTap: () => _pickImage(ref),
              child: _buildPreview(context),
            ),
            if (_displayPath != null)
              Positioned(
                top: 0,
                right: 0,
                child: _RemoveButton(onPressed: onImageRemoved),
              ),
          ],
        ),
        const SizedBox(height: Spacing.fieldSpacing),
      ],
    );
  }

  Widget _buildPreview(BuildContext context) {
    final theme = Theme.of(context);

    if (isBanner) {
      if (_displayPath != null && _displayPath!.isNotEmpty) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(Spacing.cardRadius),
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.file(
              File(_displayPath!),
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _bannerPlaceholder(theme),
            ),
          ),
        );
      }
      return _bannerPlaceholder(theme);
    }

    if (_displayPath != null && _displayPath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(Spacing.sm),
        child: Image.file(
          File(_displayPath!),
          width: avatarSize,
          height: avatarSize,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => EntityImage.avatar(
            imagePath: null,
            fallbackIcon: fallbackIcon,
            size: avatarSize,
          ),
        ),
      );
    }

    return EntityImage.avatar(
      imagePath: null,
      fallbackIcon: fallbackIcon,
      size: avatarSize,
    );
  }

  Widget _bannerPlaceholder(ThemeData theme) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(Spacing.cardRadius),
          border: Border.all(
            color: theme.colorScheme.outline,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              color: theme.colorScheme.primary,
              size: 32,
            ),
            const SizedBox(height: Spacing.xs),
            Text(
              'Add banner image',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(WidgetRef ref) async {
    final imageService = ref.read(imageStorageProvider);
    final path = await imageService.pickImageFile();
    if (path != null) {
      onImageSelected(path);
    }
  }
}

class _RemoveButton extends StatelessWidget {
  const _RemoveButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.error,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Icon(Icons.close, size: 16, color: theme.colorScheme.onError),
        ),
      ),
    );
  }
}
