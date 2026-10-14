import 'package:equatable/equatable.dart';

/// Represents a public feature request or feedback item displayed on the community board or roadmap.
class BoardItem extends Equatable {
  final String id;
  final String title;
  final String description;
  final String? category;
  final String status;
  final int voteCount;
  final bool hasVoted;
  final bool isMine;
  final DateTime createdAt;

  const BoardItem({
    required this.id,
    required this.title,
    required this.description,
    this.category,
    required this.status,
    required this.voteCount,
    required this.hasVoted,
    required this.isMine,
    required this.createdAt,
  });

  BoardItem copyWith({
    String? id,
    String? title,
    String? description,
    String? category,
    String? status,
    int? voteCount,
    bool? hasVoted,
    bool? isMine,
    DateTime? createdAt,
  }) {
    return BoardItem(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      status: status ?? this.status,
      voteCount: voteCount ?? this.voteCount,
      hasVoted: hasVoted ?? this.hasVoted,
      isMine: isMine ?? this.isMine,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        status,
        voteCount,
        hasVoted,
        isMine,
        createdAt,
      ];
}
