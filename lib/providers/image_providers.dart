import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/image/image_storage_service.dart';

/// Provider for the image storage service.
final imageStorageProvider = Provider<ImageStorageService>(
  (ref) => ImageStorageService(),
);
