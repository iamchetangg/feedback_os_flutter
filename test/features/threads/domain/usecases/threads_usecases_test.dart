import 'package:feedback_os_flutter/src/core/errors/failures.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/entities/my_feedback_item.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/entities/thread_detail.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/entities/thread_reply.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/entities/unread_count.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/repositories/threads_repository.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/usecases/get_my_items_use_case.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/usecases/get_thread_detail_use_case.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/usecases/get_unread_count_use_case.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/usecases/mark_thread_read_use_case.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/usecases/send_reply_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockThreadsRepository extends Mock implements ThreadsRepository {}

void main() {
  group('Threads UseCases', () {
    late MockThreadsRepository repository;

    setUp(() {
      repository = MockThreadsRepository();
    });

    test('GetUnreadCountUseCase delegates to repository', () async {
      final useCase = GetUnreadCountUseCase(repository);
      when(() => repository.getUnreadCount(
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => const Right(UnreadCount(count: 2)));

      final result = await useCase();

      expect(result, const Right(UnreadCount(count: 2)));
      verify(() => repository.getUnreadCount(cancelToken: null)).called(1);
    });

    test('GetMyItemsUseCase delegates to repository', () async {
      final useCase = GetMyItemsUseCase(repository);
      final items = [
        MyFeedbackItem(
          id: '1',
          title: 'Bug',
          type: 'bug',
          status: 'open',
          hasUnread: false,
          createdAt: DateTime.now(),
        )
      ];

      when(() => repository.getMyItems(
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Right(items));

      final result = await useCase();

      expect(result, Right(items));
      verify(() => repository.getMyItems(cancelToken: null)).called(1);
    });

    test('GetThreadDetailUseCase delegates to repository', () async {
      final useCase = GetThreadDetailUseCase(repository);
      final detail = ThreadDetail(
        id: '1',
        title: 'Title',
        description: 'Desc',
        type: 'bug',
        status: 'open',
        createdAt: DateTime.now(),
      );

      when(() => repository.getThreadDetail(
            itemId: '1',
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Right(detail));

      final result = await useCase(itemId: '1');

      expect(result, Right(detail));
      verify(() => repository.getThreadDetail(itemId: '1', cancelToken: null))
          .called(1);
    });

    test('SendReplyUseCase validates empty message locally before API call',
        () async {
      final useCase = SendReplyUseCase(repository);

      final result = await useCase(itemId: '1', message: '   ');

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Expected Left'),
      );
      verifyNever(() => repository.sendReply(
            itemId: any(named: 'itemId'),
            message: any(named: 'message'),
          ));
    });

    test('SendReplyUseCase delegates non-empty trimmed message to repository',
        () async {
      final useCase = SendReplyUseCase(repository);
      final reply = ThreadReply(
        id: 'r_1',
        body: 'Valid message',
        authorType: 'user',
        createdAt: DateTime.now(),
      );

      when(() => repository.sendReply(
            itemId: '1',
            message: 'Valid message',
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Right(reply));

      final result = await useCase(itemId: '1', message: '  Valid message  ');

      expect(result, Right(reply));
      verify(() => repository.sendReply(
            itemId: '1',
            message: 'Valid message',
            cancelToken: null,
          )).called(1);
    });

    test('MarkThreadReadUseCase delegates to repository', () async {
      final useCase = MarkThreadReadUseCase(repository);

      when(() => repository.markThreadRead(
            itemId: '1',
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => const Right(null));

      final result = await useCase(itemId: '1');

      expect(result, const Right(null));
      verify(() => repository.markThreadRead(itemId: '1', cancelToken: null))
          .called(1);
    });
  });
}
