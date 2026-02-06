/// Notification settings for the user.
/// Stored in secure storage.
class NotificationSettings {
  const NotificationSettings({
    this.emailEnabled = false,
    this.emailAddress,
    this.notifyOnProcessingComplete = true,
  });

  /// Whether email notifications are enabled.
  final bool emailEnabled;

  /// Email address for notifications.
  final String? emailAddress;

  /// Whether to notify when session processing completes.
  final bool notifyOnProcessingComplete;

  /// Whether notifications are effectively enabled.
  bool get isConfigured =>
      emailEnabled &&
      emailAddress != null &&
      emailAddress!.isNotEmpty &&
      _isValidEmail(emailAddress!);

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      emailEnabled: map['email_enabled'] as bool? ?? false,
      emailAddress: map['email_address'] as String?,
      notifyOnProcessingComplete:
          map['notify_on_processing_complete'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email_enabled': emailEnabled,
      'email_address': emailAddress,
      'notify_on_processing_complete': notifyOnProcessingComplete,
    };
  }

  NotificationSettings copyWith({
    bool? emailEnabled,
    String? emailAddress,
    bool? notifyOnProcessingComplete,
  }) {
    return NotificationSettings(
      emailEnabled: emailEnabled ?? this.emailEnabled,
      emailAddress: emailAddress ?? this.emailAddress,
      notifyOnProcessingComplete:
          notifyOnProcessingComplete ?? this.notifyOnProcessingComplete,
    );
  }

  static bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    return regex.hasMatch(email);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationSettings &&
        other.emailEnabled == emailEnabled &&
        other.emailAddress == emailAddress &&
        other.notifyOnProcessingComplete == notifyOnProcessingComplete;
  }

  @override
  int get hashCode {
    return Object.hash(emailEnabled, emailAddress, notifyOnProcessingComplete);
  }
}
