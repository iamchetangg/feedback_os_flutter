import 'package:equatable/equatable.dart';
import 'feedback_item.dart';

/// Indicates the resolution status of a feedback submission.
enum FeedbackSubmitStatus {
  /// Confirmed and acknowledged by the server (HTTP 201 or 200).
  sent,

  /// Successfully committed to the local durable offline queue.
  queued,
}

/// The result returned when submitting feedback through the SDK.
class FeedbackSubmitResult extends Equatable {
  final FeedbackSubmitStatus status;
  final String? itemId;
  final String clientSubmissionId;
  final FeedbackItem? item;

  const FeedbackSubmitResult({
    required this.status,
    this.itemId,
    required this.clientSubmissionId,
    this.item,
  });

  bool get isSent => status == FeedbackSubmitStatus.sent;
  bool get isQueued => status == FeedbackSubmitStatus.queued;

  @override
  List<Object?> get props => [status, itemId, clientSubmissionId, item];
}
