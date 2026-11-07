import 'package:feedback_os_flutter/src/features/board/domain/entities/board_item.dart';
import 'package:feedback_os_flutter/src/features/board/domain/entities/roadmap.dart';
import 'package:feedback_os_flutter/src/features/board/domain/usecases/get_board_use_case.dart';
import 'package:feedback_os_flutter/src/features/board/domain/usecases/get_roadmap_use_case.dart';
import 'package:feedback_os_flutter/src/features/board/domain/usecases/unvote_item_use_case.dart';
import 'package:feedback_os_flutter/src/features/board/domain/usecases/vote_item_use_case.dart';
import 'package:feedback_os_flutter/src/features/board/presentation/roadmap_view.dart';
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
  group('RoadmapView Widget Tests', () {
    late MockGetBoardUseCase mockGetBoard;
    late MockGetRoadmapUseCase mockGetRoadmap;
    late MockVoteItemUseCase mockVote;
    late MockUnvoteItemUseCase mockUnvote;
    late BoardBloc bloc;

    final plannedItem = BoardItem(
      id: 'p1',
      title: 'Export to CSV',
      description: 'Export all reports to CSV',
      status: 'planned',
      voteCount: 20,
      hasVoted: false,
      isMine: false,
      createdAt: DateTime.now(),
    );

    setUp(() {
      mockGetBoard = MockGetBoardUseCase();
      mockGetRoadmap = MockGetRoadmapUseCase();
      mockVote = MockVoteItemUseCase();
      mockUnvote = MockUnvoteItemUseCase();

      when(() => mockGetRoadmap()).thenAnswer(
        (_) async => Right(Roadmap(
          planned: [plannedItem],
          inProgress: const [],
          shipped: const [],
        )),
      );

      bloc = BoardBloc(
        getBoardUseCase: mockGetBoard,
        getRoadmapUseCase: mockGetRoadmap,
        voteItemUseCase: mockVote,
        unvoteItemUseCase: mockUnvote,
        initialState: BoardState(
          status: BoardStatus.success,
          roadmap: Roadmap(
            planned: [plannedItem],
            inProgress: const [],
            shipped: const [],
          ),
        ),
      );
    });

    tearDown(() {
      bloc.close();
    });

    testWidgets('renders roadmap sections and items in planned tab',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BoardBloc>.value(
            value: bloc,
            child: const RoadmapView(),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Product Roadmap'), findsOneWidget);
      expect(find.text('Planned'), findsOneWidget);
      expect(find.text('In Progress'), findsOneWidget);
      expect(find.text('Shipped'), findsOneWidget);
      expect(find.text('Export to CSV'), findsOneWidget);
    });

    testWidgets(
        'renders and fires onOpenDashboard, onOpenBoard, and onOpenMyFeedback',
        (tester) async {
      bool dashboardOpened = false;
      bool boardOpened = false;
      bool myFeedbackOpened = false;

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<BoardBloc>.value(
            value: bloc,
            child: RoadmapView(
              onOpenDashboard: () => dashboardOpened = true,
              onOpenBoard: () => boardOpened = true,
              onOpenMyFeedback: () => myFeedbackOpened = true,
            ),
          ),
        ),
      );

      await tester.pump();

      final dashboardFinder =
          find.byKey(const Key('roadmap_open_dashboard_button'));
      final boardFinder = find.byKey(const Key('roadmap_open_board_button'));
      final myFeedbackFinder =
          find.byKey(const Key('roadmap_open_my_feedback_button'));

      expect(dashboardFinder, findsOneWidget);
      expect(boardFinder, findsOneWidget);
      expect(myFeedbackFinder, findsOneWidget);

      await tester.tap(dashboardFinder);
      await tester.tap(boardFinder);
      await tester.tap(myFeedbackFinder);

      expect(dashboardOpened, isTrue);
      expect(boardOpened, isTrue);
      expect(myFeedbackOpened, isTrue);
    });

    testWidgets('isFromBoard true pops current screen on dashboard button press',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  key: const Key('push_roadmap_btn'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider<BoardBloc>.value(
                          value: bloc,
                          child: const RoadmapView(isFromBoard: true),
                        ),
                      ),
                    );
                  },
                  child: const Text('Push Roadmap'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('push_roadmap_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(RoadmapView), findsOneWidget);

      final dashboardFinder =
          find.byKey(const Key('roadmap_open_dashboard_button'));
      expect(dashboardFinder, findsOneWidget);

      await tester.tap(dashboardFinder);
      await tester.pumpAndSettle();

      expect(find.byType(RoadmapView), findsNothing);
      expect(find.byKey(const Key('push_roadmap_btn')), findsOneWidget);
    });
  });
}
