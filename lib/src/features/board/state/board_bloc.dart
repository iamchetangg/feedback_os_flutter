import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/entities/board_item.dart';
import '../domain/usecases/get_board_use_case.dart';
import '../domain/usecases/get_roadmap_use_case.dart';
import '../domain/usecases/unvote_item_use_case.dart';
import '../domain/usecases/vote_item_use_case.dart';
import 'board_event.dart';
import 'board_state.dart';

class BoardBloc extends Bloc<BoardEvent, BoardState> {
  final GetBoardUseCase _getBoardUseCase;
  final GetRoadmapUseCase _getRoadmapUseCase;
  final VoteItemUseCase _voteItemUseCase;
  final UnvoteItemUseCase _unvoteItemUseCase;

  BoardBloc({
    required GetBoardUseCase getBoardUseCase,
    required GetRoadmapUseCase getRoadmapUseCase,
    required VoteItemUseCase voteItemUseCase,
    required UnvoteItemUseCase unvoteItemUseCase,
    BoardState? initialState,
  })  : _getBoardUseCase = getBoardUseCase,
        _getRoadmapUseCase = getRoadmapUseCase,
        _voteItemUseCase = voteItemUseCase,
        _unvoteItemUseCase = unvoteItemUseCase,
        super(initialState ?? const BoardState()) {
    on<BoardStarted>(_onBoardStarted);
    on<BoardSortChanged>(_onBoardSortChanged);
    on<BoardNextPageRequested>(_onBoardNextPageRequested);
    on<BoardItemVoteToggled>(_onBoardItemVoteToggled);
    on<RoadmapStarted>(_onRoadmapStarted);
  }

  Future<void> _onBoardStarted(
    BoardStarted event,
    Emitter<BoardState> emit,
  ) async {
    emit(state.copyWith(
      status: BoardStatus.loading,
      sort: event.sort,
      errorMessage: null,
    ));

    final result = await _getBoardUseCase(sort: event.sort);
    result.fold(
      (failure) => emit(state.copyWith(
        status: BoardStatus.failure,
        errorMessage: failure.message,
      )),
      (page) => emit(state.copyWith(
        status: BoardStatus.success,
        items: page.items,
        nextCursor: page.nextCursor,
        hasMore: page.nextCursor != null,
      )),
    );
  }

  Future<void> _onBoardSortChanged(
    BoardSortChanged event,
    Emitter<BoardState> emit,
  ) async {
    if (state.sort == event.sort && state.status == BoardStatus.success) return;
    add(BoardStarted(sort: event.sort));
  }

  Future<void> _onBoardNextPageRequested(
    BoardNextPageRequested event,
    Emitter<BoardState> emit,
  ) async {
    if (state.nextCursor == null || state.status == BoardStatus.loading) return;

    final result = await _getBoardUseCase(
      sort: state.sort,
      cursor: state.nextCursor,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        errorMessage: failure.message,
      )),
      (page) => emit(state.copyWith(
        items: [...state.items, ...page.items],
        nextCursor: page.nextCursor,
        hasMore: page.nextCursor != null,
      )),
    );
  }

  Future<void> _onBoardItemVoteToggled(
    BoardItemVoteToggled event,
    Emitter<BoardState> emit,
  ) async {
    final index = state.items.indexWhere((item) => item.id == event.itemId);
    if (index == -1) return;

    final currentItem = state.items[index];
    final wasVoted = currentItem.hasVoted;
    final newVoteCount = wasVoted
        ? (currentItem.voteCount - 1).clamp(0, 999999)
        : currentItem.voteCount + 1;

    // 1. Optimistic update
    final updatedItem = currentItem.copyWith(
      hasVoted: !wasVoted,
      voteCount: newVoteCount,
    );
    final updatedList = List<BoardItem>.from(state.items);
    updatedList[index] = updatedItem;
    emit(state.copyWith(items: updatedList));

    // 2. Perform API call
    final result = wasVoted
        ? await _unvoteItemUseCase(itemId: event.itemId)
        : await _voteItemUseCase(itemId: event.itemId);

    result.fold(
      (failure) {
        // Rollback on failure
        final rollbackList = List<BoardItem>.from(state.items);
        final rollbackIndex =
            rollbackList.indexWhere((item) => item.id == event.itemId);
        if (rollbackIndex != -1) {
          rollbackList[rollbackIndex] = currentItem;
          emit(state.copyWith(
            items: rollbackList,
            errorMessage: 'Failed to update vote: ${failure.message}',
          ));
        }
      },
      (voteResult) {
        // Confirm server vote state
        final confirmedList = List<BoardItem>.from(state.items);
        final confirmIndex =
            confirmedList.indexWhere((item) => item.id == event.itemId);
        if (confirmIndex != -1) {
          confirmedList[confirmIndex] = currentItem.copyWith(
            hasVoted: voteResult.hasVoted,
            voteCount: voteResult.voteCount,
          );
          emit(state.copyWith(items: confirmedList));
        }
      },
    );
  }

  Future<void> _onRoadmapStarted(
    RoadmapStarted event,
    Emitter<BoardState> emit,
  ) async {
    emit(state.copyWith(
      status: BoardStatus.loading,
      errorMessage: null,
    ));

    final result = await _getRoadmapUseCase();
    result.fold(
      (failure) => emit(state.copyWith(
        status: BoardStatus.failure,
        errorMessage: failure.message,
      )),
      (roadmap) => emit(state.copyWith(
        status: BoardStatus.success,
        roadmap: roadmap,
      )),
    );
  }
}
