import 'package:feedback_os_flutter/src/features/board/domain/entities/board_item.dart';
import 'package:feedback_os_flutter/src/features/board/domain/entities/board_page.dart';
import 'package:feedback_os_flutter/src/features/board/domain/usecases/get_board_use_case.dart';
import 'package:feedback_os_flutter/src/features/board/domain/usecases/get_roadmap_use_case.dart';
import 'package:feedback_os_flutter/src/features/board/domain/usecases/unvote_item_use_case.dart';
import 'package:feedback_os_flutter/src/features/board/domain/usecases/vote_item_use_case.dart';
import 'package:feedback_os_flutter/src/features/board/presentation/board_view.dart';
import 'package:feedback_os_flutter/src/features/board/state/board_bloc.dart';
import 'package:feedback_os_flutter/src/features/board/state/board_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:mocktail/mocktail.dart';

class MockGetBoardUseCase extends Mock implements GetBoardUseCase {}

class MockGetRoadmapUseCase extends Mock implements GetRoadmapUseCase {}

class MockVoteItemUseCase extends Mock implements VoteItemUseCase {}

class MockUnvoteItemUseCase extends Mock implements UnvoteItemUseCase {}

void main() {
  group('BoardView Widget Tests', () {
    late MockGetBoardUseCase mockGetBoard;
    late MockGetRoadmapUseCase mockGetRoadmap;
    late MockVoteItemUseCase mockVote;
    late MockUnvoteItemUseCase mockUnvote;
    late BoardBloc bloc;

    final testItem = BoardItem(
      id: 'item_1',
      title: 'Dark Mode Support',
      description: 'Support dark mode please',
      category: 'UI',
      status: 'planned',
      voteCount: 15,
      hasVoted: false,
      isMine: true,
      createdAt: DateTime.parse('2026-10-14T00:00:00.000Z'),
    );

    setUp(() {
      mockGetBoard = MockGetBoardUseCase();
      mockGetRoadmap = MockGetRoadmapUseCase();
      mockVote = MockVoteItemUseCase();
      mockUnvote = MockUnvoteItemUseCase();

      when(() => mockGetBoard(
            sort: any(named: 'sort'),
            cursor: any(named: 'cursor'),
            limit: any(named: 'limit'),
            cancelToken: any(named: 'cancelToken'),
          )).thenAnswer(
        (_) async => Right(BoardPage(items: [testItem])),
      );

      bloc = BoardBloc(
        getBoardUseCase: mockGetBoard,
        getRoadmapUseCase: mockGetRoadmap,
        voteItemUseCase: mockVote,
        unvoteItemUseCase: mockUnvote,
        initialState: BoardState(
          status: BoardStatus.success,
          items: [testItem],
        ),
      );
    });

    tearDown(() {
      bloc.close();
    });

    testWidgets('renders board items and sort chips', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BoardBloc>.value(
            value: bloc,
            child: const BoardView(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Feedback'), findsOneWidget);
      expect(find.text('Dark Mode Support'), findsOneWidget);
      expect(find.text('Support dark mode please'), findsOneWidget);
      expect(find.text('Planned'), findsOneWidget);
      expect(find.text('You submitted'), findsOneWidget);
      expect(find.text('15'), findsOneWidget);
    });

    testWidgets('renders and fires onOpenDashboard and onOpenRoadmap',
        (tester) async {
      bool dashboardOpened = false;
      bool roadmapOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BoardBloc>.value(
            value: bloc,
            child: BoardView(
              onOpenDashboard: () => dashboardOpened = true,
              onOpenRoadmap: () => roadmapOpened = true,
            ),
          ),
        ),
      );

      await tester.pump();

      final dashboardFinder =
          find.byKey(const Key('board_open_dashboard_button'));
      final roadmapFinder = find.byKey(const Key('board_open_roadmap_button'));

      expect(dashboardFinder, findsOneWidget);
      expect(roadmapFinder, findsOneWidget);

      await tester.tap(dashboardFinder);
      await tester.tap(roadmapFinder);

      expect(dashboardOpened, isTrue);
      expect(roadmapOpened, isTrue);
    });

    testWidgets('isFromRoadmap true pops current screen on roadmap button press',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  key: const Key('push_board_btn'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider<BoardBloc>.value(
                          value: bloc,
                          child: const BoardView(isFromRoadmap: true),
                        ),
                      ),
                    );
                  },
                  child: const Text('Push Board'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('push_board_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(BoardView), findsOneWidget);

      final roadmapFinder = find.byKey(const Key('board_open_roadmap_button'));
      expect(roadmapFinder, findsOneWidget);

      await tester.tap(roadmapFinder);
      await tester.pumpAndSettle();

      expect(find.byType(BoardView), findsNothing);
      expect(find.byKey(const Key('push_board_btn')), findsOneWidget);
    });

    testWidgets('tapping an item only invokes onItemTap if currentUser owns it (isMine is true)',
        (tester) async {
      String? tappedItemId;

      final notMyItem = BoardItem(
        id: 'item_others',
        title: 'Others Request',
        description: 'Others desc',
        status: 'open',
        voteCount: 3,
        hasVoted: false,
        isMine: false,
        createdAt: DateTime.now(),
      );

      final myItem = BoardItem(
        id: 'item_mine',
        title: 'My Request',
        description: 'My desc',
        status: 'open',
        voteCount: 1,
        hasVoted: false,
        isMine: true,
        createdAt: DateTime.now(),
      );

      bloc = BoardBloc(
        getBoardUseCase: mockGetBoard,
        getRoadmapUseCase: mockGetRoadmap,
        voteItemUseCase: mockVote,
        unvoteItemUseCase: mockUnvote,
        initialState: BoardState(
          status: BoardStatus.success,
          items: [notMyItem, myItem],
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BoardBloc>.value(
            value: bloc,
            child: BoardView(
              onItemTap: (id) => tappedItemId = id,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap unowned item
      await tester.tap(find.text('Others Request'));
      await tester.pumpAndSettle();
      expect(tappedItemId, isNull);

      // Tap owned item
      await tester.tap(find.text('My Request'));
      await tester.pumpAndSettle();
      expect(tappedItemId, equals('item_mine'));
    });
  });
}
