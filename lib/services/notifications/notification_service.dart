import '../../data/models/campaign.dart';
import '../../data/models/notification_settings.dart';
import '../../data/models/session.dart';
import '../../data/models/session_summary.dart';
import 'email_service.dart';
import 'email_templates.dart';

/// Result of a notification operation.
class NotificationResult {
  const NotificationResult({
    required this.emailSent,
    this.emailError,
  });

  final bool emailSent;
  final String? emailError;

  bool get hasError => emailError != null;
}

/// Service for sending notifications.
class NotificationService {
  NotificationService({
    required EmailService emailService,
  }) : _emailService = emailService;

  final EmailService _emailService;

  /// Send notification for a completed session processing.
  Future<NotificationResult> notifySessionProcessed({
    required NotificationSettings settings,
    required Campaign campaign,
    required Session session,
    required SessionSummary summary,
    String? deepLink,
  }) async {
    // Skip if notifications not configured
    if (!settings.isConfigured || !settings.notifyOnProcessingComplete) {
      return const NotificationResult(emailSent: false);
    }

    // Check if email service is available
    if (!await _emailService.isAvailable()) {
      return const NotificationResult(
        emailSent: false,
        emailError: 'Email service not available',
      );
    }

    // Build summary preview (truncate to reasonable length)
    final summaryText = summary.overallSummary ?? 'Session processed successfully';
    final summaryPreview = _truncateSummary(summaryText, 200);

    // Create email content
    final email = EmailTemplates.sessionProcessed(
      recipientEmail: settings.emailAddress!,
      campaignName: campaign.name,
      sessionDate: session.date,
      summaryPreview: summaryPreview,
      sessionNumber: session.sessionNumber ?? 1,
      sessionTitle: session.title,
      deepLink: deepLink,
    );

    // Send email
    final result = await _emailService.send(email);

    return NotificationResult(
      emailSent: result.success,
      emailError: result.error,
    );
  }

  String _truncateSummary(String summary, int maxLength) {
    if (summary.length <= maxLength) {
      return summary;
    }

    // Try to truncate at a word boundary
    final truncated = summary.substring(0, maxLength);
    final lastSpace = truncated.lastIndexOf(' ');

    if (lastSpace > maxLength * 0.8) {
      return '${truncated.substring(0, lastSpace)}...';
    }

    return '$truncated...';
  }
}
