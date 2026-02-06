import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/action_item.dart';

/// Repository for action items and plot threads.
class ActionItemRepository {
  ActionItemRepository(this._db);

  final DatabaseHelper _db;
  static const _uuid = Uuid();

  Future<ActionItem> create({
    required String sessionId,
    required String campaignId,
    required String title,
    String? description,
    String? actionType,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final item = ActionItem(
      id: _uuid.v4(),
      sessionId: sessionId,
      campaignId: campaignId,
      title: title,
      description: description,
      actionType: actionType,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('action_items', item.toMap());
    return item;
  }

  Future<ActionItem?> getById(String id) async {
    final db = await _db.database;
    final results = await db.query(
      'action_items',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return ActionItem.fromMap(results.first);
  }

  Future<List<ActionItem>> getByCampaign(String campaignId) async {
    final db = await _db.database;
    final results = await db.query(
      'action_items',
      where: 'campaign_id = ?',
      whereArgs: [campaignId],
      orderBy: 'created_at DESC',
    );
    return results.map((m) => ActionItem.fromMap(m)).toList();
  }

  Future<List<ActionItem>> getBySession(String sessionId) async {
    final db = await _db.database;
    final results = await db.query(
      'action_items',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at ASC',
    );
    return results.map((m) => ActionItem.fromMap(m)).toList();
  }

  Future<List<ActionItem>> getOpenByCampaign(String campaignId) async {
    final db = await _db.database;
    final results = await db.query(
      'action_items',
      where: 'campaign_id = ? AND status IN (?, ?)',
      whereArgs: [
        campaignId,
        ActionItemStatus.open.value,
        ActionItemStatus.inProgress.value,
      ],
      orderBy: 'created_at DESC',
    );
    return results.map((m) => ActionItem.fromMap(m)).toList();
  }

  Future<void> update(ActionItem item, {bool markEdited = false}) async {
    final db = await _db.database;
    final updated = item.copyWith(
      updatedAt: DateTime.now(),
      isEdited: markEdited ? true : item.isEdited,
    );
    await db.update(
      'action_items',
      updated.toMap(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> updateStatus(
    String id,
    ActionItemStatus status, {
    String? resolvedSessionId,
  }) async {
    final db = await _db.database;
    await db.update(
      'action_items',
      {
        'status': status.value,
        'resolved_session_id': resolvedSessionId,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('action_items', where: 'id = ?', whereArgs: [id]);
  }
}
