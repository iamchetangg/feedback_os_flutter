import '../../domain/entities/queued_feedback.dart';

/// Contract for durable local storage of queued feedback submissions.
abstract interface class SubmissionStore {
  /// Opens the storage backend (e.g. database connection).
  Future<void> open();

  /// Persists a new item into the queue.
  Future<void> insert(QueuedFeedback item);

  /// Retrieves due items ready for transmission (status is pending or retryScheduled, nextAttemptAt <= now).
  Future<List<QueuedFeedback>> getDue(
    DateTime now, {
    required String appScope,
    int limit = 20,
  });

  /// Retrieves a specific queued item by clientSubmissionId.
  Future<QueuedFeedback?> getById(String clientSubmissionId);

  /// Returns total count of items pending transmission for the given app scope.
  Future<int> getPendingCount({required String appScope});

  /// Returns total count of permanently failed items for the given app scope.
  Future<int> getFailedCount({required String appScope});

  /// Returns total count of all items (pending, sending, failed) for the given app scope.
  Future<int> getTotalCount({required String appScope});

  /// Removes an item upon confirmed delivery.
  Future<void> remove(String clientSubmissionId);

  /// Updates status to [QueueStatus.sending].
  Future<void> markSending(String clientSubmissionId);

  /// Schedules a retry with backoff.
  Future<void> scheduleRetry(
    String clientSubmissionId, {
    required DateTime nextAttemptAt,
    required int attemptCount,
    required String errorCode,
    String? errorMessage,
  });

  /// Marks an item as permanently failed.
  Future<void> markPermanentlyFailed(
    String clientSubmissionId, {
    required String errorCode,
    String? errorMessage,
  });

  /// Discards all permanently failed items for the given app scope.
  Future<void> clearPermanentlyFailed({required String appScope});

  /// Deletes items older than the specified threshold.
  Future<void> deleteExpired(DateTime threshold);

  /// Closes the storage connection.
  Future<void> close();
}
