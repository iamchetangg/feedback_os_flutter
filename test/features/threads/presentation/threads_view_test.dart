import 'package:feedback_os_flutter/src/features/threads/domain/entities/my_feedback_item.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/entities/thread_detail.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/entities/thread_reply.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/entities/unread_count.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/usecases/get_my_items_use_case.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/usecases/get_thread_detail_use_case.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/usecases/get_unread_count_use_case.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/usecases/mark_thread_read_use_case.dart';
import 'package:feedback_os_flutter/src/features/threads/domain/usecases/send_reply_use_case.dart';
import 'package:feedback_os_flutter/src/features/threads/presentation/my_feedback_list_view.dart';
import 'package:feedback_os_flutter/src/features/threads/presentation/thread_detail_view.dart';
import 'package:feedback_os_flutter/src/features/threads/state/threads_bloc.dart';
import 'package:feedback_os_flutter/src/features/threads/state/threads_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
  group('Threads Presentation Widget Tests', () {
    late MockGetMyItemsUseCase mockGetMyItems;
    late MockGetThreadDetailUseCase mockGetThreadDetail;
    late MockGetUnreadCountUseCase mockGetUnreadCount;
    late MockSendReplyUseCase mockSendReply;
    late MockMarkThreadReadUseCase mockMarkThreadRead;

    final testItem = MyFeedbackItem(
      id: 'item_1',
      title: 'Crash on Android 14',
      type: 'bug',
      category: 'Stability',
      status: 'in_progress',
      hasUnread: true,
      createdAt: DateTime.parse('2026-10-14T00:00:00.000Z'),
    );

    final testDetail = ThreadDetail(
      id: 'item_1',
      title: 'Crash on Android 14',
      description: 'Happens on back navigation',
      type: 'bug',
      category: 'Stability',
      status: 'in_progress',
      createdAt: DateTime.parse('2026-10-14T00:00:00.000Z'),
      replies: [
        ThreadReply(
          id: 'rep_1',
          body: 'We isolated the root cause',
          authorType: 'admin',
          createdAt: DateTime.parse('2026-10-14T01:00:00.000Z'),
        )
      ],
      events: const [],
    );

    setUp(() {
      mockGetMyItems = MockGetMyItemsUseCase();
      mockGetThreadDetail = MockGetThreadDetailUseCase();
      mockGetUnreadCount = MockGetUnreadCountUseCase();
      mockSendReply = MockSendReplyUseCase();
      mockMarkThreadRead = MockMarkThreadReadUseCase();

      when(() => mockGetMyItems()).thenAnswer((_) async => Right([testItem]));
      when(() => mockGetUnreadCount())
          .thenAnswer((_) async => const Right(UnreadCount(count: 1)));
      when(() => mockGetThreadDetail(itemId: 'item_1'))
          .thenAnswer((_) async => Right(testDetail));
      when(() => mockMarkThreadRead(itemId: 'item_1'))
          .thenAnswer((_) async => const Right(null));
    });

    late ThreadsBloc bloc;

    tearDown(() {
      bloc.close();
    });

    testWidgets('MyFeedbackListView renders user submitted items',
        (tester) async {
      bloc = ThreadsBloc(
        getMyItemsUseCase: mockGetMyItems,
        getThreadDetailUseCase: mockGetThreadDetail,
        getUnreadCountUseCase: mockGetUnreadCount,
        sendReplyUseCase: mockSendReply,
        markThreadReadUseCase: mockMarkThreadRead,
        initialState: ThreadsState(
          status: ThreadsStatus.success,
          items: [testItem],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ThreadsBloc>.value(
            value: bloc,
            child: const MyFeedbackListView(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Feedback'), findsOneWidget);
      expect(find.text('Crash on Android 14'), findsOneWidget);
      expect(find.text('In progress'), findsOneWidget);
    });

    testWidgets('ThreadDetailView renders conversation and allows reply input',
        (tester) async {
      bloc = ThreadsBloc(
        getMyItemsUseCase: mockGetMyItems,
        getThreadDetailUseCase: mockGetThreadDetail,
        getUnreadCountUseCase: mockGetUnreadCount,
        sendReplyUseCase: mockSendReply,
        markThreadReadUseCase: mockMarkThreadRead,
        initialState: ThreadsState(
          status: ThreadsStatus.success,
          selectedThread: testDetail,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<ThreadsBloc>.value(
            value: bloc,
            child: const ThreadDetailView(itemId: 'item_1'),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Your request'), findsOneWidget);
      expect(find.text('Crash on Android 14'), findsOneWidget);
      expect(
          find.textContaining('Happens on back navigation'), findsOneWidget);
      expect(find.text('FeedbackOS Team'), findsOneWidget);
      expect(find.text('We isolated the root cause'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });
  });
}
