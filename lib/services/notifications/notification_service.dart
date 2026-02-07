import 'package:flutter/foundation.dart';

import '../../data/models/notification_settings.dart';
import 'email_service.dart';

/// Thin wrapper that checks notification settings before sending emails.
class NotificationService {
  NotificationService(this._emailService);

  final ResendEmailService _emailService;

  /// Send a session-complete notification if settings allow it.
  /// Returns true if the email was sent, false if skipped or failed.
  Future<bool> notifySessionComplete({
    required NotificationSettings settings,
    required String campaignName,
    required String sessionTitle,
    required DateTime sessionDate,
    String? summaryText,
    int? durationSeconds,
    int sceneCount = 0,
    int npcCount = 0,
    int locationCount = 0,
    int itemCount = 0,
    int actionItemCount = 0,
    int momentCount = 0,
    String? transcript,
  }) async {
    if (!settings.isConfigured || !settings.notifyOnProcessingComplete) {
      debugPrint('[NotificationService] Skipped: not configured or disabled');
      return false;
    }

    return _emailService.sendSessionCompleteEmail(
      toEmail: settings.emailAddress!,
      campaignName: campaignName,
      sessionTitle: sessionTitle,
      sessionDate: sessionDate,
      summaryText: summaryText,
      durationSeconds: durationSeconds,
      sceneCount: sceneCount,
      npcCount: npcCount,
      locationCount: locationCount,
      itemCount: itemCount,
      actionItemCount: actionItemCount,
      momentCount: momentCount,
      transcript: transcript,
    );
  }
}
