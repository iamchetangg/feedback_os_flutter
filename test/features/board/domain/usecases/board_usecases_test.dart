import 'package:feedback_os_flutter/src/features/board/domain/entities/board_item.dart';
import 'package:feedback_os_flutter/src/features/board/domain/entities/board_page.dart';
import 'package:feedback_os_flutter/src/features/board/domain/entities/roadmap.dart';
import 'package:feedback_os_flutter/src/features/board/domain/entities/vote_result.dart';
import 'package:feedback_os_flutter/src/features/board/domain/repositories/board_repository.dart';
import 'package:feedback_os_flutter/src/features/board/domain/usecases/get_board_use_case.dart';
import 'package:feedback_os_flutter/src/features/board/domain/usecases/get_roadmap_use_case.dart';
import 'package:feedback_os_flutter/src/features/board/domain/usecases/unvote_item_use_case.dart';
import 'package:feedback_os_flutter/src/features/board/domain/usecases/vote_item_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockBoardRepository extends Mock implements BoardRepository {}

void main() {
  group('Board UseCases', () {
    late MockBoardRepository repository;

    setUp(() {
      repository = MockBoardRepository();
    });

    final testItem = BoardItem(
      id: 'item_1',
      title: 'Item 1',
      description: 'Desc 1',
      status: 'planned',
      voteCount: 5,
      hasVoted: false,
      isMine: true,
      createdAt: DateTime.parse('2026-10-14T00:00:00.000Z'),
    );

    test('GetBoardUseCase delegates call to repository', () async {
      final useCase = GetBoardUseCase(repository);
      final page = BoardPage(items: [testItem], nextCursor: null);

      when(
        () => repository.getBoard(
          sort: 'top',
          cursor: any(named: 'cursor'),
          limit: 25,
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => Right(page));

      final result = await useCase(sort: 'top');

      expect(result, Right(page));
      verify(
        () => repository.getBoard(
          sort: 'top',
          cursor: null,
          limit: 25,
          cancelToken: null,
        ),
      ).called(1);
    });

    test('GetRoadmapUseCase delegates call to repository', () async {
      final useCase = GetRoadmapUseCase(repository);
      final roadmap = Roadmap(
        planned: [testItem],
        inProgress: const [],
        shipped: const [],
      );

      when(
        () => repository.getRoadmap(cancelToken: any(named: 'cancelToken')),
      ).thenAnswer((_) async => Right(roadmap));

      final result = await useCase();

      expect(result, Right(roadmap));
      verify(() => repository.getRoadmap(cancelToken: null)).called(1);
    });

    test('VoteItemUseCase delegates call to repository', () async {
      final useCase = VoteItemUseCase(repository);
      const voteResult = VoteResult(voteCount: 6, hasVoted: true);

      when(
        () => repository.voteItem(
          itemId: 'item_1',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => const Right(voteResult));

      final result = await useCase(itemId: 'item_1');

      expect(result, const Right(voteResult));
      verify(() => repository.voteItem(itemId: 'item_1', cancelToken: null))
          .called(1);
    });

    test('UnvoteItemUseCase delegates call to repository', () async {
      final useCase = UnvoteItemUseCase(repository);
      const voteResult = VoteResult(voteCount: 5, hasVoted: false);

      when(
        () => repository.unvoteItem(
          itemId: 'item_1',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => const Right(voteResult));

      final result = await useCase(itemId: 'item_1');

      expect(result, const Right(voteResult));
      verify(() => repository.unvoteItem(itemId: 'item_1', cancelToken: null))
          .called(1);
    });
  });
}
