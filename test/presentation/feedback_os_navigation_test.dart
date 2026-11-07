import 'package:dio/dio.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';
import 'package:feedback_os_flutter/src/core/network/api_endpoints.dart';
import 'package:feedback_os_flutter/src/core/network/feedback_os_dio_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFeedbackOsHttpClient extends Mock implements FeedbackOsHttpClient {}

void main() {
  late MockFeedbackOsHttpClient mockHttpClient;
  late InMemoryDeviceIdStore inMemoryDeviceStore;
  late InMemorySubmissionStore inMemorySubmissionStore;
  const testKey = 'fos_pk_test_live_nav_123';
  const testDeviceId = '12345678-1234-1234-1234-123456789abc';

  setUp(() async {
    mockHttpClient = MockFeedbackOsHttpClient();
    inMemoryDeviceStore = InMemoryDeviceIdStore(initialDeviceId: testDeviceId);
    inMemorySubmissionStore = InMemorySubmissionStore();
    await inMemorySubmissionStore.open();
    await FeedbackOS.instance.reset();

    // Mock API responses for board, roadmap, meItems, and thread detail
    when(
      () => mockHttpClient.get<Map<String, dynamic>>(
        ApiEndpoints.roadmap,
        queryParameters: any(named: 'queryParameters'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ApiEndpoints.roadmap),
        data: {
          'planned': [],
          'in_progress': [],
          'shipped': [],
        },
        statusCode: 200,
      ),
    );

    when(
      () => mockHttpClient.get<Map<String, dynamic>>(
        ApiEndpoints.board,
        queryParameters: any(named: 'queryParameters'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ApiEndpoints.board),
        data: {
          'items': [],
          'has_more': false,
        },
        statusCode: 200,
      ),
    );

    when(
      () => mockHttpClient.get<Map<String, dynamic>>(
        ApiEndpoints.meItems,
        queryParameters: any(named: 'queryParameters'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions: RequestOptions(path: ApiEndpoints.meItems),
        data: {
          'items': [],
        },
        statusCode: 200,
      ),
    );

    when(
      () => mockHttpClient.get<Map<String, dynamic>>(
        ApiEndpoints.meItemDetail('item_nav_1'),
        queryParameters: any(named: 'queryParameters'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions:
            RequestOptions(path: ApiEndpoints.meItemDetail('item_nav_1')),
        data: {
          'id': 'item_nav_1',
          'type': 'feature_request',
          'title': 'Test Item',
          'description': 'Test Desc',
          'status': 'planned',
          'vote_count': 5,
          'has_voted': false,
          'is_mine': true,
          'created_at': '2026-10-15T00:00:00.000Z',
          'events': [],
          'replies': [],
        },
        statusCode: 200,
      ),
    );

    when(
      () => mockHttpClient.post<dynamic>(
        ApiEndpoints.meItemRead('item_nav_1'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer(
      (_) async => Response(
        requestOptions:
            RequestOptions(path: ApiEndpoints.meItemRead('item_nav_1')),
        statusCode: 204,
      ),
    );

    await FeedbackOS.instance.initializeTest(
      publishableKey: testKey,
      deviceIdStore: inMemoryDeviceStore,
      submissionStore: inMemorySubmissionStore,
      httpClient: mockHttpClient,
      deviceInfoProvider: const StaticDeviceInfoProvider(),
    );
  });

  tearDown(() async {
    await FeedbackOS.instance.reset();
  });

  group('FeedbackOS Navigation Integration', () {
    testWidgets('openRoadmap pushes RoadmapView and allows navigating to BoardView and Dashboard',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  key: const Key('open_roadmap_btn'),
                  onPressed: () =>
                      FeedbackOS.instance.openRoadmap(context: context),
                  child: const Text('Open Roadmap'),
                );
              },
            ),
          ),
        ),
      );

      // Initially on host screen
      expect(find.byKey(const Key('open_roadmap_btn')), findsOneWidget);
      expect(find.byType(RoadmapView), findsNothing);

      // Tap to open Roadmap
      await tester.tap(find.byKey(const Key('open_roadmap_btn')));
      await tester.pumpAndSettle();

      // Verify RoadmapView is on screen
      expect(find.byType(RoadmapView), findsOneWidget);
      expect(find.text('Product Roadmap'), findsOneWidget);

      // Verify the dashboard action button is present on RoadmapView
      final dashboardBtn =
          find.byKey(const Key('roadmap_open_dashboard_button'));
      expect(dashboardBtn, findsOneWidget);

      // Tap dashboard button to open BoardView
      await tester.tap(dashboardBtn);
      await tester.pumpAndSettle();

      // Verify BoardView is now on screen
      expect(find.byType(BoardView), findsOneWidget);
      expect(find.text('Community Board'), findsOneWidget);

      // Verify dashboard action button is present on BoardView to track requests
      final boardDashboardBtn =
          find.byKey(const Key('board_open_dashboard_button'));
      expect(boardDashboardBtn, findsOneWidget);

      // Tap dashboard button on BoardView to open MyFeedbackListView
      await tester.tap(boardDashboardBtn);
      await tester.pumpAndSettle();

      // Verify MyFeedbackListView is now on screen
      expect(find.byType(MyFeedbackListView), findsOneWidget);
      expect(find.text('My Feedback'), findsOneWidget);
    });

    testWidgets(
        'toggling between Roadmap and Board pops back rather than pushing repetitive pages',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  key: const Key('open_roadmap_test_btn'),
                  onPressed: () =>
                      FeedbackOS.instance.openRoadmap(context: context),
                  child: const Text('Open Roadmap'),
                );
              },
            ),
          ),
        ),
      );

      // Open roadmap
      await tester.tap(find.byKey(const Key('open_roadmap_test_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(RoadmapView), findsOneWidget);
      expect(find.byType(BoardView), findsNothing);

      // Click "Feedback Dashboard" to navigate to BoardView
      await tester.tap(find.byKey(const Key('roadmap_open_dashboard_button')));
      await tester.pumpAndSettle();

      expect(find.byType(BoardView), findsOneWidget);

      // Click "Product Roadmap" on BoardView -> must POP back to existing RoadmapView, not push
      await tester.tap(find.byKey(const Key('board_open_roadmap_button')));
      await tester.pumpAndSettle();

      // BoardView is gone, exactly one RoadmapView is present
      expect(find.byType(BoardView), findsNothing);
      expect(find.byType(RoadmapView), findsOneWidget);

      // Click "Feedback Dashboard" again
      await tester.tap(find.byKey(const Key('roadmap_open_dashboard_button')));
      await tester.pumpAndSettle();

      expect(find.byType(BoardView), findsOneWidget);

      // Click "Product Roadmap" again -> pops back
      await tester.tap(find.byKey(const Key('board_open_roadmap_button')));
      await tester.pumpAndSettle();

      expect(find.byType(BoardView), findsNothing);
      expect(find.byType(RoadmapView), findsOneWidget);

      // Clicking back on RoadmapView returns to host screen
      await tester.tap(find.byIcon(Icons.arrow_back).first);
      await tester.pumpAndSettle();

      expect(find.byType(RoadmapView), findsNothing);
      expect(find.byKey(const Key('open_roadmap_test_btn')), findsOneWidget);
    });

    testWidgets(
        'toggling from Board to Roadmap pops back rather than pushing repetitive pages',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  key: const Key('open_board_test_btn'),
                  onPressed: () =>
                      FeedbackOS.instance.openBoard(context: context),
                  child: const Text('Open Board'),
                );
              },
            ),
          ),
        ),
      );

      // Open board
      await tester.tap(find.byKey(const Key('open_board_test_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(BoardView), findsOneWidget);
      expect(find.byType(RoadmapView), findsNothing);

      // Click "Product Roadmap" on BoardView to navigate to RoadmapView
      await tester.tap(find.byKey(const Key('board_open_roadmap_button')));
      await tester.pumpAndSettle();

      expect(find.byType(RoadmapView), findsOneWidget);

      // Click "Feedback Dashboard" on RoadmapView -> must POP back to existing BoardView
      await tester.tap(find.byKey(const Key('roadmap_open_dashboard_button')));
      await tester.pumpAndSettle();

      expect(find.byType(RoadmapView), findsNothing);
      expect(find.byType(BoardView), findsOneWidget);

      // Clicking back on BoardView returns to host screen
      await tester.tap(find.byIcon(Icons.arrow_back).first);
      await tester.pumpAndSettle();

      expect(find.byType(BoardView), findsNothing);
      expect(find.byKey(const Key('open_board_test_btn')), findsOneWidget);
    });

    testWidgets('openBoard pushes BoardView directly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  key: const Key('open_board_btn'),
                  onPressed: () =>
                      FeedbackOS.instance.openBoard(context: context),
                  child: const Text('Open Board'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open_board_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(BoardView), findsOneWidget);
      expect(find.text('Community Board'), findsOneWidget);
    });

    testWidgets('openFeedbackDashboard and openMyFeedback push MyFeedbackListView',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  key: const Key('open_dash_btn'),
                  onPressed: () => FeedbackOS.instance
                      .openFeedbackDashboard(context: context),
                  child: const Text('Open Dashboard'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open_dash_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(MyFeedbackListView), findsOneWidget);
      expect(find.text('My Feedback'), findsOneWidget);
    });

    testWidgets('openThreadDetail pushes ThreadDetailView', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  key: const Key('open_thread_btn'),
                  onPressed: () => FeedbackOS.instance.openThreadDetail(
                    context: context,
                    itemId: 'item_nav_1',
                  ),
                  child: const Text('Open Thread'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open_thread_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(ThreadDetailView), findsOneWidget);
      expect(find.text('Feedback Thread'), findsOneWidget);
    });
  });
}

