import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../data/models/notification_settings.dart';
import '../services/notifications/email_service.dart';

const _settingsKey = 'notification_settings';
const _storage = FlutterSecureStorage();

/// Provider for EmailService.
final emailServiceProvider = Provider<EmailService>((ref) {
  return ResendEmailService();
});

/// Provider to check if email service is available.
final emailServiceAvailableProvider = FutureProvider<bool>((ref) async {
  final emailService = ref.watch(emailServiceProvider);
  return await emailService.isAvailable();
});

/// Loads notification settings from secure storage.
Future<NotificationSettings> _loadSettings() async {
  try {
    final json = await _storage.read(key: _settingsKey);
    if (json == null || json.isEmpty) {
      return const NotificationSettings();
    }
    final map = jsonDecode(json) as Map<String, dynamic>;
    return NotificationSettings.fromMap(map);
  } catch (_) {
    return const NotificationSettings();
  }
}

/// Saves notification settings to secure storage.
Future<void> _saveSettings(NotificationSettings settings) async {
  final json = jsonEncode(settings.toMap());
  await _storage.write(key: _settingsKey, value: json);
}

/// Notifier for managing notification settings.
class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier() : super(const NotificationSettings()) {
    _load();
  }

  Future<void> _load() async {
    state = await _loadSettings();
  }

  /// Update email enabled status.
  Future<void> setEmailEnabled(bool enabled) async {
    state = state.copyWith(emailEnabled: enabled);
    await _saveSettings(state);
  }

  /// Update email address.
  Future<void> setEmailAddress(String? email) async {
    state = state.copyWith(emailAddress: email);
    await _saveSettings(state);
  }

  /// Update processing complete notification preference.
  Future<void> setNotifyOnProcessingComplete(bool notify) async {
    state = state.copyWith(notifyOnProcessingComplete: notify);
    await _saveSettings(state);
  }

  /// Update all settings at once.
  Future<void> updateSettings(NotificationSettings settings) async {
    state = settings;
    await _saveSettings(state);
  }
}

/// Provider for notification settings state.
final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>(
  (ref) => NotificationSettingsNotifier(),
);

/// In-app notification state for showing snackbars/toasts.
class InAppNotification {
  const InAppNotification({
    required this.message,
    this.sessionId,
    this.type = InAppNotificationType.info,
  });

  final String message;
  final String? sessionId;
  final InAppNotificationType type;
}

enum InAppNotificationType {
  info,
  success,
  error,
}

/// Notifier for in-app notification state.
class InAppNotificationNotifier extends StateNotifier<InAppNotification?> {
  InAppNotificationNotifier() : super(null);

  /// Show a notification.
  void show(InAppNotification notification) {
    state = notification;
  }

  /// Show a success notification for completed processing.
  void showProcessingComplete({
    required String sessionId,
    String? sessionTitle,
  }) {
    final title = sessionTitle ?? 'Session';
    state = InAppNotification(
      message: '$title is ready for review',
      sessionId: sessionId,
      type: InAppNotificationType.success,
    );
  }

  /// Show an error notification.
  void showError(String message) {
    state = InAppNotification(
      message: message,
      type: InAppNotificationType.error,
    );
  }

  /// Clear the current notification.
  void clear() {
    state = null;
  }
}

/// Provider for in-app notifications.
final inAppNotificationProvider =
    StateNotifierProvider<InAppNotificationNotifier, InAppNotification?>(
  (ref) => InAppNotificationNotifier(),
);
