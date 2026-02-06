import 'package:intl/intl.dart';

import 'email_service.dart';

/// Generates email content for session processing notifications.
abstract final class EmailTemplates {
  /// Creates email content for session processed notification.
  static EmailContent sessionProcessed({
    required String recipientEmail,
    required String campaignName,
    required DateTime sessionDate,
    required String summaryPreview,
    required int sessionNumber,
    String? sessionTitle,
    String? deepLink,
  }) {
    final dateFormatter = DateFormat('EEEE, MMMM d, yyyy');
    final formattedDate = dateFormatter.format(sessionDate);
    final displayTitle = sessionTitle ?? 'Session $sessionNumber';

    return EmailContent(
      to: recipientEmail,
      subject: 'Your session is ready: $campaignName - $displayTitle',
      htmlBody: _buildHtml(
        campaignName: campaignName,
        displayTitle: displayTitle,
        formattedDate: formattedDate,
        summaryPreview: summaryPreview,
        deepLink: deepLink,
      ),
      textBody: _buildText(
        campaignName: campaignName,
        displayTitle: displayTitle,
        formattedDate: formattedDate,
        summaryPreview: summaryPreview,
        deepLink: deepLink,
      ),
    );
  }

  static String _buildHtml({
    required String campaignName,
    required String displayTitle,
    required String formattedDate,
    required String summaryPreview,
    String? deepLink,
  }) {
    final escapedCampaign = _escapeHtml(campaignName);
    final escapedTitle = _escapeHtml(displayTitle);
    final escapedDate = _escapeHtml(formattedDate);
    final escapedSummary = _escapeHtml(summaryPreview);

    final viewButton = deepLink != null
        ? '''
      <tr>
        <td style="padding: 24px 0;">
          <a href="$deepLink"
             style="background-color: #2563EB; color: #ffffff; padding: 12px 24px;
                    text-decoration: none; border-radius: 6px; font-weight: 600;
                    display: inline-block;">
            View Session Details
          </a>
        </td>
      </tr>
      '''
        : '';

    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Session Processed</title>
</head>
<body style="margin: 0; padding: 0; font-family: -apple-system, BlinkMacSystemFont,
             'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
             background-color: #f7f7f7;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background-color: #f7f7f7;">
    <tr>
      <td align="center" style="padding: 40px 16px;">
        <table width="100%" cellpadding="0" cellspacing="0"
               style="max-width: 600px; background-color: #ffffff;
                      border-radius: 8px; border: 1px solid #d1d5db;">
          <!-- Header -->
          <tr>
            <td style="padding: 32px 32px 24px; border-bottom: 1px solid #eeeeee;">
              <h1 style="margin: 0; font-size: 24px; font-weight: 600;
                         color: #1a1a1a;">
                Session Ready for Review
              </h1>
            </td>
          </tr>

          <!-- Content -->
          <tr>
            <td style="padding: 24px 32px;">
              <p style="margin: 0 0 16px; color: #333333; font-size: 16px;
                        line-height: 1.5;">
                Your session has been processed and is ready for review.
              </p>

              <!-- Session Info Card -->
              <table width="100%" cellpadding="0" cellspacing="0"
                     style="background-color: #f7f7f7; border-radius: 6px;
                            margin: 16px 0;">
                <tr>
                  <td style="padding: 20px;">
                    <p style="margin: 0 0 8px; color: #666666; font-size: 14px;">
                      Campaign
                    </p>
                    <p style="margin: 0 0 16px; color: #1a1a1a; font-size: 18px;
                              font-weight: 600;">
                      $escapedCampaign
                    </p>

                    <p style="margin: 0 0 8px; color: #666666; font-size: 14px;">
                      Session
                    </p>
                    <p style="margin: 0 0 16px; color: #1a1a1a; font-size: 16px;">
                      $escapedTitle
                    </p>

                    <p style="margin: 0 0 8px; color: #666666; font-size: 14px;">
                      Date
                    </p>
                    <p style="margin: 0; color: #1a1a1a; font-size: 16px;">
                      $escapedDate
                    </p>
                  </td>
                </tr>
              </table>

              <!-- Summary Preview -->
              <p style="margin: 24px 0 8px; color: #666666; font-size: 14px;">
                Summary Preview
              </p>
              <p style="margin: 0; color: #333333; font-size: 16px;
                        line-height: 1.6; font-style: italic;">
                "$escapedSummary"
              </p>

              $viewButton
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding: 24px 32px; border-top: 1px solid #eeeeee;
                       background-color: #f7f7f7; border-radius: 0 0 8px 8px;">
              <p style="margin: 0; color: #666666; font-size: 14px;
                        text-align: center;">
                TTRPG Session Tracker
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
''';
  }

  static String _buildText({
    required String campaignName,
    required String displayTitle,
    required String formattedDate,
    required String summaryPreview,
    String? deepLink,
  }) {
    final buffer = StringBuffer();

    buffer.writeln('SESSION READY FOR REVIEW');
    buffer.writeln('========================');
    buffer.writeln();
    buffer.writeln('Your session has been processed and is ready for review.');
    buffer.writeln();
    buffer.writeln('Campaign: $campaignName');
    buffer.writeln('Session: $displayTitle');
    buffer.writeln('Date: $formattedDate');
    buffer.writeln();
    buffer.writeln('Summary Preview:');
    buffer.writeln('"$summaryPreview"');

    if (deepLink != null) {
      buffer.writeln();
      buffer.writeln('View session: $deepLink');
    }

    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('TTRPG Session Tracker');

    return buffer.toString();
  }

  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}
