import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/processing_queue.dart';

/// Repository for processing queue management.
class ProcessingQueueRepository {
  ProcessingQueueRepository(this._db);

  final DatabaseHelper _db;
  static const _uuid = Uuid();

  /// Add a session to the processing queue.
  Future<ProcessingQueueItem> enqueue(String sessionId) async {
    final db = await _db.database;
    final item = ProcessingQueueItem(
      id: _uuid.v4(),
      sessionId: sessionId,
      createdAt: DateTime.now(),
    );
    await db.insert('processing_queue', item.toMap());
    return item;
  }

  /// Get the next pending item in the queue.
  Future<ProcessingQueueItem?> getNextPending() async {
    final db = await _db.database;
    final results = await db.query(
      'processing_queue',
      where: 'status = ?',
      whereArgs: [ProcessingStatus.pending.value],
      orderBy: 'created_at ASC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ProcessingQueueItem.fromMap(results.first);
  }

  /// Get queue item by session ID.
  Future<ProcessingQueueItem?> getBySessionId(String sessionId) async {
    final db = await _db.database;
    final results = await db.query(
      'processing_queue',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return ProcessingQueueItem.fromMap(results.first);
  }

  /// Get all pending items.
  Future<List<ProcessingQueueItem>> getPendingItems() async {
    final db = await _db.database;
    final results = await db.query(
      'processing_queue',
      where: 'status = ?',
      whereArgs: [ProcessingStatus.pending.value],
      orderBy: 'created_at ASC',
    );
    return results.map((m) => ProcessingQueueItem.fromMap(m)).toList();
  }

  /// Mark item as processing.
  Future<void> markProcessing(String id) async {
    final db = await _db.database;
    await db.update(
      'processing_queue',
      {
        'status': ProcessingStatus.processing.value,
        'started_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark item as complete.
  Future<void> markComplete(String id) async {
    final db = await _db.database;
    await db.update(
      'processing_queue',
      {
        'status': ProcessingStatus.complete.value,
        'completed_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Mark item as failed with error message.
  Future<void> markError(String id, String errorMessage) async {
    final db = await _db.database;
    final item = await getById(id);
    final attempts = (item?.attempts ?? 0) + 1;

    await db.update(
      'processing_queue',
      {
        'status': ProcessingStatus.error.value,
        'error_message': errorMessage,
        'attempts': attempts,
        'completed_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Reset a failed item to pending for retry.
  Future<void> resetForRetry(String id) async {
    final db = await _db.database;
    await db.update(
      'processing_queue',
      {
        'status': ProcessingStatus.pending.value,
        'error_message': null,
        'started_at': null,
        'completed_at': null,
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Get item by ID.
  Future<ProcessingQueueItem?> getById(String id) async {
    final db = await _db.database;
    final results = await db.query(
      'processing_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return ProcessingQueueItem.fromMap(results.first);
  }

  /// Delete a queue item.
  Future<void> delete(String id) async {
    final db = await _db.database;
    await db.delete('processing_queue', where: 'id = ?', whereArgs: [id]);
  }

  /// Get count of pending items.
  Future<int> getPendingCount() async {
    final db = await _db.database;
    final result = await db.rawQuery(
      '''
      SELECT COUNT(*) as count FROM processing_queue
      WHERE status = ?
    ''',
      [ProcessingStatus.pending.value],
    );
    return result.first['count'] as int? ?? 0;
  }
}
