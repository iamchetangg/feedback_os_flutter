import '../../domain/entities/thread_detail.dart';
import 'thread_event_model.dart';
import 'thread_reply_model.dart';

class ThreadDetailModel extends ThreadDetail {
  const ThreadDetailModel({
    required super.id,
    required super.title,
    required super.description,
    required super.type,
    super.category,
    required super.status,
    required super.createdAt,
    super.replies = const [],
    super.events = const [],
  });

  factory ThreadDetailModel.fromJson(Map<String, dynamic> json) {
    final rawReplies = json['replies'] as List<dynamic>? ?? const [];
    final replies = rawReplies
        .map((r) => ThreadReplyModel.fromJson(r as Map<String, dynamic>))
        .toList();

    final rawEvents = json['events'] as List<dynamic>? ?? const [];
    final events = rawEvents
        .map((e) => ThreadEventModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return ThreadDetailModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      type: (json['type'] as String?) ?? 'bug',
      category: json['category'] as String?,
      status: (json['status'] as String?) ?? 'open',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      replies: replies,
      events: events,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'type': type,
      if (category != null) 'category': category,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'replies':
          replies.map((r) => ThreadReplyModel.fromEntity(r).toJson()).toList(),
      'events':
          events.map((e) => ThreadEventModel.fromEntity(e).toJson()).toList(),
    };
  }

  factory ThreadDetailModel.fromEntity(ThreadDetail entity) {
    return ThreadDetailModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      type: entity.type,
      category: entity.category,
      status: entity.status,
      createdAt: entity.createdAt,
      replies: entity.replies,
      events: entity.events,
    );
  }
}
