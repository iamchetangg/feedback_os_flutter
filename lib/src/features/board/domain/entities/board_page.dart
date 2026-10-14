import 'package:equatable/equatable.dart';
import 'board_item.dart';

/// Represents a paginated list of public board items with an optional next cursor.
class BoardPage extends Equatable {
  final List<BoardItem> items;
  final String? nextCursor;

  const BoardPage({
    required this.items,
    this.nextCursor,
  });

  @override
  List<Object?> get props => [items, nextCursor];
}
