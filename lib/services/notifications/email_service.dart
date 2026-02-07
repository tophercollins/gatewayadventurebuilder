import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../config/env_config.dart';
import 'email_templates.dart';

/// Simple Resend API client for sending session notification emails.
class ResendEmailService {
  ResendEmailService({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;

  static const _apiUrl = 'https://api.resend.com/emails';
  static const _fromEmail = 'History Check <onboarding@resend.dev>';

  /// Check if the Resend API key is configured.
  Future<bool> isAvailable() async {
    final apiKey = await EnvConfig.getResendApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  /// Send a session-complete notification email.
  /// Returns true if the email was sent successfully.
  Future<bool> sendSessionCompleteEmail({
    required String toEmail,
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
    debugPrint('[EmailService] Sending session-complete email to $toEmail');

    final apiKey = await EnvConfig.getResendApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('[EmailService] No Resend API key configured');
      return false;
    }

    final email = EmailTemplates.sessionProcessed(
      recipientEmail: toEmail,
      campaignName: campaignName,
      sessionDate: sessionDate,
      summaryPreview: summaryText ?? 'Session processed successfully',
      sessionNumber: 1,
      sessionTitle: sessionTitle,
      durationSeconds: durationSeconds,
      sceneCount: sceneCount,
      npcCount: npcCount,
      locationCount: locationCount,
      itemCount: itemCount,
      actionItemCount: actionItemCount,
      momentCount: momentCount,
      transcript: transcript,
    );

    return _sendViaResend(
      apiKey: apiKey,
      toEmail: email.to,
      subject: email.subject,
      htmlBody: email.htmlBody,
      textBody: email.textBody,
    );
  }

  /// Send a simple test email to verify Resend is configured.
  /// Returns true if sent successfully.
  Future<bool> sendTestEmail({required String toEmail}) async {
    debugPrint('[EmailService] Sending test email to $toEmail');

    final apiKey = await EnvConfig.getResendApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      debugPrint('[EmailService] No Resend API key configured');
      return false;
    }

    return _sendViaResend(
      apiKey: apiKey,
      toEmail: toEmail,
      subject: 'Test notification from History Check',
      htmlBody: '''
<!DOCTYPE html>
<html>
<body style="margin:0; padding:0; font-family:-apple-system, BlinkMacSystemFont,
             'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
             background-color:#f7f7f7;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color:#f7f7f7;">
    <tr>
      <td align="center" style="padding:40px 16px;">
        <table width="100%" cellpadding="0" cellspacing="0"
               style="max-width:600px; background-color:#ffffff;
                      border-radius:8px; border:1px solid #d1d5db;">
          <tr>
            <td style="padding:32px;">
              <h1 style="margin:0 0 16px; font-size:24px; color:#1a1a1a;">
                Email notifications are working!
              </h1>
              <p style="margin:0; color:#333333; font-size:16px; line-height:1.5;">
                This is a test email from History Check. If you received this,
                your email notification settings are configured correctly.
              </p>
            </td>
          </tr>
          <tr>
            <td style="padding:16px 32px; border-top:1px solid #eeeeee;
                       background-color:#f7f7f7; border-radius:0 0 8px 8px;">
              <p style="margin:0; color:#666666; font-size:14px; text-align:center;">
                History Check
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''',
      textBody:
          'Email notifications are working!\n\n'
          'This is a test email from History Check. If you received this, '
          'your email notification settings are configured correctly.\n\n'
          '---\nHistory Check',
    );
  }

  /// Low-level Resend API call.
  Future<bool> _sendViaResend({
    required String apiKey,
    required String toEmail,
    required String subject,
    required String htmlBody,
    String? textBody,
  }) async {
    try {
      final response = await _httpClient.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': _fromEmail,
          'to': [toEmail],
          'subject': subject,
          'html': htmlBody,
          // ignore: use_null_aware_elements
          if (textBody != null) 'text': textBody,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        debugPrint('[EmailService] Sent! id=${data['id']}');
        return true;
      }

      debugPrint(
        '[EmailService] Failed: ${response.statusCode} ${response.body}',
      );
      return false;
    } catch (e) {
      debugPrint('[EmailService] Error: $e');
      return false;
    }
  }
}
