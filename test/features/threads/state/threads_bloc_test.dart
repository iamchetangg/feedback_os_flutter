import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:feedback_os_flutter/src/features/realtime/domain/entities/feedback_os_event.dart';
import 'package:feedback_os_flutter/src/features/realtime/domain/realtime_link.dart';
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
import 'package:flutter/foundation.dart';
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

    test(
        'ThreadDetailRefreshed(isSilent: true) updates selectedThread without loading status',
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

      initializedBloc
          .add(const ThreadDetailRefreshed('item_1', isSilent: true));

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

  group('ThreadsBloc realtime', () {
    late MockGetMyItemsUseCase mockGetMyItems;
    late MockGetThreadDetailUseCase mockGetThreadDetail;
    late MockGetUnreadCountUseCase mockGetUnreadCount;
    late MockSendReplyUseCase mockSendReply;
    late MockMarkThreadReadUseCase mockMarkThreadRead;
    late StreamController<FeedbackOSEvent> events;
    late ValueNotifier<bool> connected;
    late int threadReadCalls;
    late List<String> watched;

    final detail = ThreadDetail(
      id: 'item_1',
      title: 'Crash on Android 14',
      description: 'Happens on back navigation',
      type: 'bug',
      status: 'in_progress',
      createdAt: DateTime.parse('2026-10-14T00:00:00.000Z'),
      replies: const [],
    );

    ReplyReceived reply(String itemId) => ReplyReceived(
          itemId: itemId,
          replyId: 'r_1',
          authorName: 'Jane',
          preview: 'Hi',
          createdAt: DateTime.utc(2026, 11, 25),
        );

    ThreadsBloc buildBloc() => ThreadsBloc(
          getMyItemsUseCase: mockGetMyItems,
          getThreadDetailUseCase: mockGetThreadDetail,
          getUnreadCountUseCase: mockGetUnreadCount,
          sendReplyUseCase: mockSendReply,
          markThreadReadUseCase: mockMarkThreadRead,
          realtime: RealtimeLink(
            events: events.stream,
            isConnected: connected,
            onThreadRead: () async => threadReadCalls++,
            onThreadWatched: watched.add,
            onThreadUnwatched: (id) => watched.remove(id),
          ),
        );

    setUp(() {
      mockGetMyItems = MockGetMyItemsUseCase();
      mockGetThreadDetail = MockGetThreadDetailUseCase();
      mockGetUnreadCount = MockGetUnreadCountUseCase();
      mockSendReply = MockSendReplyUseCase();
      mockMarkThreadRead = MockMarkThreadReadUseCase();
      events = StreamController<FeedbackOSEvent>.broadcast();
      connected = ValueNotifier<bool>(true);
      threadReadCalls = 0;
      watched = [];

      when(() => mockGetThreadDetail.call(
            itemId: any(named: 'itemId'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => Right(detail));
      when(() => mockMarkThreadRead.call(
            itemId: any(named: 'itemId'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer((_) async => const Right(null));
      when(() => mockGetMyItems.call(cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => const Right([]));
      when(() =>
              mockGetUnreadCount.call(cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => const Right(UnreadCount(count: 1)));
    });

    test('refreshes and marks read the watched thread on a live event', () {
      fakeAsync((async) {
        final bloc = buildBloc();
        bloc.add(const ThreadPollingStarted('item_1'));
        async.flushMicrotasks();
        expect(watched, ['item_1']);

        events.add(reply('item_1'));
        async.flushMicrotasks();

        verify(() => mockGetThreadDetail.call(itemId: 'item_1')).called(1);
        verify(() => mockMarkThreadRead.call(itemId: 'item_1')).called(1);
        expect(threadReadCalls, 1);

        // Events for other threads do not refresh the open thread.
        events.add(reply('item_2'));
        async.flushMicrotasks();
        verifyNever(() => mockGetThreadDetail.call(itemId: 'item_2'));

        bloc.add(const ThreadPollingStopped());
        async.flushMicrotasks();
        expect(watched, isEmpty);
        bloc.close();
        async.flushMicrotasks();
      });
    });

    test('silently refreshes "My requests" on events once loaded', () {
      fakeAsync((async) {
        final bloc = buildBloc();
        events.add(reply('item_9'));
        async.flushMicrotasks();
        verifyNever(
            () => mockGetMyItems.call(cancelToken: any(named: 'cancelToken')));

        bloc.add(const MyItemsStarted());
        async.flushMicrotasks();
        final states = <ThreadsState>[];
        bloc.stream.listen(states.add);

        events.add(reply('item_9'));
        async.flushMicrotasks();
        verify(() =>
                mockGetMyItems.call(cancelToken: any(named: 'cancelToken')))
            .called(2);
        expect(states.any((s) => s.status == ThreadsStatus.loading), isFalse);

        bloc.close();
        async.flushMicrotasks();
      });
    });

    test('does not poll while connected; polls as fallback when disconnected',
        () {
      fakeAsync((async) {
        final bloc = buildBloc();
        bloc.add(const ThreadPollingStarted(
          'item_1',
          interval: Duration(seconds: 4),
        ));
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 20));
        verifyNever(() => mockGetThreadDetail.call(itemId: 'item_1'));
        expect(bloc.isPolling, isFalse);

        // Socket drops: fallback polling kicks in.
        connected.value = false;
        async.flushMicrotasks();
        expect(bloc.isPolling, isTrue);
        async.elapse(const Duration(seconds: 8));
        verify(() => mockGetThreadDetail.call(itemId: 'item_1')).called(2);

        // Socket back: one catch-up refresh, then polling stops.
        connected.value = true;
        async.flushMicrotasks();
        expect(bloc.isPolling, isFalse);
        async.elapse(const Duration(seconds: 20));
        verify(() => mockGetThreadDetail.call(itemId: 'item_1')).called(1);

        bloc.close();
        async.flushMicrotasks();
      });
    });

    test('polls when realtime is disabled (no link)', () {
      fakeAsync((async) {
        final bloc = ThreadsBloc(
          getMyItemsUseCase: mockGetMyItems,
          getThreadDetailUseCase: mockGetThreadDetail,
          getUnreadCountUseCase: mockGetUnreadCount,
          sendReplyUseCase: mockSendReply,
          markThreadReadUseCase: mockMarkThreadRead,
        );
        bloc.add(const ThreadPollingStarted(
          'item_1',
          interval: Duration(seconds: 4),
        ));
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 12));
        verify(() => mockGetThreadDetail.call(itemId: 'item_1')).called(3);

        bloc.close();
        async.flushMicrotasks();
      });
    });

    test('ThreadReadMarked resyncs the global unread count', () {
      fakeAsync((async) {
        final bloc = buildBloc();
        bloc.add(const ThreadReadMarked('item_1'));
        async.flushMicrotasks();
        expect(threadReadCalls, 1);
        bloc.close();
        async.flushMicrotasks();
      });
    });
  });
}
