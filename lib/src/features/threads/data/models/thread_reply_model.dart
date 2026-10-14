import '../../domain/entities/thread_reply.dart';

class ThreadReplyModel extends ThreadReply {
  const ThreadReplyModel({
    required super.id,
    required super.body,
    required super.authorType,
    required super.createdAt,
  });

  factory ThreadReplyModel.fromJson(Map<String, dynamic> json) {
    return ThreadReplyModel(
      id: json['id'] as String,
      body: json['body'] as String,
      authorType: (json['author_type'] as String?) ?? 'user',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'body': body,
      'author_type': authorType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ThreadReplyModel.fromEntity(ThreadReply entity) {
    return ThreadReplyModel(
      id: entity.id,
      body: entity.body,
      authorType: entity.authorType,
      createdAt: entity.createdAt,
    );
  }
}
