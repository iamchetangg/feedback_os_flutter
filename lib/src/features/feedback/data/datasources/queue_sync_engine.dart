import 'dart:convert';
import 'dart:math';
import '../../../../config/feedback_os_options.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/queued_feedback.dart';
import '../models/feedback_submission_model.dart';
import 'feedback_remote_data_source.dart';
import 'submission_store.dart';

/// Coordinates synchronized delivery, backoff, and identity restoration for queued feedback.
class QueueSyncEngine {
  final SubmissionStore _store;
  final FeedbackRemoteDataSource _remoteDataSource;
  final FeedbackOSOptions _options;
  final String _appScope;
  final Future<String?> Function() _getActiveUserId;
  final Future<void> Function(String?) _setActiveUserId;
  final Random _random;

  bool _isSyncing = false;

  /// Whether a queue synchronization run is currently in progress.
  bool get isSyncing => _isSyncing;

  QueueSyncEngine({
    required SubmissionStore store,
    required FeedbackRemoteDataSource remoteDataSource,
    required FeedbackOSOptions options,
    required String appScope,
    required Future<String?> Function() getActiveUserId,
    required Future<void> Function(String?) setActiveUserId,
    Random? random,
  })  : _store = store,
        _remoteDataSource = remoteDataSource,
        _options = options,
        _appScope = appScope,
        _getActiveUserId = getActiveUserId,
        _setActiveUserId = setActiveUserId,
        _random = random ?? Random();

  /// Flushes all due items from the queue.
  ///
  /// Serialized: concurrent calls safely return early.
  Future<int> flushQueue({DateTime? currentClock}) async {
    if (_isSyncing) return 0;
    _isSyncing = true;

    final now = currentClock ?? DateTime.now().toUtc();
    int processedCount = 0;
    String? originalActiveUserId;

    try {
      // 1. Prune expired records
      final expiryThreshold = now.subtract(_options.queueItemTtl);
      await _store.deleteExpired(expiryThreshold);

      // 2. Fetch due items for this app scope
      final dueItems = await _store.getDue(
        now,
        appScope: _appScope,
        limit: 20,
      );

      if (dueItems.isEmpty) return 0;

      originalActiveUserId = await _getActiveUserId();
      String? currentSyncedUserId = originalActiveUserId;

      for (final item in dueItems) {
        await _store.markSending(item.clientSubmissionId);

        // 3. Serialize identity restoration if queued under a different user
        if (item.externalUserId != currentSyncedUserId) {
          try {
            await _remoteDataSource.identify(item.externalUserId);
            currentSyncedUserId = item.externalUserId;
          } catch (_) {
            // If identity call fails, retry this item later
            await _scheduleRetry(item, now, 'identity_sync_failed', null);
            continue;
          }
        }

        // 4. Submit feedback payload
        try {
          final payloadMap =
              jsonDecode(item.payloadJson) as Map<String, dynamic>;
          final model = FeedbackSubmissionModel.fromJson(payloadMap);

          await _remoteDataSource.submitFeedback(model);

          // Success (201 or 200 idempotent repeat) -> remove from store
          await _store.remove(item.clientSubmissionId);
          processedCount++;
        } on FeedbackOsValidationException catch (e) {
          // Permanent failure (400 bad request) -> do not retry endlessly
          await _store.markPermanentlyFailed(
            item.clientSubmissionId,
            errorCode: e.code ?? 'invalid_request',
            errorMessage: e.message,
          );
        } on FeedbackOsPayloadTooLargeException catch (e) {
          // Permanent failure (413 payload too large)
          await _store.markPermanentlyFailed(
            item.clientSubmissionId,
            errorCode: 'payload_too_large',
            errorMessage: e.message,
          );
        } on FeedbackOsAuthenticationException catch (e) {
          // Auth failed (invalid/revoked key) -> pause queue immediately
          await _scheduleRetry(
            item,
            now,
            e.code ?? 'invalid_key',
            e.message,
          );
          break; // Stop further requests until credentials change
        } on FeedbackOsSubscriptionException catch (e) {
          // Subscription required (402) -> pause queue
          await _scheduleRetry(
            item,
            now,
            e.code ?? 'subscription_required',
            e.message,
          );
          break;
        } on FeedbackOsRateLimitException catch (e) {
          // Rate limited (429) -> honor Retry-After and pause
          await _scheduleRetry(
            item,
            now,
            'rate_limited',
            e.message,
            explicitRetryAfter: e.retryAfter,
          );
          break;
        } catch (e) {
          // Transient network failure or 5xx -> schedule exponential backoff
          await _scheduleRetry(
            item,
            now,
            'network_error',
            e.toString(),
          );
        }
      }
    } finally {
      // 5. Restore active user identity if it differed
      if (originalActiveUserId != null) {
        try {
          await _setActiveUserId(originalActiveUserId);
        } catch (_) {}
      }
      _isSyncing = false;
    }

    return processedCount;
  }

  Future<void> _scheduleRetry(
    QueuedFeedback item,
    DateTime now,
    String errorCode,
    String? errorMessage, {
    Duration? explicitRetryAfter,
  }) async {
    final nextAttemptCount = item.attemptCount + 1;
    final backoff = explicitRetryAfter ?? _calculateBackoff(nextAttemptCount);
    final nextAttemptAt = now.add(backoff);

    await _store.scheduleRetry(
      item.clientSubmissionId,
      nextAttemptAt: nextAttemptAt,
      attemptCount: nextAttemptCount,
      errorCode: errorCode,
      errorMessage: errorMessage,
    );
  }

  /// Calculates bounded exponential backoff with +/- 20% jitter.
  Duration _calculateBackoff(int attemptCount) {
    const baseSeconds = 5;
    const maxSeconds = 3600; // 1 hour max

    final exponential = baseSeconds * pow(2, min(attemptCount - 1, 10));
    final clamped = min(exponential.toInt(), maxSeconds);

    // Add jitter between 0.8x and 1.2x
    final jitterMultiplier = 0.8 + (_random.nextDouble() * 0.4);
    final finalSeconds = max(1, (clamped * jitterMultiplier).round());

    return Duration(seconds: finalSeconds);
  }
}
