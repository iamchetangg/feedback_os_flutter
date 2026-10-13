import 'package:flutter_test/flutter_test.dart';
import 'package:feedback_os_flutter/src/features/feedback/data/datasources/in_memory_submission_store.dart';
import 'package:feedback_os_flutter/src/features/feedback/domain/entities/queued_feedback.dart';

void main() {
  group('InMemorySubmissionStore', () {
    late InMemorySubmissionStore store;
    const testScope = 'fos_pk_test_123';
    final now = DateTime.utc(2026, 10, 13, 12);

    setUp(() async {
      store = InMemorySubmissionStore();
      await store.open();
    });

    QueuedFeedback createItem({
      required String id,
      String scope = testScope,
      QueueStatus status = QueueStatus.pending,
      DateTime? nextAttemptAt,
      DateTime? createdAt,
    }) {
      return QueuedFeedback(
        clientSubmissionId: id,
        payloadJson: '{"title":"test"}',
        appScope: scope,
        createdAt: createdAt ?? now,
        nextAttemptAt: nextAttemptAt ?? now,
        status: status,
      );
    }

    test('inserts and retrieves item by clientSubmissionId', () async {
      final item = createItem(id: 'item_1');
      await store.insert(item);

      final retrieved = await store.getById('item_1');
      expect(retrieved, equals(item));
    });

    test('getDue returns only due items matching appScope', () async {
      final dueItem = createItem(id: 'due_1', nextAttemptAt: now);
      final futureItem = createItem(
        id: 'future_1',
        nextAttemptAt: now.add(const Duration(minutes: 5)),
      );
      final wrongScope = createItem(
        id: 'wrong_scope_1',
        scope: 'other_scope',
      );
      final failedItem = createItem(
        id: 'failed_1',
        status: QueueStatus.permanentlyFailed,
      );

      await store.insert(dueItem);
      await store.insert(futureItem);
      await store.insert(wrongScope);
      await store.insert(failedItem);

      final dueList = await store.getDue(now, appScope: testScope);
      expect(dueList.length, equals(1));
      expect(dueList.first.clientSubmissionId, equals('due_1'));
    });

    test('state transitions: markSending, scheduleRetry, markPermanentlyFailed',
        () async {
      final item = createItem(id: 'item_1');
      await store.insert(item);

      await store.markSending('item_1');
      var current = await store.getById('item_1');
      expect(current?.status, equals(QueueStatus.sending));

      final retryTime = now.add(const Duration(seconds: 30));
      await store.scheduleRetry(
        'item_1',
        nextAttemptAt: retryTime,
        attemptCount: 1,
        errorCode: 'network_error',
        errorMessage: 'timeout',
      );
      current = await store.getById('item_1');
      expect(current?.status, equals(QueueStatus.retryScheduled));
      expect(current?.attemptCount, equals(1));
      expect(current?.lastErrorCode, equals('network_error'));
      expect(current?.nextAttemptAt, equals(retryTime));

      await store.markPermanentlyFailed(
        'item_1',
        errorCode: 'invalid_request',
        errorMessage: 'Bad JSON',
      );
      current = await store.getById('item_1');
      expect(current?.status, equals(QueueStatus.permanentlyFailed));
      expect(current?.lastErrorCode, equals('invalid_request'));
    });

    test('counts and cleanup', () async {
      await store.insert(createItem(id: 'pending_1'));
      await store.insert(
        createItem(id: 'failed_1', status: QueueStatus.permanentlyFailed),
      );

      expect(await store.getPendingCount(appScope: testScope), equals(1));
      expect(await store.getFailedCount(appScope: testScope), equals(1));

      await store.clearPermanentlyFailed(appScope: testScope);
      expect(await store.getFailedCount(appScope: testScope), equals(0));
      expect(await store.getById('failed_1'), isNull);
      expect(await store.getById('pending_1'), isNotNull);

      // deleteExpired
      final oldThreshold = now.add(const Duration(days: 1));
      await store.deleteExpired(oldThreshold);
      expect(await store.getById('pending_1'), isNull);
    });
  });
}
