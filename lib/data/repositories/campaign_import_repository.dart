import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/campaign_import.dart';

/// Repository for campaign imports.
class CampaignImportRepository {
  CampaignImportRepository(this._db);

  final DatabaseHelper _db;
  static const _uuid = Uuid();

  /// Create a new campaign import record.
  Future<CampaignImport> create({
    required String campaignId,
    required String rawText,
  }) async {
    final db = await _db.database;
    final import = CampaignImport(
      id: _uuid.v4(),
      campaignId: campaignId,
      rawText: rawText,
      createdAt: DateTime.now(),
    );
    await db.insert('campaign_imports', import.toMap());
    return import;
  }

  /// Get import by ID.
  Future<CampaignImport?> getById(String id) async {
    final db = await _db.database;
    final results = await db.query(
      'campaign_imports',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return CampaignImport.fromMap(results.first);
  }

  /// Get imports by campaign.
  Future<List<CampaignImport>> getByCampaign(String campaignId) async {
    final db = await _db.database;
    final results = await db.query(
      'campaign_imports',
      where: 'campaign_id = ?',
      whereArgs: [campaignId],
      orderBy: 'created_at DESC',
    );
    return results.map((m) => CampaignImport.fromMap(m)).toList();
  }

  /// Get pending imports.
  Future<List<CampaignImport>> getPending() async {
    final db = await _db.database;
    final results = await db.query(
      'campaign_imports',
      where: 'status = ?',
      whereArgs: [ImportStatus.pending.value],
      orderBy: 'created_at ASC',
    );
    return results.map((m) => CampaignImport.fromMap(m)).toList();
  }

  /// Mark import as processing.
  Future<void> markProcessing(String id) async {
    final db = await _db.database;
    await db.update(
      'campaign_imports',
      {'status': ImportStatus.processing.value},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark import as complete.
  Future<void> markComplete(String id) async {
    final db = await _db.database;
    await db.update(
      'campaign_imports',
      {
        'status': ImportStatus.complete.value,
        'processed_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark import as error.
  Future<void> markError(String id) async {
    final db = await _db.database;
    await db.update(
      'campaign_imports',
      {'status': ImportStatus.error.value},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Delete an import record.
  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('campaign_imports', where: 'id = ?', whereArgs: [id]);
  }
}
