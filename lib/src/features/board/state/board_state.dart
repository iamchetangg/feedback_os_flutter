import 'package:equatable/equatable.dart';
import '../domain/entities/board_item.dart';
import '../domain/entities/roadmap.dart';

enum BoardStatus { initial, loading, success, failure }

class BoardState extends Equatable {
  final BoardStatus status;
  final List<BoardItem> items;
  final String? nextCursor;
  final bool hasMore;
  final String sort;
  final Roadmap? roadmap;
  final String? errorMessage;

  const BoardState({
    this.status = BoardStatus.initial,
    this.items = const [],
    this.nextCursor,
    this.hasMore = false,
    this.sort = 'top',
    this.roadmap,
    this.errorMessage,
  });

  BoardState copyWith({
    BoardStatus? status,
    List<BoardItem>? items,
    String? nextCursor,
    bool? hasMore,
    String? sort,
    Roadmap? roadmap,
    String? errorMessage,
  }) {
    return BoardState(
      status: status ?? this.status,
      items: items ?? this.items,
      nextCursor: nextCursor ?? this.nextCursor,
      hasMore: hasMore ?? this.hasMore,
      sort: sort ?? this.sort,
      roadmap: roadmap ?? this.roadmap,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        nextCursor,
        hasMore,
        sort,
        roadmap,
        errorMessage,
      ];
}
