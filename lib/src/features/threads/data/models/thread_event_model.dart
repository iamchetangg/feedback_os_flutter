import '../../domain/entities/thread_event.dart';

class ThreadEventModel extends ThreadEvent {
  const ThreadEventModel({
    required super.id,
    required super.type,
    super.oldStatus,
    super.newStatus,
    required super.createdAt,
  });

  factory ThreadEventModel.fromJson(Map<String, dynamic> json) {
    return ThreadEventModel(
      id: json['id'] as String,
      type: json['type'] as String,
      oldStatus: json['old_status'] as String?,
      newStatus: json['new_status'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      if (oldStatus != null) 'old_status': oldStatus,
      if (newStatus != null) 'new_status': newStatus,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory ThreadEventModel.fromEntity(ThreadEvent entity) {
    return ThreadEventModel(
      id: entity.id,
      type: entity.type,
      oldStatus: entity.oldStatus,
      newStatus: entity.newStatus,
      createdAt: entity.createdAt,
    );
  }
}
