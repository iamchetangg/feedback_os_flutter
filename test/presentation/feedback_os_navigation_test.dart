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
    testWidgets(
        'openRoadmap pushes FeedbackContainerView with Roadmap tab active and allows switching tabs',
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
      expect(find.byType(FeedbackContainerView), findsNothing);

      // Tap to open Roadmap
      await tester.tap(find.byKey(const Key('open_roadmap_btn')));
      await tester.pumpAndSettle();

      // Verify FeedbackContainerView is on screen with RoadmapView active
      expect(find.byType(FeedbackContainerView), findsOneWidget);
      expect(find.byType(RoadmapView), findsOneWidget);
      expect(find.text('Feedback'), findsOneWidget);

      // Tap "Board" tab to switch tabs inside the container
      await tester.tap(find.text('Board'));
      await tester.pumpAndSettle();

      expect(find.byType(BoardView), findsOneWidget);

      // Tap "My requests" tab to switch tabs inside the container
      await tester.tap(find.text('My requests'));
      await tester.pumpAndSettle();

      expect(find.byType(MyFeedbackListView), findsOneWidget);

      // Tap "Roadmap" tab again to switch back
      await tester.tap(find.text('Roadmap'));
      await tester.pumpAndSettle();

      expect(find.byType(RoadmapView), findsOneWidget);

      // Back button pops back to host screen
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(FeedbackContainerView), findsNothing);
      expect(find.byKey(const Key('open_roadmap_btn')), findsOneWidget);
    });

    testWidgets('openBoard pushes FeedbackContainerView with Board tab active',
        (tester) async {
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

      expect(find.byType(FeedbackContainerView), findsOneWidget);
      expect(find.byType(BoardView), findsOneWidget);
      expect(find.text('Feedback'), findsOneWidget);
      expect(find.text('New request'), findsOneWidget);
    });

    testWidgets(
        'openFeedbackDashboard and openMyFeedback push FeedbackContainerView with My requests tab active',
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

      expect(find.byType(FeedbackContainerView), findsOneWidget);
      expect(find.byType(MyFeedbackListView), findsOneWidget);
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
      expect(find.text('Your request'), findsOneWidget);
    });

    testWidgets(
        'tapping unread item in MyFeedbackListView clears New reply badge when returning',
        (tester) async {
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
            'data': [
              {
                'id': 'item_nav_1',
                'type': 'feature',
                'title': 'Test Item',
                'description': 'Test Desc',
                'status': 'planned',
                'has_unread': true,
                'created_at': '2026-10-15T00:00:00.000Z',
              }
            ],
          },
          statusCode: 200,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return ElevatedButton(
                  key: const Key('open_dash_unread_btn'),
                  onPressed: () => FeedbackOS.instance
                      .openFeedbackDashboard(context: context),
                  child: const Text('Open Dashboard'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('open_dash_unread_btn')));
      await tester.pumpAndSettle();

      expect(find.byType(MyFeedbackListView), findsOneWidget);
      expect(find.text('New reply'), findsOneWidget);

      // On second fetch (after returning and marking read), has_unread is false
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
            'data': [
              {
                'id': 'item_nav_1',
                'type': 'feature',
                'title': 'Test Item',
                'description': 'Test Desc',
                'status': 'planned',
                'has_unread': false,
                'created_at': '2026-10-15T00:00:00.000Z',
              }
            ],
          },
          statusCode: 200,
        ),
      );

      // Tap the unread item to open ThreadDetailView
      await tester.tap(find.text('Test Item'));
      await tester.pumpAndSettle();

      expect(find.byType(ThreadDetailView), findsOneWidget);

      // Pop back to container / MyFeedbackListView
      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(MyFeedbackListView), findsOneWidget);
      // "New reply" badge is gone!
      expect(find.text('New reply'), findsNothing);
    });
  });
}

