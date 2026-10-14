import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import '../../../../config/feedback_os_options.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../uploads/domain/repositories/upload_repository.dart';
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
  final UploadRepository? _uploadRepository;
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
    UploadRepository? uploadRepository,
    Random? random,
  })  : _store = store,
        _remoteDataSource = remoteDataSource,
        _options = options,
        _appScope = appScope,
        _getActiveUserId = getActiveUserId,
        _setActiveUserId = setActiveUserId,
        _uploadRepository = uploadRepository,
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

        // 4. Submit feedback payload (including offline attachment re-reservations)
        try {
          final payloadMap =
              Map<String, dynamic>.from(jsonDecode(item.payloadJson) as Map);

          final pendingAttachments =
              (payloadMap['pending_attachments'] as List<dynamic>?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList();

          if (pendingAttachments != null &&
              pendingAttachments.isNotEmpty &&
              _uploadRepository != null) {
            final uploadIds = List<String>.from(
              (payloadMap['screenshot_upload_ids'] as List<dynamic>?)
                      ?.map((e) => e.toString()) ??
                  const [],
            );

            bool uploadErrorOccurred = false;

            for (final attMap in pendingAttachments) {
              final contentType = attMap['content_type'] as String;
              final bytesBase64 = attMap['bytes_base64'] as String?;
              final bytes = bytesBase64 != null
                  ? base64Decode(bytesBase64)
                  : Uint8List(0);

              // 1. Reserve fresh upload URL (handles expired reservations automatically)
              final reserveResult = await _uploadRepository.reserveUpload(
                contentType: contentType,
                byteSize: bytes.lengthInBytes,
              );

              final uploadId = await reserveResult.fold(
                (failure) async {
                  if (failure is ValidationFailure ||
                      failure is UploadInvalidFailure ||
                      failure is PayloadTooLargeFailure) {
                    await _store.markPermanentlyFailed(
                      item.clientSubmissionId,
                      errorCode: failure.code ?? 'upload_invalid',
                      errorMessage: failure.message,
                    );
                    uploadErrorOccurred = true;
                    return null;
                  }
                  throw FeedbackOsNetworkException(
                    failure.message,
                    statusCode: failure.statusCode,
                  );
                },
                (reservation) async {
                  // 2. Transmit raw bytes directly to storage bucket with returned headers
                  final uploadResult = await _uploadRepository.uploadBinary(
                    reservation: reservation,
                    bytes: bytes,
                  );
                  return uploadResult.fold(
                    (failure) {
                      throw FeedbackOsNetworkException(
                        failure.message,
                        statusCode: failure.statusCode,
                      );
                    },
                    (_) => reservation.uploadId,
                  );
                },
              );

              if (uploadErrorOccurred) break;
              if (uploadId != null) {
                uploadIds.add(uploadId);
              }
            }

            if (uploadErrorOccurred) {
              continue;
            }

            payloadMap['screenshot_upload_ids'] = uploadIds;
            payloadMap.remove('pending_attachments');
          }

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
