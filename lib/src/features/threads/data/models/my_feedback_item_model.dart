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
  });

  factory MyFeedbackItemModel.fromJson(Map<String, dynamic> json) {
    return MyFeedbackItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      category: json['category'] as String?,
      status: json['status'] as String,
      hasUnread: (json['has_unread'] as bool?) ?? false,
      lastActivityAt: json['last_activity_at'] != null
          ? DateTime.parse(json['last_activity_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
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
    );
  }
}
