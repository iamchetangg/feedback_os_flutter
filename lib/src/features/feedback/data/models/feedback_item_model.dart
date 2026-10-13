import '../../domain/entities/feedback_item.dart';
import '../../domain/entities/feedback_type.dart';

class FeedbackItemModel extends FeedbackItem {
  const FeedbackItemModel({
    required super.id,
    required super.type,
    required super.title,
    required super.description,
    super.category,
    required super.status,
    required super.isPublic,
    required super.createdAt,
  });

  factory FeedbackItemModel.fromJson(Map<String, dynamic> json) {
    return FeedbackItemModel(
      id: json['id'] as String,
      type: FeedbackType.fromString(json['type'] as String),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String?,
      status: json['status'] as String? ?? 'open',
      isPublic: json['is_public'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.value,
      'title': title,
      'description': description,
      'category': category,
      'status': status,
      'is_public': isPublic,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
