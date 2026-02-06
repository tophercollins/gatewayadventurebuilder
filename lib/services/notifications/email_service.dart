import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/env_config.dart';

/// Result of an email send operation.
class EmailResult {
  const EmailResult({
    required this.success,
    this.messageId,
    this.error,
  });

  final bool success;
  final String? messageId;
  final String? error;

  factory EmailResult.success(String messageId) {
    return EmailResult(success: true, messageId: messageId);
  }

  factory EmailResult.failure(String error) {
    return EmailResult(success: false, error: error);
  }
}

/// Email content structure.
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

/// Abstract interface for email providers.
/// Allows swapping implementations (Resend, SendGrid, etc.)
abstract class EmailService {
  /// Send an email.
  Future<EmailResult> send(EmailContent email);

  /// Check if the service is configured and available.
  Future<bool> isAvailable();
}

/// Resend email service implementation.
/// Uses Resend API (https://resend.com/docs/api-reference/emails/send-email)
class ResendEmailService implements EmailService {
  ResendEmailService({
    http.Client? httpClient,
    String? fromEmail,
  })  : _httpClient = httpClient ?? http.Client(),
        _fromEmail = fromEmail ?? 'TTRPG Tracker <notifications@ttrpg-tracker.app>';

  final http.Client _httpClient;
  final String _fromEmail;

  static const _apiUrl = 'https://api.resend.com/emails';

  @override
  Future<EmailResult> send(EmailContent email) async {
    try {
      final apiKey = await EnvConfig.getResendApiKey();
      if (apiKey == null || apiKey.isEmpty) {
        return EmailResult.failure('Resend API key not configured');
      }

      final response = await _httpClient.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'from': _fromEmail,
          'to': [email.to],
          'subject': email.subject,
          'html': email.htmlBody,
          if (email.textBody != null) 'text': email.textBody,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final messageId = data['id'] as String?;
        return EmailResult.success(messageId ?? 'unknown');
      } else {
        final error = _parseError(response.body);
        return EmailResult.failure(error);
      }
    } catch (e) {
      return EmailResult.failure('Failed to send email: $e');
    }
  }

  @override
  Future<bool> isAvailable() async {
    final apiKey = await EnvConfig.getResendApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }

  String _parseError(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      return data['message'] as String? ?? 'Unknown error';
    } catch (_) {
      return 'Failed to parse error response';
    }
  }
}

/// Mock email service for testing.
class MockEmailService implements EmailService {
  final List<EmailContent> sentEmails = [];
  bool shouldFail = false;
  String failureMessage = 'Mock failure';

  @override
  Future<EmailResult> send(EmailContent email) async {
    await Future.delayed(const Duration(milliseconds: 100));

    if (shouldFail) {
      return EmailResult.failure(failureMessage);
    }

    sentEmails.add(email);
    return EmailResult.success('mock-message-id-${sentEmails.length}');
  }

  @override
  Future<bool> isAvailable() async => !shouldFail;

  void reset() {
    sentEmails.clear();
    shouldFail = false;
    failureMessage = 'Mock failure';
  }
}
