/// Action item model - plot threads and action items.
class ActionItem {
  const ActionItem({
    required this.id,
    required this.sessionId,
    required this.campaignId,
    required this.title,
    this.description,
    this.actionType,
    this.status = ActionItemStatus.open,
    this.resolvedSessionId,
    this.isEdited = false,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sessionId;
  final String campaignId;
  final String title;
  final String? description;
  final String? actionType;
  final ActionItemStatus status;
  final String? resolvedSessionId;
  final bool isEdited;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ActionItem.fromMap(Map<String, dynamic> map) {
    return ActionItem(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      campaignId: map['campaign_id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      actionType: map['action_type'] as String?,
      status: ActionItemStatus.fromString(map['status'] as String?),
      resolvedSessionId: map['resolved_session_id'] as String?,
      isEdited: (map['is_edited'] as int?) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'campaign_id': campaignId,
      'title': title,
      'description': description,
      'action_type': actionType,
      'status': status.value,
      'resolved_session_id': resolvedSessionId,
      'is_edited': isEdited ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ActionItem copyWith({
    String? id,
    String? sessionId,
    String? campaignId,
    String? title,
    String? description,
    String? actionType,
    ActionItemStatus? status,
    String? resolvedSessionId,
    bool? isEdited,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ActionItem(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      campaignId: campaignId ?? this.campaignId,
      title: title ?? this.title,
      description: description ?? this.description,
      actionType: actionType ?? this.actionType,
      status: status ?? this.status,
      resolvedSessionId: resolvedSessionId ?? this.resolvedSessionId,
      isEdited: isEdited ?? this.isEdited,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

enum ActionItemStatus {
  open('open'),
  inProgress('in_progress'),
  resolved('resolved'),
  dropped('dropped');

  const ActionItemStatus(this.value);
  final String value;

  static ActionItemStatus fromString(String? value) {
    return ActionItemStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => ActionItemStatus.open,
    );
  }
}
