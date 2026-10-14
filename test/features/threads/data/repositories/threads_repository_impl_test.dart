import 'package:feedback_os_flutter/src/core/errors/exceptions.dart';
import 'package:feedback_os_flutter/src/core/errors/failures.dart';
import 'package:feedback_os_flutter/src/features/threads/data/datasources/threads_remote_data_source.dart';
import 'package:feedback_os_flutter/src/features/threads/data/models/my_feedback_item_model.dart';
import 'package:feedback_os_flutter/src/features/threads/data/models/thread_detail_model.dart';
import 'package:feedback_os_flutter/src/features/threads/data/models/thread_reply_model.dart';
import 'package:feedback_os_flutter/src/features/threads/data/models/unread_count_model.dart';
import 'package:feedback_os_flutter/src/features/threads/data/repositories/threads_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockThreadsRemoteDataSource extends Mock
    implements ThreadsRemoteDataSource {}

void main() {
  group('ThreadsRepositoryImpl', () {
    late MockThreadsRemoteDataSource mockDataSource;
    late ThreadsRepositoryImpl repository;

    setUp(() {
      mockDataSource = MockThreadsRemoteDataSource();
      repository = ThreadsRepositoryImpl(remoteDataSource: mockDataSource);
    });

    test('getUnreadCount returns UnreadCount on success', () async {
      when(() => mockDataSource.getUnreadCount(
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => const UnreadCountModel(count: 3));

      final result = await repository.getUnreadCount();

      expect(result.isRight(), isTrue);
      result.match(
        (failure) => fail('Expected Right'),
        (unread) => expect(unread.count, 3),
      );
    });

    test('getUnreadCount returns Failure on exception', () async {
      when(() => mockDataSource.getUnreadCount(
            cancelToken: any(named: 'cancelToken'),
          )).thenThrow(
        const FeedbackOsAuthenticationException('Invalid key', statusCode: 401),
      );

      final result = await repository.getUnreadCount();

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, isA<AuthenticationFailure>()),
        (_) => fail('Expected Left'),
      );
    });

    test('getMyItems returns list on success', () async {
      final items = [
        MyFeedbackItemModel(
          id: 'item_1',
          title: 'Title',
          type: 'bug',
          status: 'open',
          hasUnread: false,
          createdAt: DateTime.now(),
        ),
      ];

      when(() => mockDataSource.getMyItems(
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => items);

      final result = await repository.getMyItems();

      expect(result.isRight(), isTrue);
      result.match(
        (failure) => fail('Expected Right'),
        (list) => expect(list.length, 1),
      );
    });

    test('getThreadDetail returns detail on success', () async {
      final detail = ThreadDetailModel(
        id: 'item_1',
        title: 'Title',
        description: 'Desc',
        type: 'bug',
        status: 'open',
        createdAt: DateTime.now(),
      );

      when(() => mockDataSource.getThreadDetail(
            itemId: 'item_1',
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => detail);

      final result = await repository.getThreadDetail(itemId: 'item_1');

      expect(result.isRight(), isTrue);
      result.match(
        (failure) => fail('Expected Right'),
        (d) => expect(d.id, 'item_1'),
      );
    });

    test('sendReply returns reply on success', () async {
      final reply = ThreadReplyModel(
        id: 'r_1',
        body: 'Message',
        authorType: 'user',
        createdAt: DateTime.now(),
      );

      when(() => mockDataSource.sendReply(
            itemId: 'item_1',
            message: 'Message',
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => reply);

      final result = await repository.sendReply(
        itemId: 'item_1',
        message: 'Message',
      );

      expect(result.isRight(), isTrue);
      result.match(
        (failure) => fail('Expected Right'),
        (r) => expect(r.id, 'r_1'),
      );
    });

    test('markThreadRead returns void Right on success', () async {
      when(() => mockDataSource.markThreadRead(
            itemId: 'item_1',
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async {});

      final result = await repository.markThreadRead(itemId: 'item_1');

      expect(result.isRight(), isTrue);
    });
  });
}
