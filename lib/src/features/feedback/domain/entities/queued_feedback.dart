import 'package:equatable/equatable.dart';

/// Status of an item within the offline submission queue.
enum QueueStatus {
  /// Waiting for its first transmission attempt.
  pending,

  /// Currently being transmitted over the network.
  sending,

  /// Temporarily failed; waiting for backoff timer to expire.
  retryScheduled,

  /// Permanently rejected by server (e.g., 400 bad request, 413 payload too large).
  permanentlyFailed,
}

/// Represents a durable queued feedback item.
class QueuedFeedback extends Equatable {
  final String clientSubmissionId;
  final String payloadJson;
  final String appScope;
  final String? externalUserId;
  final DateTime createdAt;
  final DateTime nextAttemptAt;
  final int attemptCount;
  final QueueStatus status;
  final String? lastErrorCode;
  final String? lastErrorMessage;

  const QueuedFeedback({
    required this.clientSubmissionId,
    required this.payloadJson,
    required this.appScope,
    this.externalUserId,
    required this.createdAt,
    required this.nextAttemptAt,
    this.attemptCount = 0,
    this.status = QueueStatus.pending,
    this.lastErrorCode,
    this.lastErrorMessage,
  });

  QueuedFeedback copyWith({
    String? clientSubmissionId,
    String? payloadJson,
    String? appScope,
    String? externalUserId,
    DateTime? createdAt,
    DateTime? nextAttemptAt,
    int? attemptCount,
    QueueStatus? status,
    String? lastErrorCode,
    String? lastErrorMessage,
  }) {
    return QueuedFeedback(
      clientSubmissionId: clientSubmissionId ?? this.clientSubmissionId,
      payloadJson: payloadJson ?? this.payloadJson,
      appScope: appScope ?? this.appScope,
      externalUserId: externalUserId ?? this.externalUserId,
      createdAt: createdAt ?? this.createdAt,
      nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
      attemptCount: attemptCount ?? this.attemptCount,
      status: status ?? this.status,
      lastErrorCode: lastErrorCode ?? this.lastErrorCode,
      lastErrorMessage: lastErrorMessage ?? this.lastErrorMessage,
    );
  }

  @override
  List<Object?> get props => [
        clientSubmissionId,
        payloadJson,
        appScope,
        externalUserId,
        createdAt,
        nextAttemptAt,
        attemptCount,
        status,
        lastErrorCode,
        lastErrorMessage,
      ];
}
