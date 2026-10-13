import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';
import 'package:feedback_os_flutter/src/features/feedback/data/datasources/feedback_remote_data_source.dart';
import 'package:feedback_os_flutter/src/features/feedback/data/datasources/queue_sync_engine.dart';
import 'package:feedback_os_flutter/src/features/feedback/data/models/feedback_item_model.dart';
import 'package:feedback_os_flutter/src/features/feedback/data/models/feedback_submission_model.dart';

class MockFeedbackRemoteDataSource extends Mock
    implements FeedbackRemoteDataSource {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const FeedbackSubmissionModel(
        clientSubmissionId: 'sub_fallback_1234',
        type: FeedbackType.bug,
        title: 'Title',
        device: FeedbackDeviceInfo(
          osVersion: 'os',
          appVersion: 'app',
          deviceModel: 'model',
        ),
      ),
    );
  });

  group('QueueSyncEngine', () {
    late InMemorySubmissionStore store;
    late MockFeedbackRemoteDataSource mockRemote;
    late QueueSyncEngine engine;
    const testScope = 'fos_pk_test_scope_123';
    final now = DateTime.utc(2026, 10, 13, 12);

    String? activeUserId = 'active_user_1';

    setUp(() async {
      store = InMemorySubmissionStore();
      await store.open();
      mockRemote = MockFeedbackRemoteDataSource();
      activeUserId = 'active_user_1';

      when(() => mockRemote.identify(any())).thenAnswer((_) async {});

      engine = QueueSyncEngine(
        store: store,
        remoteDataSource: mockRemote,
        options: FeedbackOSOptions(queueItemTtl: const Duration(days: 7)),
        appScope: testScope,
        getActiveUserId: () async => activeUserId,
        setActiveUserId: (id) async => activeUserId = id,
      );
    });

    QueuedFeedback createQueued({
      required String id,
      String? externalUserId,
      QueueStatus status = QueueStatus.pending,
      DateTime? nextAttemptAt,
      DateTime? createdAt,
    }) {
      final payload = {
        'client_submission_id': id,
        'type': 'bug',
        'title': 'Test bug',
        'description': '',
        'category': null,
        'device': {
          'os_version': 'iOS 17',
          'app_version': '1.0',
          'device_model': 'iPhone',
        },
        'screenshot_upload_ids': <String>[],
      };

      return QueuedFeedback(
        clientSubmissionId: id,
        payloadJson: jsonEncode(payload),
        appScope: testScope,
        externalUserId: externalUserId,
        createdAt: createdAt ?? now,
        nextAttemptAt: nextAttemptAt ?? now,
        status: status,
      );
    }

    test('successfully delivers item and removes from queue', () async {
      final queued = createQueued(id: 'sub_1');
      await store.insert(queued);

      when(() => mockRemote.submitFeedback(any()))
          .thenAnswer((_) async => FeedbackItemModel(
                id: 'server_id_1',
                type: FeedbackType.bug,
                title: 'Test bug',
                description: '',
                status: 'open',
                isPublic: false,
                createdAt: DateTime.utc(2026, 10, 13),
              ));

      final count = await engine.flushQueue(currentClock: now);

      expect(count, equals(1));
      expect(await store.getById('sub_1'), isNull);
      verify(() => mockRemote.submitFeedback(any())).called(1);
    });

    test('schedules retry on transient network error', () async {
      final queued = createQueued(id: 'sub_transient');
      await store.insert(queued);

      when(() => mockRemote.submitFeedback(any())).thenThrow(
        const FeedbackOsNetworkException('Socket closed'),
      );

      final count = await engine.flushQueue(currentClock: now);

      expect(count, equals(0));
      final item = await store.getById('sub_transient');
      expect(item?.status, equals(QueueStatus.retryScheduled));
      expect(item?.attemptCount, equals(1));
      expect(item?.lastErrorCode, equals('network_error'));
      expect(item?.nextAttemptAt.isAfter(now), isTrue);
    });

    test('marks permanently failed on 400 validation error', () async {
      final queued = createQueued(id: 'sub_bad_payload');
      await store.insert(queued);

      when(() => mockRemote.submitFeedback(any())).thenThrow(
        const FeedbackOsValidationException('Malformed JSON', statusCode: 400),
      );

      final count = await engine.flushQueue(currentClock: now);

      expect(count, equals(0));
      final item = await store.getById('sub_bad_payload');
      expect(item?.status, equals(QueueStatus.permanentlyFailed));
      expect(item?.lastErrorCode, equals('invalid_request'));
    });

    test('honors Retry-After on 429 rate limit', () async {
      final queued = createQueued(id: 'sub_rate_limited');
      await store.insert(queued);

      when(() => mockRemote.submitFeedback(any())).thenThrow(
        const FeedbackOsRateLimitException(
          'Slow down',
          retryAfter: Duration(seconds: 45),
        ),
      );

      await engine.flushQueue(currentClock: now);

      final item = await store.getById('sub_rate_limited');
      expect(item?.status, equals(QueueStatus.retryScheduled));
      expect(item?.nextAttemptAt, equals(now.add(const Duration(seconds: 45))));
    });

    test(
        'restores active user identity after syncing queued item with different user',
        () async {
      activeUserId = 'logged_in_user_2';

      // Queued item belongs to user_1
      final queued = createQueued(id: 'sub_user_1', externalUserId: 'user_1');
      await store.insert(queued);

      when(() => mockRemote.identify('user_1')).thenAnswer((_) async {});
      when(() => mockRemote.identify('logged_in_user_2'))
          .thenAnswer((_) async {});
      when(() => mockRemote.submitFeedback(any()))
          .thenAnswer((_) async => FeedbackItemModel(
                id: 'srv_1',
                type: FeedbackType.bug,
                title: 'Test bug',
                description: '',
                status: 'open',
                isPublic: false,
                createdAt: DateTime.utc(2026, 10, 13),
              ));

      await engine.flushQueue(currentClock: now);

      // Verify user_1 was identified before submit
      verify(() => mockRemote.identify('user_1')).called(1);
      // Verify active user was restored afterward
      expect(activeUserId, equals('logged_in_user_2'));
    });

    test('prunes expired items older than queueItemTtl', () async {
      final oldItem = createQueued(
        id: 'old_item',
        createdAt: now.subtract(const Duration(days: 8)),
      );
      await store.insert(oldItem);

      await engine.flushQueue(currentClock: now);

      expect(await store.getById('old_item'), isNull);
    });
  });
}
