import 'package:feedback_os_flutter/src/core/errors/exceptions.dart';
import 'package:feedback_os_flutter/src/core/errors/failures.dart';
import 'package:feedback_os_flutter/src/features/board/data/datasources/board_remote_data_source.dart';
import 'package:feedback_os_flutter/src/features/board/data/models/board_item_model.dart';
import 'package:feedback_os_flutter/src/features/board/data/models/board_page_model.dart';
import 'package:feedback_os_flutter/src/features/board/data/models/roadmap_model.dart';
import 'package:feedback_os_flutter/src/features/board/data/models/vote_result_model.dart';
import 'package:feedback_os_flutter/src/features/board/data/repositories/board_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockBoardRemoteDataSource extends Mock implements BoardRemoteDataSource {}

void main() {
  group('BoardRepositoryImpl', () {
    late MockBoardRemoteDataSource mockDataSource;
    late BoardRepositoryImpl repository;

    setUp(() {
      mockDataSource = MockBoardRemoteDataSource();
      repository = BoardRepositoryImpl(remoteDataSource: mockDataSource);
    });

    final testItem = BoardItemModel(
      id: 'item_1',
      title: 'Item 1',
      description: 'Desc 1',
      category: 'UI',
      status: 'planned',
      voteCount: 10,
      hasVoted: true,
      isMine: false,
      createdAt: DateTime.parse('2026-10-14T00:00:00.000Z'),
    );

    test('getBoard returns BoardPage on success', () async {
      final pageModel = BoardPageModel(
        items: [testItem],
        nextCursor: 'next_1',
      );

      when(
        () => mockDataSource.getBoard(
          sort: any(named: 'sort'),
          cursor: any(named: 'cursor'),
          limit: any(named: 'limit'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => pageModel);

      final result = await repository.getBoard();

      expect(result.isRight(), isTrue);
      result.match(
        (failure) => fail('Expected Right but got $failure'),
        (page) {
          expect(page.items.length, 1);
          expect(page.items.first.id, 'item_1');
          expect(page.nextCursor, 'next_1');
        },
      );
    });

    test('getBoard maps FeedbackOsException to Failure', () async {
      when(
        () => mockDataSource.getBoard(
          sort: any(named: 'sort'),
          cursor: any(named: 'cursor'),
          limit: any(named: 'limit'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(
        const FeedbackOsNetworkException('Offline', statusCode: 499),
      );

      final result = await repository.getBoard();

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) {
          expect(failure, isA<NetworkFailure>());
          expect(failure.statusCode, 499);
        },
        (_) => fail('Expected Left'),
      );
    });

    test('getRoadmap returns Roadmap on success', () async {
      final roadmapModel = RoadmapModel(
        planned: [testItem],
        inProgress: const [],
        shipped: const [],
      );

      when(
        () => mockDataSource.getRoadmap(
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => roadmapModel);

      final result = await repository.getRoadmap();

      expect(result.isRight(), isTrue);
      result.match(
        (failure) => fail('Expected Right'),
        (roadmap) {
          expect(roadmap.planned.length, 1);
          expect(roadmap.inProgress, isEmpty);
          expect(roadmap.shipped, isEmpty);
        },
      );
    });

    test('voteItem returns VoteResult on success', () async {
      const voteModel = VoteResultModel(voteCount: 11, hasVoted: true);

      when(
        () => mockDataSource.voteItem(
          itemId: 'item_1',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => voteModel);

      final result = await repository.voteItem(itemId: 'item_1');

      expect(result.isRight(), isTrue);
      result.match(
        (failure) => fail('Expected Right'),
        (vote) {
          expect(vote.voteCount, 11);
          expect(vote.hasVoted, isTrue);
        },
      );
    });

    test('unvoteItem returns VoteResult on success', () async {
      const voteModel = VoteResultModel(voteCount: 10, hasVoted: false);

      when(
        () => mockDataSource.unvoteItem(
          itemId: 'item_1',
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => voteModel);

      final result = await repository.unvoteItem(itemId: 'item_1');

      expect(result.isRight(), isTrue);
      result.match(
        (failure) => fail('Expected Right'),
        (vote) {
          expect(vote.voteCount, 10);
          expect(vote.hasVoted, isFalse);
        },
      );
    });
  });
}
