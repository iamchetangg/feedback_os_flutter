import '../../domain/entities/board_item.dart';

class BoardItemModel extends BoardItem {
  const BoardItemModel({
    required super.id,
    required super.title,
    required super.description,
    super.category,
    required super.status,
    required super.voteCount,
    required super.hasVoted,
    required super.isMine,
    required super.createdAt,
  });

  factory BoardItemModel.fromJson(Map<String, dynamic> json) {
    return BoardItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      description: (json['description'] as String?) ?? '',
      category: json['category'] as String?,
      status: json['status'] as String,
      voteCount: (json['vote_count'] as num?)?.toInt() ?? 0,
      hasVoted: (json['has_voted'] as bool?) ?? false,
      isMine: (json['is_mine'] as bool?) ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      if (category != null) 'category': category,
      'status': status,
      'vote_count': voteCount,
      'has_voted': hasVoted,
      'is_mine': isMine,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory BoardItemModel.fromEntity(BoardItem entity) {
    return BoardItemModel(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      category: entity.category,
      status: entity.status,
      voteCount: entity.voteCount,
      hasVoted: entity.hasVoted,
      isMine: entity.isMine,
      createdAt: entity.createdAt,
    );
  }
}
