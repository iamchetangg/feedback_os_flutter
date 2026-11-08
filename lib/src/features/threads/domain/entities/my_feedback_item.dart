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

  /// Creates a copy of this item with specified properties replaced.
  MyFeedbackItem copyWith({
    String? id,
    String? title,
    String? type,
    String? category,
    String? status,
    bool? hasUnread,
    DateTime? lastActivityAt,
    DateTime? createdAt,
    String? description,
    String? latestReplyPreview,
    int? replyCount,
  }) {
    return MyFeedbackItem(
      id: id ?? this.id,
      title: title ?? this.title,
      type: type ?? this.type,
      category: category ?? this.category,
      status: status ?? this.status,
      hasUnread: hasUnread ?? this.hasUnread,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
      createdAt: createdAt ?? this.createdAt,
      description: description ?? this.description,
      latestReplyPreview: latestReplyPreview ?? this.latestReplyPreview,
      replyCount: replyCount ?? this.replyCount,
    );
  }

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
