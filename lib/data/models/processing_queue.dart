/// Processing queue item model.
class ProcessingQueueItem {
  const ProcessingQueueItem({
    required this.id,
    required this.sessionId,
    this.status = ProcessingStatus.pending,
    this.errorMessage,
    this.attempts = 0,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
  });

  final String id;
  final String sessionId;
  final ProcessingStatus status;
  final String? errorMessage;
  final int attempts;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? completedAt;

  factory ProcessingQueueItem.fromMap(Map<String, dynamic> map) {
    return ProcessingQueueItem(
      id: map['id'] as String,
      sessionId: map['session_id'] as String,
      status: ProcessingStatus.fromString(map['status'] as String?),
      errorMessage: map['error_message'] as String?,
      attempts: map['attempts'] as int? ?? 0,
      createdAt: DateTime.parse(map['created_at'] as String),
      startedAt: map['started_at'] != null
          ? DateTime.parse(map['started_at'] as String)
          : null,
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'session_id': sessionId,
      'status': status.value,
      'error_message': errorMessage,
      'attempts': attempts,
      'created_at': createdAt.toIso8601String(),
      'started_at': startedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  ProcessingQueueItem copyWith({
    String? id,
    String? sessionId,
    ProcessingStatus? status,
    String? errorMessage,
    int? attempts,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return ProcessingQueueItem(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      attempts: attempts ?? this.attempts,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

enum ProcessingStatus {
  pending('pending'),
  processing('processing'),
  complete('complete'),
  error('error');

  const ProcessingStatus(this.value);
  final String value;

  static ProcessingStatus fromString(String? value) {
    return ProcessingStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => ProcessingStatus.pending,
    );
  }
}
