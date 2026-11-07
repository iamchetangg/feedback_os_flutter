import "../../domain/entities/thread_reply.dart";

class ThreadReplyModel extends ThreadReply {
  const ThreadReplyModel({
    required super.id,
    required super.body,
    required super.authorType,
    super.authorName,
    required super.createdAt,
  });

  factory ThreadReplyModel.fromJson(Map<String, dynamic> json) {
    final authorRaw = (json["author_type"] as String?) ??
        (json["author"] as String?) ??
        "user";
    final authorType = (authorRaw == "developer" || authorRaw == "admin")
        ? "admin"
        : "user";

    return ThreadReplyModel(
      id: (json["id"] as String?) ?? "",
      body: (json["body"] as String?) ?? "",
      authorType: authorType,
      authorName: json["author_name"] as String?,
      createdAt: json["created_at"] != null
          ? DateTime.tryParse(json["created_at"].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "id": id,
      "body": body,
      "author_type": authorType,
      if (authorName != null) "author_name": authorName,
      "created_at": createdAt.toIso8601String(),
    };
  }

  factory ThreadReplyModel.fromEntity(ThreadReply entity) {
    return ThreadReplyModel(
      id: entity.id,
      body: entity.body,
      authorType: entity.authorType,
      authorName: entity.authorName,
      createdAt: entity.createdAt,
    );
  }
}
