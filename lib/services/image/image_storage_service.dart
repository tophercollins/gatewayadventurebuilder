import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Image type controls resize dimensions.
enum EntityImageType {
  /// 16:9 wide banner for worlds/campaigns (max 1200px wide).
  banner,

  /// Square avatar for players/characters/NPCs/locations/items (max 512px).
  avatar,
}

/// Service for picking, resizing, storing, and deleting entity images.
class ImageStorageService {
  static const _baseDir = 'ttrpg_tracker/images';
  static const _bannerMaxWidth = 1200;
  static const _avatarMaxSize = 512;
  static const _jpegQuality = 85;

  /// Opens the OS file picker filtered to image files.
  /// Returns the selected file path, or null if cancelled.
  Future<String?> pickImageFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['png', 'jpg', 'jpeg', 'webp'],
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;
    return result.files.single.path;
  }

  /// Reads the source image, resizes it, encodes as JPEG, and writes
  /// to the storage directory. Returns the stored file path.
  Future<String> storeImage({
    required String sourcePath,
    required String entityType,
    required String entityId,
    required EntityImageType imageType,
  }) async {
    final bytes = await File(sourcePath).readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw Exception('Failed to decode image: $sourcePath');
    }

    final resized = _resize(decoded, imageType);
    final jpeg = img.encodeJpg(resized, quality: _jpegQuality);

    final storagePath = await _storagePath(entityType, entityId);
    final dir = Directory(p.dirname(storagePath));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    await File(storagePath).writeAsBytes(jpeg);
    return storagePath;
  }

  /// Deletes the stored image file for an entity, if it exists.
  Future<void> deleteImage({
    required String entityType,
    required String entityId,
  }) async {
    final path = await _storagePath(entityType, entityId);
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  /// Returns the expected file path for an entity's image.
  Future<String> getImagePath({
    required String entityType,
    required String entityId,
  }) async {
    return _storagePath(entityType, entityId);
  }

  img.Image _resize(img.Image source, EntityImageType imageType) {
    switch (imageType) {
      case EntityImageType.banner:
        if (source.width <= _bannerMaxWidth) return source;
        return img.copyResize(source, width: _bannerMaxWidth);
      case EntityImageType.avatar:
        final size = source.width > source.height
            ? source.height
            : source.width;
        // Crop to square from center, then resize
        final cropped = img.copyCrop(
          source,
          x: (source.width - size) ~/ 2,
          y: (source.height - size) ~/ 2,
          width: size,
          height: size,
        );
        if (cropped.width <= _avatarMaxSize) return cropped;
        return img.copyResize(cropped, width: _avatarMaxSize);
    }
  }

  Future<String> _storagePath(String entityType, String entityId) async {
    final appDir = await getApplicationDocumentsDirectory();
    return p.join(appDir.path, _baseDir, entityType, '$entityId.jpg');
  }
}
