import 'package:intl/intl.dart';

/// Simple email content structure used by templates.
class EmailContent {
  const EmailContent({
    required this.to,
    required this.subject,
    required this.htmlBody,
    this.textBody,
  });

  final String to;
  final String subject;
  final String htmlBody;
  final String? textBody;
}

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
    int? durationSeconds,
    int sceneCount = 0,
    int npcCount = 0,
    int locationCount = 0,
    int itemCount = 0,
    int actionItemCount = 0,
    int momentCount = 0,
    String? transcript,
  }) {
    final dateFormatter = DateFormat('EEEE, MMMM d, yyyy');
    final formattedDate = dateFormatter.format(sessionDate);
    final displayTitle = sessionTitle ?? 'Session $sessionNumber';
    final formattedDuration = _formatDuration(durationSeconds);

    return EmailContent(
      to: recipientEmail,
      subject: 'Your session is ready: $campaignName - $displayTitle',
      htmlBody: _buildHtml(
        campaignName: campaignName,
        displayTitle: displayTitle,
        formattedDate: formattedDate,
        summaryPreview: summaryPreview,
        deepLink: deepLink,
        formattedDuration: formattedDuration,
        sceneCount: sceneCount,
        npcCount: npcCount,
        locationCount: locationCount,
        itemCount: itemCount,
        actionItemCount: actionItemCount,
        momentCount: momentCount,
        transcript: transcript,
      ),
      textBody: _buildText(
        campaignName: campaignName,
        displayTitle: displayTitle,
        formattedDate: formattedDate,
        summaryPreview: summaryPreview,
        deepLink: deepLink,
        formattedDuration: formattedDuration,
        sceneCount: sceneCount,
        npcCount: npcCount,
        locationCount: locationCount,
        itemCount: itemCount,
        actionItemCount: actionItemCount,
        momentCount: momentCount,
        transcript: transcript,
      ),
    );
  }

  static String? _formatDuration(int? seconds) {
    if (seconds == null || seconds <= 0) return null;
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  static String _buildStatsHtml({
    String? formattedDuration,
    required int sceneCount,
    required int npcCount,
    required int locationCount,
    required int itemCount,
    required int actionItemCount,
    required int momentCount,
  }) {
    final rows = <String>[];
    if (formattedDuration != null) {
      rows.add(_statRow('Duration', formattedDuration));
    }
    if (sceneCount > 0) rows.add(_statRow('Scenes', '$sceneCount'));
    if (npcCount > 0) rows.add(_statRow('NPCs', '$npcCount'));
    if (locationCount > 0) rows.add(_statRow('Locations', '$locationCount'));
    if (itemCount > 0) rows.add(_statRow('Items', '$itemCount'));
    if (actionItemCount > 0) {
      rows.add(_statRow('Action Items', '$actionItemCount'));
    }
    if (momentCount > 0) {
      rows.add(_statRow('Player Moments', '$momentCount'));
    }

    if (rows.isEmpty) return '';

    return '''
              <p style="margin: 24px 0 8px; color: #666666; font-size: 14px;">
                Session Stats
              </p>
              <table width="100%" cellpadding="0" cellspacing="0"
                     style="background-color: #f7f7f7; border-radius: 6px;
                            margin: 0 0 16px;">
                <tr>
                  <td style="padding: 16px 20px;">
                    <table width="100%" cellpadding="0" cellspacing="0">
                      ${rows.join('\n                      ')}
                    </table>
                  </td>
                </tr>
              </table>
    ''';
  }

  static String _statRow(String label, String value) {
    return '''<tr>
                        <td style="padding: 4px 0; color: #666666;
                                   font-size: 14px; width: 140px;">
                          $label
                        </td>
                        <td style="padding: 4px 0; color: #1a1a1a;
                                   font-size: 14px; font-weight: 600;">
                          $value
                        </td>
                      </tr>''';
  }

  static String _buildHtml({
    required String campaignName,
    required String displayTitle,
    required String formattedDate,
    required String summaryPreview,
    String? deepLink,
    String? formattedDuration,
    required int sceneCount,
    required int npcCount,
    required int locationCount,
    required int itemCount,
    required int actionItemCount,
    required int momentCount,
    String? transcript,
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

    final statsSection = _buildStatsHtml(
      formattedDuration: formattedDuration,
      sceneCount: sceneCount,
      npcCount: npcCount,
      locationCount: locationCount,
      itemCount: itemCount,
      actionItemCount: actionItemCount,
      momentCount: momentCount,
    );

    final transcriptSection = transcript != null && transcript.isNotEmpty
        ? '''
              <p style="margin: 24px 0 8px; color: #666666; font-size: 14px;">
                Full Transcript
              </p>
              <div style="background-color: #f7f7f7; border-radius: 6px;
                          padding: 20px; margin: 0 0 16px;
                          white-space: pre-wrap; word-wrap: break-word;
                          font-family: -apple-system, BlinkMacSystemFont,
                          'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
                          font-size: 14px; line-height: 1.6; color: #333333;">
${_escapeHtml(transcript)}</div>
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

              <!-- Stats -->
              $statsSection

              <!-- Summary Preview -->
              <p style="margin: 24px 0 8px; color: #666666; font-size: 14px;">
                Summary
              </p>
              <p style="margin: 0; color: #333333; font-size: 16px;
                        line-height: 1.6; font-style: italic;">
                "$escapedSummary"
              </p>

              <!-- Transcript -->
              $transcriptSection

              $viewButton
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding: 24px 32px; border-top: 1px solid #eeeeee;
                       background-color: #f7f7f7; border-radius: 0 0 8px 8px;">
              <p style="margin: 0; color: #666666; font-size: 14px;
                        text-align: center;">
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
''';
  }

  static String _buildText({
    required String campaignName,
    required String displayTitle,
    required String formattedDate,
    required String summaryPreview,
    String? deepLink,
    String? formattedDuration,
    required int sceneCount,
    required int npcCount,
    required int locationCount,
    required int itemCount,
    required int actionItemCount,
    required int momentCount,
    String? transcript,
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

    // Stats
    final hasStats =
        formattedDuration != null ||
        sceneCount > 0 ||
        npcCount > 0 ||
        locationCount > 0 ||
        itemCount > 0 ||
        actionItemCount > 0 ||
        momentCount > 0;

    if (hasStats) {
      buffer.writeln();
      buffer.writeln('Stats:');
      if (formattedDuration != null) {
        buffer.writeln('  Duration: $formattedDuration');
      }
      if (sceneCount > 0) buffer.writeln('  Scenes: $sceneCount');
      if (npcCount > 0) buffer.writeln('  NPCs: $npcCount');
      if (locationCount > 0) buffer.writeln('  Locations: $locationCount');
      if (itemCount > 0) buffer.writeln('  Items: $itemCount');
      if (actionItemCount > 0) {
        buffer.writeln('  Action Items: $actionItemCount');
      }
      if (momentCount > 0) buffer.writeln('  Player Moments: $momentCount');
    }

    buffer.writeln();
    buffer.writeln('Summary:');
    buffer.writeln('"$summaryPreview"');

    if (transcript != null && transcript.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Full Transcript:');
      buffer.writeln('------------------------');
      buffer.writeln(transcript);
      buffer.writeln('------------------------');
    }

    if (deepLink != null) {
      buffer.writeln();
      buffer.writeln('View session: $deepLink');
    }

    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('History Check');

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
