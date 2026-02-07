import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models/notification_settings.dart';
import '../services/notifications/email_service.dart';

const _settingsKey = 'notification_settings';

/// Provider for ResendEmailService.
final emailServiceProvider = Provider<ResendEmailService>((ref) {
  return ResendEmailService();
});

/// Provider to check if email service is available.
final emailServiceAvailableProvider = FutureProvider<bool>((ref) async {
  final emailService = ref.watch(emailServiceProvider);
  return await emailService.isAvailable();
});

/// Loads notification settings from SharedPreferences.
Future<NotificationSettings> _loadSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final json = prefs.getString(_settingsKey);
  if (json == null || json.isEmpty) {
    return const NotificationSettings();
  }
  final map = jsonDecode(json) as Map<String, dynamic>;
  return NotificationSettings.fromMap(map);
}

/// Saves notification settings to SharedPreferences.
Future<void> _saveSettings(NotificationSettings settings) async {
  final prefs = await SharedPreferences.getInstance();
  final json = jsonEncode(settings.toMap());
  await prefs.setString(_settingsKey, json);
}

/// Provider that loads notification settings from storage once at startup.
final _initialSettingsProvider = FutureProvider<NotificationSettings>((ref) {
  return _loadSettings();
});

/// Notifier for managing notification settings.
class NotificationSettingsNotifier extends StateNotifier<NotificationSettings> {
  NotificationSettingsNotifier(super.initial);

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
/// Waits for settings to load from SharedPreferences before creating the
/// notifier, so consumers always see persisted values instead of defaults.
final notificationSettingsProvider =
    StateNotifierProvider<NotificationSettingsNotifier, NotificationSettings>((
      ref,
    ) {
      final initial = ref.watch(_initialSettingsProvider);
      return NotificationSettingsNotifier(
        initial.valueOrNull ?? const NotificationSettings(),
      );
    });

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

enum InAppNotificationType { info, success, error }

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
