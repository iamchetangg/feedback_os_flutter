import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqflite/sqflite.dart';
import 'package:feedback_os_flutter/src/features/feedback/data/datasources/sqlite_submission_store.dart';
import 'package:feedback_os_flutter/src/features/feedback/domain/entities/queued_feedback.dart';

class MockDatabase extends Mock implements Database {}

void main() {
  group('SqliteSubmissionStore', () {
    late MockDatabase mockDb;
    late SqliteSubmissionStore store;
    const testScope = 'fos_pk_test_123';
    final now = DateTime.utc(2026, 10, 13, 12);

    setUp(() {
      mockDb = MockDatabase();
      when(() => mockDb.isOpen).thenReturn(true);
      store = SqliteSubmissionStore(database: mockDb);
    });

    test('insert executes db.insert with replace conflict algorithm', () async {
      when(
        () => mockDb.insert(
          SqliteSubmissionStore.tableName,
          any(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        ),
      ).thenAnswer((_) async => 1);

      final item = QueuedFeedback(
        clientSubmissionId: 'sub_123',
        payloadJson: '{"title":"Crash"}',
        appScope: testScope,
        createdAt: now,
        nextAttemptAt: now,
      );

      await store.insert(item);

      final captured = verify(
        () => mockDb.insert(
          SqliteSubmissionStore.tableName,
          captureAny(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        ),
      ).captured;

      final map = captured.first as Map<String, dynamic>;
      expect(map['client_submission_id'], equals('sub_123'));
      expect(map['app_scope'], equals(testScope));
      expect(map['status'], equals('pending'));
    });

    test('getDue queries matching scope and pending/retryScheduled statuses',
        () async {
      final nowMs = now.toUtc().millisecondsSinceEpoch;
      when(
        () => mockDb.query(
          SqliteSubmissionStore.tableName,
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
          orderBy: any(named: 'orderBy'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => [
          {
            'client_submission_id': 'sub_123',
            'payload_json': '{"title":"Test"}',
            'app_scope': testScope,
            'external_user_id': null,
            'created_at': nowMs,
            'next_attempt_at': nowMs,
            'attempt_count': 0,
            'status': 'pending',
            'last_error_code': null,
            'last_error_message': null,
          }
        ],
      );

      final items = await store.getDue(now, appScope: testScope, limit: 10);
      expect(items.length, equals(1));
      expect(items.first.clientSubmissionId, equals('sub_123'));
      expect(items.first.status, equals(QueueStatus.pending));

      verify(
        () => mockDb.query(
          SqliteSubmissionStore.tableName,
          where: 'app_scope = ? AND status IN (?, ?) AND next_attempt_at <= ?',
          whereArgs: [
            testScope,
            QueueStatus.pending.name,
            QueueStatus.retryScheduled.name,
            nowMs,
          ],
          orderBy: 'created_at ASC',
          limit: 10,
        ),
      ).called(1);
    });

    test(
        'scheduleRetry updates status, attempt_count, next_attempt_at, and error',
        () async {
      when(
        () => mockDb.update(
          SqliteSubmissionStore.tableName,
          any(),
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        ),
      ).thenAnswer((_) async => 1);

      final nextAttempt = now.add(const Duration(seconds: 30));
      await store.scheduleRetry(
        'sub_123',
        nextAttemptAt: nextAttempt,
        attemptCount: 2,
        errorCode: 'rate_limited',
        errorMessage: 'Too many requests',
      );

      final captured = verify(
        () => mockDb.update(
          SqliteSubmissionStore.tableName,
          captureAny(),
          where: 'client_submission_id = ?',
          whereArgs: ['sub_123'],
        ),
      ).captured;

      final map = captured.first as Map<String, dynamic>;
      expect(map['status'], equals('retryScheduled'));
      expect(map['attempt_count'], equals(2));
      expect(map['last_error_code'], equals('rate_limited'));
      expect(map['last_error_message'], equals('Too many requests'));
      expect(map['next_attempt_at'],
          equals(nextAttempt.toUtc().millisecondsSinceEpoch));
    });

    test('remove and deleteExpired invoke db.delete properly', () async {
      when(
        () => mockDb.delete(
          SqliteSubmissionStore.tableName,
          where: any(named: 'where'),
          whereArgs: any(named: 'whereArgs'),
        ),
      ).thenAnswer((_) async => 1);

      await store.remove('sub_123');
      verify(
        () => mockDb.delete(
          SqliteSubmissionStore.tableName,
          where: 'client_submission_id = ?',
          whereArgs: ['sub_123'],
        ),
      ).called(1);

      await store.deleteExpired(now);
      verify(
        () => mockDb.delete(
          SqliteSubmissionStore.tableName,
          where: 'created_at < ?',
          whereArgs: [now.toUtc().millisecondsSinceEpoch],
        ),
      ).called(1);
    });

    test('close closes open database', () async {
      when(() => mockDb.close()).thenAnswer((_) async {});

      await store.close();
      verify(() => mockDb.close()).called(1);
    });
  });
}
