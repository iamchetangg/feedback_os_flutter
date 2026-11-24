import 'package:equatable/equatable.dart';

/// A live event pushed by the FeedbackOS server over the realtime channel.
///
/// Subscribe via `FeedbackOS.instance.events`. Server event types the SDK
/// does not know about are ignored, so they never reach this stream.
sealed class FeedbackOSEvent extends Equatable {
  /// The feedback item (thread) this event belongs to.
  final String itemId;

  /// When the event happened on the server (UTC).
  final DateTime createdAt;

  const FeedbackOSEvent({required this.itemId, required this.createdAt});
}

/// A creator/team member replied on one of the user's feedback threads.
final class ReplyReceived extends FeedbackOSEvent {
  final String replyId;

  /// Display name of the reply author, if the server provided one.
  final String? authorName;

  /// The first (at most 140) characters of the reply.
  final String preview;

  const ReplyReceived({
    required super.itemId,
    required this.replyId,
    required this.authorName,
    required this.preview,
    required super.createdAt,
  });

  @override
  List<Object?> get props => [itemId, replyId, authorName, preview, createdAt];
}

/// The status of one of the user's feedback items changed.
final class StatusChanged extends FeedbackOSEvent {
  final String? fromStatus;
  final String toStatus;

  const StatusChanged({
    required super.itemId,
    required this.fromStatus,
    required this.toStatus,
    required super.createdAt,
  });

  @override
  List<Object?> get props => [itemId, fromStatus, toStatus, createdAt];
}
