import 'package:equatable/equatable.dart';
import 'board_item.dart';

/// Represents grouped roadmap items by lifecycle status.
class Roadmap extends Equatable {
  final List<BoardItem> planned;
  final List<BoardItem> inProgress;
  final List<BoardItem> shipped;

  const Roadmap({
    required this.planned,
    required this.inProgress,
    required this.shipped,
  });

  @override
  List<Object?> get props => [planned, inProgress, shipped];
}
