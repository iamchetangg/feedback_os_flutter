import 'package:equatable/equatable.dart';

/// Represents a feedback item created by the current device/user.
class MyFeedbackItem extends Equatable {
  final String id;
  final String title;
  final String type;
  final String? category;
  final String status;
  final bool hasUnread;
  final DateTime? lastActivityAt;
  final DateTime createdAt;
  final String? description;
  final String? latestReplyPreview;
  final int replyCount;

  const MyFeedbackItem({
    required this.id,
    required this.title,
    required this.type,
    this.category,
    required this.status,
    required this.hasUnread,
    this.lastActivityAt,
    required this.createdAt,
    this.description,
    this.latestReplyPreview,
    this.replyCount = 0,
  });

  @override
  List<Object?> get props => [
        id,
        title,
        type,
        category,
        status,
        hasUnread,
        lastActivityAt,
        createdAt,
        description,
        latestReplyPreview,
        replyCount,
      ];
}
