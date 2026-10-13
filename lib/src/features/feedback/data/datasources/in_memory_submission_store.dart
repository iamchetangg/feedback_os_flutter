import '../../domain/entities/queued_feedback.dart';
import 'submission_store.dart';

/// In-memory implementation of [SubmissionStore] for testing.
class InMemorySubmissionStore implements SubmissionStore {
  final Map<String, QueuedFeedback> _items = {};
  bool _isOpen = false;

  bool get isOpen => _isOpen;

  @override
  Future<void> open() async {
    _isOpen = true;
  }

  @override
  Future<void> insert(QueuedFeedback item) async {
    _items[item.clientSubmissionId] = item;
  }

  @override
  Future<List<QueuedFeedback>> getDue(
    DateTime now, {
    required String appScope,
    int limit = 20,
  }) async {
    final list = _items.values
        .where((item) =>
            item.appScope == appScope &&
            (item.status == QueueStatus.pending ||
                item.status == QueueStatus.retryScheduled) &&
            !item.nextAttemptAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

    return list.take(limit).toList();
  }

  @override
  Future<QueuedFeedback?> getById(String clientSubmissionId) async {
    return _items[clientSubmissionId];
  }

  @override
  Future<int> getPendingCount({required String appScope}) async {
    return _items.values
        .where((item) =>
            item.appScope == appScope &&
            (item.status == QueueStatus.pending ||
                item.status == QueueStatus.sending ||
                item.status == QueueStatus.retryScheduled))
        .length;
  }

  @override
  Future<int> getFailedCount({required String appScope}) async {
    return _items.values
        .where((item) =>
            item.appScope == appScope &&
            item.status == QueueStatus.permanentlyFailed)
        .length;
  }

  @override
  Future<int> getTotalCount({required String appScope}) async {
    return _items.values.where((item) => item.appScope == appScope).length;
  }

  @override
  Future<void> remove(String clientSubmissionId) async {
    _items.remove(clientSubmissionId);
  }

  @override
  Future<void> markSending(String clientSubmissionId) async {
    final item = _items[clientSubmissionId];
    if (item != null) {
      _items[clientSubmissionId] = item.copyWith(status: QueueStatus.sending);
    }
  }

  @override
  Future<void> scheduleRetry(
    String clientSubmissionId, {
    required DateTime nextAttemptAt,
    required int attemptCount,
    required String errorCode,
    String? errorMessage,
  }) async {
    final item = _items[clientSubmissionId];
    if (item != null) {
      _items[clientSubmissionId] = item.copyWith(
        status: QueueStatus.retryScheduled,
        nextAttemptAt: nextAttemptAt,
        attemptCount: attemptCount,
        lastErrorCode: errorCode,
        lastErrorMessage: errorMessage,
      );
    }
  }

  @override
  Future<void> markPermanentlyFailed(
    String clientSubmissionId, {
    required String errorCode,
    String? errorMessage,
  }) async {
    final item = _items[clientSubmissionId];
    if (item != null) {
      _items[clientSubmissionId] = item.copyWith(
        status: QueueStatus.permanentlyFailed,
        lastErrorCode: errorCode,
        lastErrorMessage: errorMessage,
      );
    }
  }

  @override
  Future<void> clearPermanentlyFailed({required String appScope}) async {
    _items.removeWhere((_, item) =>
        item.appScope == appScope &&
        item.status == QueueStatus.permanentlyFailed);
  }

  @override
  Future<void> deleteExpired(DateTime threshold) async {
    _items.removeWhere((_, item) => item.createdAt.isBefore(threshold));
  }

  @override
  Future<void> close() async {
    _isOpen = false;
  }
}
