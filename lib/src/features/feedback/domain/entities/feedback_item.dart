import 'package:equatable/equatable.dart';
import 'feedback_type.dart';

/// Server-acknowledged feedback item.
class FeedbackItem extends Equatable {
  final String id;
  final FeedbackType type;
  final String title;
  final String description;
  final String? category;
  final String status;
  final bool isPublic;
  final DateTime createdAt;

  const FeedbackItem({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    this.category,
    required this.status,
    required this.isPublic,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        type,
        title,
        description,
        category,
        status,
        isPublic,
        createdAt,
      ];
}
