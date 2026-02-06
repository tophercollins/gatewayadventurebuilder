/// Campaign import model - stores imported text for entity extraction.
class CampaignImport {
  const CampaignImport({
    required this.id,
    required this.campaignId,
    required this.rawText,
    this.status = ImportStatus.pending,
    required this.createdAt,
    this.processedAt,
  });

  final String id;
  final String campaignId;
  final String rawText;
  final ImportStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;

  factory CampaignImport.fromMap(Map<String, dynamic> map) {
    return CampaignImport(
      id: map['id'] as String,
      campaignId: map['campaign_id'] as String,
      rawText: map['raw_text'] as String,
      status: ImportStatus.fromString(map['status'] as String?),
      createdAt: DateTime.parse(map['created_at'] as String),
      processedAt: map['processed_at'] != null
          ? DateTime.parse(map['processed_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'campaign_id': campaignId,
      'raw_text': rawText,
      'status': status.value,
      'created_at': createdAt.toIso8601String(),
      'processed_at': processedAt?.toIso8601String(),
    };
  }

  CampaignImport copyWith({
    String? id,
    String? campaignId,
    String? rawText,
    ImportStatus? status,
    DateTime? createdAt,
    DateTime? processedAt,
  }) {
    return CampaignImport(
      id: id ?? this.id,
      campaignId: campaignId ?? this.campaignId,
      rawText: rawText ?? this.rawText,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }
}

enum ImportStatus {
  pending('pending'),
  processing('processing'),
  complete('complete'),
  error('error');

  const ImportStatus(this.value);
  final String value;

  static ImportStatus fromString(String? value) {
    return ImportStatus.values.firstWhere(
      (s) => s.value == value,
      orElse: () => ImportStatus.pending,
    );
  }
}
