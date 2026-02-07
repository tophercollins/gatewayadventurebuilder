import 'package:uuid/uuid.dart';

import '../database/database_helper.dart';
import '../models/session.dart';
import '../models/session_audio.dart';
import '../models/session_transcript.dart';
import '../models/transcript_segment.dart';

/// Repository for sessions, audio, transcripts, and attendees.
class SessionRepository {
  SessionRepository(this._db);

  final DatabaseHelper _db;
  static const _uuid = Uuid();

  // ============================================
  // SESSIONS
  // ============================================

  Future<Session> createSession({
    required String campaignId,
    int? sessionNumber,
    String? title,
    required DateTime date,
  }) async {
    final db = await _db.database;
    final now = DateTime.now();
    final session = Session(
      id: _uuid.v4(),
      campaignId: campaignId,
      sessionNumber: sessionNumber,
      title: title,
      date: date,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('sessions', session.toMap());
    return session;
  }

  Future<Session?> getSessionById(String id) async {
    final db = await _db.database;
    final results = await db.query(
      'sessions',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isEmpty) return null;
    return Session.fromMap(results.first);
  }

  Future<List<Session>> getSessionsByCampaign(String campaignId) async {
    final db = await _db.database;
    final results = await db.query(
      'sessions',
      where: 'campaign_id = ?',
      whereArgs: [campaignId],
      orderBy: 'date DESC',
    );
    return results.map((m) => Session.fromMap(m)).toList();
  }

  Future<int> getNextSessionNumber(String campaignId) async {
    final db = await _db.database;
    final results = await db.rawQuery(
      '''
      SELECT MAX(session_number) as max_num FROM sessions
      WHERE campaign_id = ?
    ''',
      [campaignId],
    );
    final maxNum = results.first['max_num'] as int?;
    return (maxNum ?? 0) + 1;
  }

  Future<void> updateSession(Session session) async {
    final db = await _db.database;
    await db.update(
      'sessions',
      session.copyWith(updatedAt: DateTime.now()).toMap(),
      where: 'id = ?',
      whereArgs: [session.id],
    );
  }

  Future<void> updateSessionStatus(String id, SessionStatus status) async {
    final db = await _db.database;
    await db.update(
      'sessions',
      {'status': status.value, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> deleteSession(String id) async {
    final db = await _db.database;
    await db.delete('sessions', where: 'id = ?', whereArgs: [id]);
  }

  /// Deletes a session and all related data (cascade).
  Future<void> deleteSessionWithRelated(String id) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      // Get transcript IDs for segment cleanup
      final transcripts = await txn.query(
        'session_transcripts',
        columns: ['id'],
        where: 'session_id = ?',
        whereArgs: [id],
      );
      for (final t in transcripts) {
        await txn.delete(
          'transcript_segments',
          where: 'transcript_id = ?',
          whereArgs: [t['id']],
        );
      }
      // Delete all session-linked rows
      for (final table in [
        'npc_quotes',
        'entity_appearances',
        'player_moments',
        'action_items',
        'scenes',
        'session_summaries',
        'session_transcripts',
        'session_audio',
        'session_attendees',
        'processing_queue',
      ]) {
        await txn.delete(table, where: 'session_id = ?', whereArgs: [id]);
      }
      // Null out resolved_session_id references in action_items
      await txn.update(
        'action_items',
        {'resolved_session_id': null},
        where: 'resolved_session_id = ?',
        whereArgs: [id],
      );
      // Delete the session itself
      await txn.delete('sessions', where: 'id = ?', whereArgs: [id]);
    });
  }

  // ============================================
  // SESSION ATTENDEES
  // ============================================

  Future<SessionAttendee> addAttendee({
    required String sessionId,
    required String playerId,
    String? characterId,
  }) async {
    final db = await _db.database;
    final attendee = SessionAttendee(
      id: _uuid.v4(),
      sessionId: sessionId,
      playerId: playerId,
      characterId: characterId,
    );
    await db.insert('session_attendees', attendee.toMap());
    return attendee;
  }

  Future<List<SessionAttendee>> getAttendeesBySession(String sessionId) async {
    final db = await _db.database;
    final results = await db.query(
      'session_attendees',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    return results.map((m) => SessionAttendee.fromMap(m)).toList();
  }

  /// Atomically replace all attendees for a session.
  Future<void> replaceAttendees({
    required String sessionId,
    required List<({String playerId, String? characterId})> attendees,
  }) async {
    final db = await _db.database;
    await db.transaction((txn) async {
      await txn.delete(
        'session_attendees',
        where: 'session_id = ?',
        whereArgs: [sessionId],
      );
      for (final a in attendees) {
        final id = _uuid.v4();
        await txn.insert('session_attendees', {
          'id': id,
          'session_id': sessionId,
          'player_id': a.playerId,
          'character_id': a.characterId,
        });
      }
    });
  }

  // ============================================
  // SESSION AUDIO (IMMUTABLE - INSERT ONLY)
  // ============================================

  Future<SessionAudio> createAudio({
    required String sessionId,
    required String filePath,
    int? fileSizeBytes,
    String? format,
    int? durationSeconds,
    String? checksum,
  }) async {
    final db = await _db.database;
    final audio = SessionAudio(
      id: _uuid.v4(),
      sessionId: sessionId,
      filePath: filePath,
      fileSizeBytes: fileSizeBytes,
      format: format,
      durationSeconds: durationSeconds,
      checksum: checksum,
      createdAt: DateTime.now(),
    );
    await db.insert('session_audio', audio.toMap());
    return audio;
  }

  Future<SessionAudio?> getAudioBySession(String sessionId) async {
    final db = await _db.database;
    final results = await db.query(
      'session_audio',
      where: 'session_id = ?',
      whereArgs: [sessionId],
    );
    if (results.isEmpty) return null;
    return SessionAudio.fromMap(results.first);
  }

  // ============================================
  // SESSION TRANSCRIPTS (IMMUTABLE - INSERT ONLY)
  // ============================================

  Future<SessionTranscript> createTranscript({
    required String sessionId,
    required String rawText,
    String? whisperModel,
    String language = 'en',
  }) async {
    final db = await _db.database;

    // Get next version number
    final versionResults = await db.rawQuery(
      '''
      SELECT MAX(version) as max_ver FROM session_transcripts
      WHERE session_id = ?
    ''',
      [sessionId],
    );
    final maxVer = versionResults.first['max_ver'] as int?;
    final nextVersion = (maxVer ?? 0) + 1;

    final transcript = SessionTranscript(
      id: _uuid.v4(),
      sessionId: sessionId,
      version: nextVersion,
      rawText: rawText,
      whisperModel: whisperModel,
      language: language,
      createdAt: DateTime.now(),
    );
    await db.insert('session_transcripts', transcript.toMap());
    return transcript;
  }

  Future<SessionTranscript?> getLatestTranscript(String sessionId) async {
    final db = await _db.database;
    final results = await db.query(
      'session_transcripts',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'version DESC',
      limit: 1,
    );
    if (results.isEmpty) return null;
    return SessionTranscript.fromMap(results.first);
  }

  Future<List<SessionTranscript>> getAllTranscripts(String sessionId) async {
    final db = await _db.database;
    final results = await db.query(
      'session_transcripts',
      where: 'session_id = ?',
      whereArgs: [sessionId],
      orderBy: 'version DESC',
    );
    return results.map((m) => SessionTranscript.fromMap(m)).toList();
  }

  /// Save user's edited version of the transcript.
  /// The original rawText remains untouched.
  Future<void> updateTranscriptText(String transcriptId, String newText) async {
    final db = await _db.database;
    await db.update(
      'session_transcripts',
      {'edited_text': newText},
      where: 'id = ?',
      whereArgs: [transcriptId],
    );
  }

  /// Revert to the original transcript by clearing editedText.
  Future<void> revertTranscriptText(String transcriptId) async {
    final db = await _db.database;
    await db.update(
      'session_transcripts',
      {'edited_text': null},
      where: 'id = ?',
      whereArgs: [transcriptId],
    );
  }

  // ============================================
  // TRANSCRIPT SEGMENTS (IMMUTABLE - INSERT ONLY)
  // ============================================

  Future<void> createSegments(List<TranscriptSegment> segments) async {
    final db = await _db.database;
    final batch = db.batch();
    for (final segment in segments) {
      batch.insert('transcript_segments', segment.toMap());
    }
    await batch.commit(noResult: true);
  }

  Future<List<TranscriptSegment>> getSegmentsByTranscript(
    String transcriptId,
  ) async {
    final db = await _db.database;
    final results = await db.query(
      'transcript_segments',
      where: 'transcript_id = ?',
      whereArgs: [transcriptId],
      orderBy: 'segment_index ASC',
    );
    return results.map((m) => TranscriptSegment.fromMap(m)).toList();
  }
}
