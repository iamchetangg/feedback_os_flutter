import '../../domain/entities/my_feedback_item.dart';

class MyFeedbackItemModel extends MyFeedbackItem {
  const MyFeedbackItemModel({
    required super.id,
    required super.title,
    required super.type,
    super.category,
    required super.status,
    required super.hasUnread,
    super.lastActivityAt,
    required super.createdAt,
    super.description,
    super.latestReplyPreview,
    super.replyCount = 0,
  });

  factory MyFeedbackItemModel.fromJson(Map<String, dynamic> json) {
    return MyFeedbackItemModel(
      id: (json['id'] as String?) ?? '',
      title: (json['title'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'bug',
      category: json['category'] as String?,
      status: (json['status'] as String?) ?? 'open',
      hasUnread: (json['has_unread'] as bool?) ?? false,
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.tryParse(json['last_activity_at'].toString())
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      description: json['description'] as String?,
      latestReplyPreview: (json['latest_reply'] as String?) ??
          (json['latest_reply_preview'] as String?),
      replyCount: (json['reply_count'] as num?)?.toInt() ??
          (json['replies_count'] as num?)?.toInt() ??
          0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'type': type,
      if (category != null) 'category': category,
      'status': status,
      'has_unread': hasUnread,
      if (lastActivityAt != null)
        'last_activity_at': lastActivityAt!.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      if (description != null) 'description': description,
      if (latestReplyPreview != null) 'latest_reply': latestReplyPreview,
      'reply_count': replyCount,
    };
  }

  factory MyFeedbackItemModel.fromEntity(MyFeedbackItem entity) {
    return MyFeedbackItemModel(
      id: entity.id,
      title: entity.title,
      type: entity.type,
      category: entity.category,
      status: entity.status,
      hasUnread: entity.hasUnread,
      lastActivityAt: entity.lastActivityAt,
      createdAt: entity.createdAt,
      description: entity.description,
      latestReplyPreview: entity.latestReplyPreview,
      replyCount: entity.replyCount,
    );
  }
}
