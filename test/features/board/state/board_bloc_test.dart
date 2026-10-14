import 'package:feedback_os_flutter/src/features/board/domain/entities/board_item.dart';
import 'package:feedback_os_flutter/src/features/board/domain/entities/board_page.dart';
import 'package:feedback_os_flutter/src/features/board/domain/usecases/get_board_use_case.dart';
import 'package:feedback_os_flutter/src/features/board/domain/usecases/get_roadmap_use_case.dart';
import 'package:feedback_os_flutter/src/features/board/domain/usecases/unvote_item_use_case.dart';
import 'package:feedback_os_flutter/src/features/board/domain/usecases/vote_item_use_case.dart';
import 'package:feedback_os_flutter/src/features/board/state/board_bloc.dart';
import 'package:feedback_os_flutter/src/features/board/state/board_event.dart';
import 'package:feedback_os_flutter/src/features/board/state/board_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetBoardUseCase extends Mock implements GetBoardUseCase {}

class MockGetRoadmapUseCase extends Mock implements GetRoadmapUseCase {}

class MockVoteItemUseCase extends Mock implements VoteItemUseCase {}

class MockUnvoteItemUseCase extends Mock implements UnvoteItemUseCase {}

void main() {
  group('BoardBloc', () {
    late MockGetBoardUseCase mockGetBoard;
    late MockGetRoadmapUseCase mockGetRoadmap;
    late MockVoteItemUseCase mockVote;
    late MockUnvoteItemUseCase mockUnvote;
    late BoardBloc bloc;

    final testItem = BoardItem(
      id: 'item_1',
      title: 'Item 1',
      description: 'Desc 1',
      status: 'planned',
      voteCount: 10,
      hasVoted: false,
      isMine: false,
      createdAt: DateTime.now(),
    );

    setUp(() {
      mockGetBoard = MockGetBoardUseCase();
      mockGetRoadmap = MockGetRoadmapUseCase();
      mockVote = MockVoteItemUseCase();
      mockUnvote = MockUnvoteItemUseCase();

      bloc = BoardBloc(
        getBoardUseCase: mockGetBoard,
        getRoadmapUseCase: mockGetRoadmap,
        voteItemUseCase: mockVote,
        unvoteItemUseCase: mockUnvote,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('BoardStarted loads items and emits success', () async {
      when(() => mockGetBoard.call(
            sort: any(named: 'sort'),
            cursor: any(named: 'cursor'),
            limit: any(named: 'limit'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Right(BoardPage(items: [testItem])));

      bloc.add(const BoardStarted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const BoardState(status: BoardStatus.loading, sort: 'top'),
          BoardState(
            status: BoardStatus.success,
            items: [testItem],
            sort: 'top',
            hasMore: false,
          ),
        ]),
      );
    });
  });
}
