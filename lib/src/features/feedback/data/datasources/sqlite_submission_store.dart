import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../domain/entities/queued_feedback.dart';
import 'submission_store.dart';

/// SQLite-backed persistent implementation of [SubmissionStore].
class SqliteSubmissionStore implements SubmissionStore {
  static const String tableName = 'fos_queued_feedback';
  static const String databaseName = 'feedback_os_offline.db';
  static const int databaseVersion = 1;

  final String? _customPath;
  Database? _db;

  SqliteSubmissionStore({String? customPath, Database? database})
      : _customPath = customPath,
        _db = database;

  Database get db {
    if (_db == null || !_db!.isOpen) {
      throw StateError('SqliteSubmissionStore is not open. Call open() first.');
    }
    return _db!;
  }

  @override
  Future<void> open() async {
    if (_db != null && _db!.isOpen) return;

    final dbPath =
        _customPath ?? p.join(await getDatabasesPath(), databaseName);

    _db = await openDatabase(
      dbPath,
      version: databaseVersion,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS $tableName (
            client_submission_id TEXT PRIMARY KEY,
            payload_json TEXT NOT NULL,
            app_scope TEXT NOT NULL,
            external_user_id TEXT,
            created_at INTEGER NOT NULL,
            next_attempt_at INTEGER NOT NULL,
            attempt_count INTEGER NOT NULL DEFAULT 0,
            status TEXT NOT NULL,
            last_error_code TEXT,
            last_error_message TEXT
          );
        ''');
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_fos_due 
          ON $tableName (app_scope, status, next_attempt_at);
        ''');
        await db.execute('''
          CREATE INDEX IF NOT EXISTS idx_fos_created 
          ON $tableName (created_at);
        ''');
      },
    );
  }

  @override
  Future<void> insert(QueuedFeedback item) async {
    await db.insert(
      tableName,
      _toMap(item),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<QueuedFeedback>> getDue(
    DateTime now, {
    required String appScope,
    int limit = 20,
  }) async {
    final nowMs = now.toUtc().millisecondsSinceEpoch;
    final results = await db.query(
      tableName,
      where: 'app_scope = ? AND status IN (?, ?) AND next_attempt_at <= ?',
      whereArgs: [
        appScope,
        QueueStatus.pending.name,
        QueueStatus.retryScheduled.name,
        nowMs,
      ],
      orderBy: 'created_at ASC',
      limit: limit,
    );

    return results.map(_fromMap).toList();
  }

  @override
  Future<QueuedFeedback?> getById(String clientSubmissionId) async {
    final results = await db.query(
      tableName,
      where: 'client_submission_id = ?',
      whereArgs: [clientSubmissionId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return _fromMap(results.first);
  }

  @override
  Future<int> getPendingCount({required String appScope}) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE app_scope = ? AND status IN (?, ?, ?)',
      [
        appScope,
        QueueStatus.pending.name,
        QueueStatus.sending.name,
        QueueStatus.retryScheduled.name,
      ],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<int> getFailedCount({required String appScope}) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE app_scope = ? AND status = ?',
      [appScope, QueueStatus.permanentlyFailed.name],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<int> getTotalCount({required String appScope}) async {
    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM $tableName WHERE app_scope = ?',
      [appScope],
    );
    return Sqflite.firstIntValue(result) ?? 0;
  }

  @override
  Future<void> remove(String clientSubmissionId) async {
    await db.delete(
      tableName,
      where: 'client_submission_id = ?',
      whereArgs: [clientSubmissionId],
    );
  }

  @override
  Future<void> markSending(String clientSubmissionId) async {
    await db.update(
      tableName,
      {'status': QueueStatus.sending.name},
      where: 'client_submission_id = ?',
      whereArgs: [clientSubmissionId],
    );
  }

  @override
  Future<void> scheduleRetry(
    String clientSubmissionId, {
    required DateTime nextAttemptAt,
    required int attemptCount,
    required String errorCode,
    String? errorMessage,
  }) async {
    await db.update(
      tableName,
      {
        'status': QueueStatus.retryScheduled.name,
        'next_attempt_at': nextAttemptAt.toUtc().millisecondsSinceEpoch,
        'attempt_count': attemptCount,
        'last_error_code': errorCode,
        'last_error_message': errorMessage,
      },
      where: 'client_submission_id = ?',
      whereArgs: [clientSubmissionId],
    );
  }

  @override
  Future<void> markPermanentlyFailed(
    String clientSubmissionId, {
    required String errorCode,
    String? errorMessage,
  }) async {
    await db.update(
      tableName,
      {
        'status': QueueStatus.permanentlyFailed.name,
        'last_error_code': errorCode,
        'last_error_message': errorMessage,
      },
      where: 'client_submission_id = ?',
      whereArgs: [clientSubmissionId],
    );
  }

  @override
  Future<void> clearPermanentlyFailed({required String appScope}) async {
    await db.delete(
      tableName,
      where: 'app_scope = ? AND status = ?',
      whereArgs: [appScope, QueueStatus.permanentlyFailed.name],
    );
  }

  @override
  Future<void> deleteExpired(DateTime threshold) async {
    final thresholdMs = threshold.toUtc().millisecondsSinceEpoch;
    await db.delete(
      tableName,
      where: 'created_at < ?',
      whereArgs: [thresholdMs],
    );
  }

  @override
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }

  Map<String, dynamic> _toMap(QueuedFeedback item) {
    return {
      'client_submission_id': item.clientSubmissionId,
      'payload_json': item.payloadJson,
      'app_scope': item.appScope,
      'external_user_id': item.externalUserId,
      'created_at': item.createdAt.toUtc().millisecondsSinceEpoch,
      'next_attempt_at': item.nextAttemptAt.toUtc().millisecondsSinceEpoch,
      'attempt_count': item.attemptCount,
      'status': item.status.name,
      'last_error_code': item.lastErrorCode,
      'last_error_message': item.lastErrorMessage,
    };
  }

  QueuedFeedback _fromMap(Map<String, dynamic> map) {
    return QueuedFeedback(
      clientSubmissionId: map['client_submission_id'] as String,
      payloadJson: map['payload_json'] as String,
      appScope: map['app_scope'] as String,
      externalUserId: map['external_user_id'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['created_at'] as int,
        isUtc: true,
      ),
      nextAttemptAt: DateTime.fromMillisecondsSinceEpoch(
        map['next_attempt_at'] as int,
        isUtc: true,
      ),
      attemptCount: map['attempt_count'] as int? ?? 0,
      status: QueueStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => QueueStatus.pending,
      ),
      lastErrorCode: map['last_error_code'] as String?,
      lastErrorMessage: map['last_error_message'] as String?,
    );
  }
}
