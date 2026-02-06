/// How session recaps are shared with players.
enum PlayerSharingMode {
  /// GM reviews first, then manually sends to players.
  reviewFirst,
  /// Automatically sent to players after processing.
  autoSend,
}

/// Notification settings for the user.
/// Stored in secure storage.
class NotificationSettings {
  const NotificationSettings({
    this.emailEnabled = false,
    this.emailAddress,
    this.notifyOnProcessingComplete = true,
    this.playerSharingMode = PlayerSharingMode.reviewFirst,
  });

  /// Whether email notifications are enabled.
  final bool emailEnabled;

  /// Email address for notifications.
  final String? emailAddress;

  /// Whether to notify when session processing completes.
  final bool notifyOnProcessingComplete;

  /// How session recaps are shared with players.
  final PlayerSharingMode playerSharingMode;

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
      playerSharingMode: PlayerSharingMode.values.firstWhere(
        (m) => m.name == (map['player_sharing_mode'] as String?),
        orElse: () => PlayerSharingMode.reviewFirst,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email_enabled': emailEnabled,
      'email_address': emailAddress,
      'notify_on_processing_complete': notifyOnProcessingComplete,
      'player_sharing_mode': playerSharingMode.name,
    };
  }

  NotificationSettings copyWith({
    bool? emailEnabled,
    String? emailAddress,
    bool? notifyOnProcessingComplete,
    PlayerSharingMode? playerSharingMode,
  }) {
    return NotificationSettings(
      emailEnabled: emailEnabled ?? this.emailEnabled,
      emailAddress: emailAddress ?? this.emailAddress,
      notifyOnProcessingComplete:
          notifyOnProcessingComplete ?? this.notifyOnProcessingComplete,
      playerSharingMode: playerSharingMode ?? this.playerSharingMode,
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
        other.notifyOnProcessingComplete == notifyOnProcessingComplete &&
        other.playerSharingMode == playerSharingMode;
  }

  @override
  int get hashCode {
    return Object.hash(
      emailEnabled,
      emailAddress,
      notifyOnProcessingComplete,
      playerSharingMode,
    );
  }
}
