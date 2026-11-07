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
    final source = (json['data'] is Map<String, dynamic>)
        ? json['data'] as Map<String, dynamic>
        : json;

    final rawReplies = source['replies'] as List<dynamic>? ?? const [];
    final replies = rawReplies
        .whereType<Map>()
        .map((r) =>
            ThreadReplyModel.fromJson(Map<String, dynamic>.from(r)))
        .toList();

    final rawEvents = source['events'] as List<dynamic>? ?? const [];
    final events = rawEvents
        .whereType<Map>()
        .map((e) =>
            ThreadEventModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return ThreadDetailModel(
      id: (source['id'] as String?) ?? '',
      title: (source['title'] as String?) ?? '',
      description: (source['description'] as String?) ?? '',
      type: (source['type'] as String?) ?? 'bug',
      category: source['category'] as String?,
      status: (source['status'] as String?) ?? 'open',
      createdAt: source['created_at'] != null
          ? DateTime.tryParse(source['created_at'].toString()) ?? DateTime.now()
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
