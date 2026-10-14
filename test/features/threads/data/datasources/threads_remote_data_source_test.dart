import 'package:dio/dio.dart';
import 'package:feedback_os_flutter/src/core/network/api_endpoints.dart';
import 'package:feedback_os_flutter/src/core/network/feedback_os_dio_client.dart';
import 'package:feedback_os_flutter/src/features/threads/data/datasources/threads_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFeedbackOsHttpClient extends Mock implements FeedbackOsHttpClient {}

void main() {
  group('ThreadsRemoteDataSourceImpl', () {
    late MockFeedbackOsHttpClient mockClient;
    late ThreadsRemoteDataSourceImpl dataSource;

    setUp(() {
      mockClient = MockFeedbackOsHttpClient();
      dataSource = ThreadsRemoteDataSourceImpl(client: mockClient);
    });

    test('getUnreadCount calls GET /v1/sdk/me/unread', () async {
      when(
        () => mockClient.get<Map<String, dynamic>>(
          ApiEndpoints.meUnread,
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.meUnread),
          statusCode: 200,
          data: {'count': 5},
        ),
      );

      final result = await dataSource.getUnreadCount();

      expect(result.count, 5);
      verify(
        () => mockClient.get<Map<String, dynamic>>(
          ApiEndpoints.meUnread,
          cancelToken: null,
        ),
      ).called(1);
    });

    test('getMyItems calls GET /v1/sdk/me/items', () async {
      when(
        () => mockClient.get<Map<String, dynamic>>(
          ApiEndpoints.meItems,
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.meItems),
          statusCode: 200,
          data: {
            'data': [
              {
                'id': 'my_1',
                'title': 'Test Item',
                'type': 'feature',
                'status': 'open',
                'has_unread': false,
              }
            ]
          },
        ),
      );

      final result = await dataSource.getMyItems();

      expect(result.length, 1);
      expect(result.first.id, 'my_1');
      expect(result.first.type, 'feature');
    });

    test('getThreadDetail calls GET /v1/sdk/me/items/{itemId}', () async {
      when(
        () => mockClient.get<Map<String, dynamic>>(
          ApiEndpoints.meItemDetail('item_99'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions:
              RequestOptions(path: ApiEndpoints.meItemDetail('item_99')),
          statusCode: 200,
          data: {
            'id': 'item_99',
            'title': 'Detailed Item',
            'description': 'More context',
            'type': 'bug',
            'status': 'in_progress',
            'replies': [],
            'events': [],
          },
        ),
      );

      final result = await dataSource.getThreadDetail(itemId: 'item_99');

      expect(result.id, 'item_99');
      expect(result.title, 'Detailed Item');
      expect(result.description, 'More context');
    });

    test('sendReply calls POST /v1/sdk/me/items/{itemId}/replies with body',
        () async {
      when(
        () => mockClient.post<Map<String, dynamic>>(
          ApiEndpoints.meItemReplies('item_99'),
          data: {'body': 'Hello support'},
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions:
              RequestOptions(path: ApiEndpoints.meItemReplies('item_99')),
          statusCode: 201,
          data: {
            'id': 'rep_1',
            'body': 'Hello support',
            'author_type': 'user',
          },
        ),
      );

      final result = await dataSource.sendReply(
        itemId: 'item_99',
        message: 'Hello support',
      );

      expect(result.id, 'rep_1');
      expect(result.body, 'Hello support');
      expect(result.isUser, isTrue);
    });

    test('markThreadRead calls POST /v1/sdk/me/items/{itemId}/read', () async {
      when(
        () => mockClient.post<dynamic>(
          ApiEndpoints.meItemRead('item_99'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions:
              RequestOptions(path: ApiEndpoints.meItemRead('item_99')),
          statusCode: 204,
        ),
      );

      await dataSource.markThreadRead(itemId: 'item_99');

      verify(
        () => mockClient.post<dynamic>(
          ApiEndpoints.meItemRead('item_99'),
          cancelToken: null,
        ),
      ).called(1);
    });
  });
}
