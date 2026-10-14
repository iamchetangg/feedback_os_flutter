import 'package:equatable/equatable.dart';

abstract class BoardEvent extends Equatable {
  const BoardEvent();

  @override
  List<Object?> get props => [];
}

class BoardStarted extends BoardEvent {
  final String sort;

  const BoardStarted({this.sort = 'top'});

  @override
  List<Object?> get props => [sort];
}

class BoardSortChanged extends BoardEvent {
  final String sort;

  const BoardSortChanged(this.sort);

  @override
  List<Object?> get props => [sort];
}

class BoardNextPageRequested extends BoardEvent {
  const BoardNextPageRequested();
}

class BoardItemVoteToggled extends BoardEvent {
  final String itemId;

  const BoardItemVoteToggled(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

class RoadmapStarted extends BoardEvent {
  const RoadmapStarted();
}
