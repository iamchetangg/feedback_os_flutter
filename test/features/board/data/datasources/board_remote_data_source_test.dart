import 'package:dio/dio.dart';
import 'package:feedback_os_flutter/src/core/network/api_endpoints.dart';
import 'package:feedback_os_flutter/src/core/network/feedback_os_dio_client.dart';
import 'package:feedback_os_flutter/src/features/board/data/datasources/board_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFeedbackOsHttpClient extends Mock implements FeedbackOsHttpClient {}

void main() {
  group('BoardRemoteDataSourceImpl', () {
    late MockFeedbackOsHttpClient mockClient;
    late BoardRemoteDataSourceImpl dataSource;

    setUp(() {
      mockClient = MockFeedbackOsHttpClient();
      dataSource = BoardRemoteDataSourceImpl(client: mockClient);
    });

    test('getBoard fetches board with default and custom query params',
        () async {
      when(
        () => mockClient.get<Map<String, dynamic>>(
          ApiEndpoints.board,
          queryParameters: {
            'sort': 'new',
            'limit': 10,
            'cursor': 'c_123',
          },
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.board),
          statusCode: 200,
          data: {
            'data': [
              {
                'id': 'item_1',
                'title': 'New Feature',
                'status': 'open',
                'vote_count': 3,
                'has_voted': false,
                'is_mine': false,
              }
            ],
            'next_cursor': 'c_456',
          },
        ),
      );

      final result = await dataSource.getBoard(
        sort: 'new',
        limit: 10,
        cursor: 'c_123',
      );

      expect(result.items.length, 1);
      expect(result.items.first.title, 'New Feature');
      expect(result.nextCursor, 'c_456');
    });

    test('getRoadmap fetches planned, in_progress, shipped sections', () async {
      when(
        () => mockClient.get<Map<String, dynamic>>(
          ApiEndpoints.roadmap,
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.roadmap),
          statusCode: 200,
          data: {
            'planned': [
              {
                'id': 'p_1',
                'title': 'Planned Item',
                'status': 'planned',
                'vote_count': 12,
                'has_voted': true,
                'is_mine': false,
              }
            ],
            'in_progress': [],
            'shipped': [],
          },
        ),
      );

      final result = await dataSource.getRoadmap();

      expect(result.planned.length, 1);
      expect(result.inProgress, isEmpty);
      expect(result.shipped, isEmpty);
    });

    test('voteItem calls POST on itemVote endpoint', () async {
      when(
        () => mockClient.post<Map<String, dynamic>>(
          ApiEndpoints.itemVote('item_abc'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions:
              RequestOptions(path: ApiEndpoints.itemVote('item_abc')),
          statusCode: 200,
          data: {
            'vote_count': 10,
            'has_voted': true,
          },
        ),
      );

      final result = await dataSource.voteItem(itemId: 'item_abc');

      expect(result.voteCount, 10);
      expect(result.hasVoted, isTrue);
    });

    test('unvoteItem calls DELETE on itemVote endpoint', () async {
      when(
        () => mockClient.delete<Map<String, dynamic>>(
          ApiEndpoints.itemVote('item_abc'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions:
              RequestOptions(path: ApiEndpoints.itemVote('item_abc')),
          statusCode: 200,
          data: {
            'vote_count': 9,
            'has_voted': false,
          },
        ),
      );

      final result = await dataSource.unvoteItem(itemId: 'item_abc');

      expect(result.voteCount, 9);
      expect(result.hasVoted, isFalse);
    });
  });
}
