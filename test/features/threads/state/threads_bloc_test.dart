import 'package:feedback_os_flutter/src/features/threads/domain/entities/my_feedback_item.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/entities/thread_detail.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/entities/unread_count.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/usecases/get_my_items_use_case.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/usecases/get_thread_detail_use_case.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/usecases/get_unread_count_use_case.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/usecases/mark_thread_read_use_case.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/usecases/send_reply_use_case.dart';
import 'package:feedback_os_flutter/src/features/threads/state/threads_bloc.dart';
import 'package:feedback_os_flutter/src/features/threads/state/threads_event.dart';
import 'package:feedback_os_flutter/src/features/threads/state/threads_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetMyItemsUseCase extends Mock implements GetMyItemsUseCase {}

class MockGetThreadDetailUseCase extends Mock
    implements GetThreadDetailUseCase {}

class MockGetUnreadCountUseCase extends Mock implements GetUnreadCountUseCase {}

class MockSendReplyUseCase extends Mock implements SendReplyUseCase {}

class MockMarkThreadReadUseCase extends Mock implements MarkThreadReadUseCase {}

void main() {
  group('ThreadsBloc', () {
    late MockGetMyItemsUseCase mockGetMyItems;
    late MockGetThreadDetailUseCase mockGetThreadDetail;
    late MockGetUnreadCountUseCase mockGetUnreadCount;
    late MockSendReplyUseCase mockSendReply;
    late MockMarkThreadReadUseCase mockMarkThreadRead;
    late ThreadsBloc bloc;

    final testItem = MyFeedbackItem(
      id: 'item_1',
      title: 'Crash on Android 14',
      type: 'bug',
      status: 'in_progress',
      hasUnread: false,
      createdAt: DateTime.parse('2026-10-14T00:00:00.000Z'),
    );

    setUp(() {
      mockGetMyItems = MockGetMyItemsUseCase();
      mockGetThreadDetail = MockGetThreadDetailUseCase();
      mockGetUnreadCount = MockGetUnreadCountUseCase();
      mockSendReply = MockSendReplyUseCase();
      mockMarkThreadRead = MockMarkThreadReadUseCase();

      bloc = ThreadsBloc(
        getMyItemsUseCase: mockGetMyItems,
        getThreadDetailUseCase: mockGetThreadDetail,
        getUnreadCountUseCase: mockGetUnreadCount,
        sendReplyUseCase: mockSendReply,
        markThreadReadUseCase: mockMarkThreadRead,
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('MyItemsStarted loads items and unread count', () async {
      when(() => mockGetMyItems.call(cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => Right([testItem]));
      when(() =>
              mockGetUnreadCount.call(cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => const Right(UnreadCount(count: 3)));

      bloc.add(const MyItemsStarted());

      await expectLater(
        bloc.stream,
        emitsInOrder([
          const ThreadsState(status: ThreadsStatus.loading),
          ThreadsState(
            status: ThreadsStatus.success,
            items: [testItem],
            unreadCount: 3,
          ),
        ]),
      );
    });

    test('ThreadDetailStarted optimistically clears unread and loads detail',
        () async {
      final unreadItem = testItem.copyWith(hasUnread: true);
      final detail = ThreadDetail(
        id: 'item_1',
        title: 'Crash on Android 14',
        description: 'Happens on back navigation',
        type: 'bug',
        status: 'in_progress',
        createdAt: DateTime.parse('2026-10-14T00:00:00.000Z'),
        replies: const [],
      );

      final initializedBloc = ThreadsBloc(
        getMyItemsUseCase: mockGetMyItems,
        getThreadDetailUseCase: mockGetThreadDetail,
        getUnreadCountUseCase: mockGetUnreadCount,
        sendReplyUseCase: mockSendReply,
        markThreadReadUseCase: mockMarkThreadRead,
        initialState: ThreadsState(
          status: ThreadsStatus.success,
          items: [unreadItem],
          unreadCount: 2,
        ),
      );

      when(() => mockGetThreadDetail.call(
            itemId: 'item_1',
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Right(detail));
      when(() => mockMarkThreadRead.call(
            itemId: 'item_1',
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => const Right(null));

      initializedBloc.add(const ThreadDetailStarted('item_1'));

      await expectLater(
        initializedBloc.stream,
        emitsInOrder([
          // Optimistic local update (hasUnread: false, unreadCount decremented)
          ThreadsState(
            status: ThreadsStatus.loading,
            items: [unreadItem.copyWith(hasUnread: false)],
            unreadCount: 1,
          ),
          // Success with detail loaded
          ThreadsState(
            status: ThreadsStatus.success,
            selectedThread: detail,
            items: [unreadItem.copyWith(hasUnread: false)],
            unreadCount: 1,
          ),
        ]),
      );

      verify(() => mockMarkThreadRead.call(itemId: 'item_1')).called(1);
      await initializedBloc.close();
    });

    test('ThreadDetailRefreshed(isSilent: true) updates selectedThread without loading status',
        () async {
      final initialDetail = ThreadDetail(
        id: 'item_1',
        title: 'Crash on Android 14',
        description: 'Happens on back navigation',
        type: 'bug',
        status: 'in_progress',
        createdAt: DateTime.parse('2026-10-14T00:00:00.000Z'),
        replies: const [],
      );

      final updatedDetail = initialDetail.copyWith(
        status: 'shipped',
      );

      final initializedBloc = ThreadsBloc(
        getMyItemsUseCase: mockGetMyItems,
        getThreadDetailUseCase: mockGetThreadDetail,
        getUnreadCountUseCase: mockGetUnreadCount,
        sendReplyUseCase: mockSendReply,
        markThreadReadUseCase: mockMarkThreadRead,
        initialState: ThreadsState(
          status: ThreadsStatus.success,
          selectedThread: initialDetail,
        ),
      );

      when(() => mockGetThreadDetail.call(
            itemId: 'item_1',
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Right(updatedDetail));

      initializedBloc.add(const ThreadDetailRefreshed('item_1', isSilent: true));

      await expectLater(
        initializedBloc.stream,
        emitsInOrder([
          ThreadsState(
            status: ThreadsStatus.success,
            selectedThread: updatedDetail,
          ),
        ]),
      );

      await initializedBloc.close();
    });
  });
}
