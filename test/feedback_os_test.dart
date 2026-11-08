import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';
import 'package:feedback_os_flutter/src/core/network/api_endpoints.dart';
import 'package:feedback_os_flutter/src/core/network/feedback_os_dio_client.dart';
import 'package:feedback_os_flutter/src/features/uploads/data/datasources/binary_uploader.dart';
import 'package:feedback_os_flutter/src/features/uploads/data/datasources/upload_remote_data_source.dart';
import 'package:feedback_os_flutter/src/features/uploads/data/repositories/upload_repository_impl.dart';

class MockFeedbackOsHttpClient extends Mock implements FeedbackOsHttpClient {}

void main() {
  late MockFeedbackOsHttpClient mockHttpClient;
  late InMemoryDeviceIdStore inMemoryDeviceStore;
  late InMemorySubmissionStore inMemorySubmissionStore;
  const testKey = 'fos_pk_test_live_123';
  const testDeviceId = '12345678-1234-1234-1234-123456789abc';

  setUp(() async {
    mockHttpClient = MockFeedbackOsHttpClient();
    inMemoryDeviceStore = InMemoryDeviceIdStore(initialDeviceId: testDeviceId);
    inMemorySubmissionStore = InMemorySubmissionStore();
    await inMemorySubmissionStore.open();
    await FeedbackOS.instance.reset();
  });

  tearDown(() async {
    await FeedbackOS.instance.reset();
  });

  group('FeedbackOS Initialization', () {
    test('throws FeedbackOsValidationException when key is empty', () async {
      expect(
        () => FeedbackOS.instance.initializeTest(publishableKey: ''),
        throwsA(isA<FeedbackOsValidationException>()),
      );
    });

    test('throws FeedbackOsValidationException when key has invalid prefix',
        () async {
      expect(
        () => FeedbackOS.instance
            .initializeTest(publishableKey: 'secret_key_123'),
        throwsA(isA<FeedbackOsValidationException>()),
      );
    });

    test('initializes successfully with valid key without requiring network',
        () async {
      await FeedbackOS.instance.initializeTest(
        publishableKey: testKey,
        deviceIdStore: inMemoryDeviceStore,
        submissionStore: inMemorySubmissionStore,
        httpClient: mockHttpClient,
        deviceInfoProvider: const StaticDeviceInfoProvider(),
      );

      expect(FeedbackOS.instance.isInitialized, isTrue);
      expect(FeedbackOS.instance.publishableKey, equals(testKey));
      expect(await FeedbackOS.instance.getDeviceId(), equals(testDeviceId));
    });

    test('calling initialize repeatedly with identical key is idempotent',
        () async {
      await FeedbackOS.instance.initializeTest(
        publishableKey: testKey,
        deviceIdStore: inMemoryDeviceStore,
        submissionStore: inMemorySubmissionStore,
        httpClient: mockHttpClient,
        deviceInfoProvider: const StaticDeviceInfoProvider(),
      );

      // Second call with same key should succeed without throwing
      await FeedbackOS.instance.initializeTest(
        publishableKey: testKey,
        deviceIdStore: inMemoryDeviceStore,
        submissionStore: inMemorySubmissionStore,
        httpClient: mockHttpClient,
        deviceInfoProvider: const StaticDeviceInfoProvider(),
      );

      expect(FeedbackOS.instance.isInitialized, isTrue);
    });

    test('calling initialize with different key throws without reset()',
        () async {
      await FeedbackOS.instance.initializeTest(
        publishableKey: testKey,
        deviceIdStore: inMemoryDeviceStore,
        submissionStore: inMemorySubmissionStore,
        httpClient: mockHttpClient,
        deviceInfoProvider: const StaticDeviceInfoProvider(),
      );

      expect(
        () => FeedbackOS.instance.initializeTest(
          publishableKey: 'fos_pk_different_project_456',
          deviceIdStore: inMemoryDeviceStore,
          submissionStore: inMemorySubmissionStore,
          httpClient: mockHttpClient,
        ),
        throwsA(isA<FeedbackOsValidationException>()),
      );
    });

    test(
        'calling methods before initialization throws FeedbackOsValidationException',
        () async {
      expect(
        () => FeedbackOS.instance.getDeviceId(),
        throwsA(isA<FeedbackOsValidationException>()),
      );
      expect(
        () => FeedbackOS.instance.ping(),
        throwsA(isA<FeedbackOsValidationException>()),
      );
    });
  });

  group('FeedbackOS Operations', () {
    setUp(() async {
      await FeedbackOS.instance.initializeTest(
        publishableKey: testKey,
        deviceIdStore: inMemoryDeviceStore,
        submissionStore: inMemorySubmissionStore,
        httpClient: mockHttpClient,
        deviceInfoProvider: const StaticDeviceInfoProvider(),
      );
    });

    test('ping returns SdkPingResult', () async {
      when(
        () => mockHttpClient.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          includeAuthHeaders: any(named: 'includeAuthHeaders'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/sdk/ping'),
          statusCode: 200,
          data: {'ok': true, 'app_id': '1c0e8260-63ee-4213-a70d-f06f88da777c'},
        ),
      );

      final ping = await FeedbackOS.instance.ping();
      expect(ping.ok, isTrue);
      expect(ping.appId, equals('1c0e8260-63ee-4213-a70d-f06f88da777c'));
    });

    test('getConfig returns SdkConfig', () async {
      when(
        () => mockHttpClient.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          includeAuthHeaders: any(named: 'includeAuthHeaders'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/sdk/config/$testKey'),
          statusCode: 200,
          data: {
            'app_id': '1c0e8260-63ee-4213-a70d-f06f88da777c',
            'config_version': 1,
            'enabled': true,
            'board': {'enabled': true},
            'roadmap': {'enabled': false},
            'categories': ['UX'],
            'statuses': ['open'],
            'limits': {
              'max_screenshots': 3,
              'max_screenshot_bytes': 5000000,
              'screenshot_types': ['image/jpeg'],
            },
          },
        ),
      );

      final config = await FeedbackOS.instance.getConfig();
      expect(config.appId, equals('1c0e8260-63ee-4213-a70d-f06f88da777c'));
      expect(config.enabled, isTrue);
      expect(config.board.enabled, isTrue);
    });

    test('identify associates user and clearIdentity removes it', () async {
      when(
        () => mockHttpClient.post<void>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          includeAuthHeaders: any(named: 'includeAuthHeaders'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/sdk/identify'),
          statusCode: 204,
        ),
      );

      await FeedbackOS.instance.identify(externalUserId: 'cust_987');
      expect(FeedbackOS.instance.activeExternalUserId, equals('cust_987'));

      await FeedbackOS.instance.clearIdentity();
      expect(FeedbackOS.instance.activeExternalUserId, isNull);
    });

    test('submitFeedback delivers online and removes from store (sent status)',
        () async {
      when(
        () => mockHttpClient.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          includeAuthHeaders: any(named: 'includeAuthHeaders'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/sdk/feedback'),
          statusCode: 201,
          data: {
            'id': '99999999-8888-7777-6666-555555555555',
            'type': 'bug',
            'title': 'Payment failed',
            'description': 'Crash on submit',
            'category': 'Payments',
            'status': 'open',
            'is_public': false,
            'created_at': '2026-10-13T12:00:00Z',
          },
        ),
      );

      final result = await FeedbackOS.instance.submitFeedback(
        type: FeedbackType.bug,
        title: 'Payment failed',
        description: 'Crash on submit',
        category: 'Payments',
        clientSubmissionId: 'custom_sub_id_12345',
      );

      expect(result.status, equals(FeedbackSubmitStatus.sent));
      expect(result.isSent, isTrue);
      expect(result.itemId, equals('99999999-8888-7777-6666-555555555555'));
      expect(result.clientSubmissionId, equals('custom_sub_id_12345'));
      expect(
          await inMemorySubmissionStore.getById('custom_sub_id_12345'), isNull);
      expect(await FeedbackOS.instance.getQueuedCount(), equals(0));
    });

    test('submitFeedback persists and returns queued status on network failure',
        () async {
      when(
        () => mockHttpClient.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          includeAuthHeaders: any(named: 'includeAuthHeaders'),
        ),
      ).thenThrow(
        const FeedbackOsNetworkException('Offline: DNS lookup failed'),
      );

      final result = await FeedbackOS.instance.submitFeedback(
        type: FeedbackType.feature,
        title: 'Offline Dark Mode',
        clientSubmissionId: 'offline_sub_id_12345',
      );

      expect(result.status, equals(FeedbackSubmitStatus.queued));
      expect(result.isQueued, isTrue);
      expect(await FeedbackOS.instance.getQueuedCount(), equals(1));

      final queued =
          await inMemorySubmissionStore.getById('offline_sub_id_12345');
      expect(queued, isNotNull);
      expect(queued?.status, equals(QueueStatus.retryScheduled));
    });

    test('flushQueue sends queued items once network returns', () async {
      when(
        () => mockHttpClient.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          includeAuthHeaders: any(named: 'includeAuthHeaders'),
        ),
      ).thenThrow(
        const FeedbackOsNetworkException('Offline'),
      );

      // 1. Submit while offline
      await FeedbackOS.instance.submitFeedback(
        type: FeedbackType.bug,
        title: 'Offline Bug',
        clientSubmissionId: 'retry_sub_id_12345',
      );
      expect(await FeedbackOS.instance.getQueuedCount(), equals(1));

      // 2. Network restores
      when(
        () => mockHttpClient.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          includeAuthHeaders: any(named: 'includeAuthHeaders'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/sdk/feedback'),
          statusCode: 201,
          data: {
            'id': 'restored_id_999',
            'type': 'bug',
            'title': 'Offline Bug',
            'description': '',
            'status': 'open',
            'is_public': false,
            'created_at': '2026-10-13T12:00:00Z',
          },
        ),
      );

      // Manually make due immediately
      final item = await inMemorySubmissionStore.getById('retry_sub_id_12345');
      await inMemorySubmissionStore.insert(
        item!.copyWith(
            nextAttemptAt:
                DateTime.now().toUtc().subtract(const Duration(seconds: 1))),
      );

      final sentCount = await FeedbackOS.instance.flushQueue();
      expect(sentCount, equals(1));
      expect(await FeedbackOS.instance.getQueuedCount(), equals(0));
    });

    test('enforces queue maxOfflineQueueSize capacity limit', () async {
      await FeedbackOS.instance.reset();
      await FeedbackOS.instance.initializeTest(
        publishableKey: testKey,
        deviceIdStore: inMemoryDeviceStore,
        submissionStore: inMemorySubmissionStore,
        httpClient: mockHttpClient,
        deviceInfoProvider: const StaticDeviceInfoProvider(),
        options: const FeedbackOSOptions(maxOfflineQueueSize: 1),
      );

      when(
        () => mockHttpClient.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          includeAuthHeaders: any(named: 'includeAuthHeaders'),
        ),
      ).thenThrow(
        const FeedbackOsNetworkException('Offline'),
      );

      // First submission fills capacity
      await FeedbackOS.instance.submitFeedback(
        type: FeedbackType.bug,
        title: 'First item',
        clientSubmissionId: 'item_1_12345678',
      );

      // Second submission exceeds limit and throws storage exception
      expect(
        () => FeedbackOS.instance.submitFeedback(
          type: FeedbackType.bug,
          title: 'Second item',
          clientSubmissionId: 'item_2_12345678',
        ),
        throwsA(isA<FeedbackOsStorageException>()),
      );
    });

    test('uploadScreenshot reserves and transmits binary data', () async {
      await FeedbackOS.instance.initializeTest(
        publishableKey: testKey,
        deviceIdStore: inMemoryDeviceStore,
        submissionStore: inMemorySubmissionStore,
        httpClient: mockHttpClient,
        deviceInfoProvider: const StaticDeviceInfoProvider(),
      );

      when(
        () => mockHttpClient.post<Map<String, dynamic>>(
          ApiEndpoints.uploads,
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          includeAuthHeaders: any(named: 'includeAuthHeaders'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.uploads),
          statusCode: 201,
          data: {
            'upload_id': 'upload-uuid-456',
            'method': 'PUT',
            'url': 'https://r2.storage.feedbackos.dev/screen.png',
            'headers': {'content-type': 'image/png'},
            'expires_at': DateTime.now()
                .add(const Duration(minutes: 15))
                .toIso8601String(),
          },
        ),
      );

      final dummyUploader = _FakeBinaryUploader();
      final uploadRepo = UploadRepositoryImpl(
        remoteDataSource: UploadRemoteDataSourceImpl(client: mockHttpClient),
        binaryUploader: dummyUploader,
      );

      await FeedbackOS.instance.reset();
      await FeedbackOS.instance.initializeTest(
        publishableKey: testKey,
        deviceIdStore: inMemoryDeviceStore,
        submissionStore: inMemorySubmissionStore,
        httpClient: mockHttpClient,
        deviceInfoProvider: const StaticDeviceInfoProvider(),
        uploadRepository: uploadRepo,
      );

      final attachment = ScreenshotAttachment(
        fileName: 'screen.png',
        contentType: 'image/png',
        bytes: Uint8List.fromList([10, 20, 30]),
      );

      final uploadId = await FeedbackOS.instance.uploadScreenshot(
        attachment: attachment,
      );

      expect(uploadId, equals('upload-uuid-456'));
      expect(dummyUploader.uploadedBytes,
          equals(Uint8List.fromList([10, 20, 30])));
    });

    test(
        'submitFeedback uploads screenshot first then references uploadId in submit payload',
        () async {
      final dummyUploader = _FakeBinaryUploader();
      final uploadRepo = UploadRepositoryImpl(
        remoteDataSource: UploadRemoteDataSourceImpl(client: mockHttpClient),
        binaryUploader: dummyUploader,
      );

      await FeedbackOS.instance.reset();
      await FeedbackOS.instance.initializeTest(
        publishableKey: testKey,
        deviceIdStore: inMemoryDeviceStore,
        submissionStore: inMemorySubmissionStore,
        httpClient: mockHttpClient,
        deviceInfoProvider: const StaticDeviceInfoProvider(),
        uploadRepository: uploadRepo,
      );

      // 1. Mock upload reservation
      when(
        () => mockHttpClient.post<Map<String, dynamic>>(
          ApiEndpoints.uploads,
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          includeAuthHeaders: any(named: 'includeAuthHeaders'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.uploads),
          statusCode: 201,
          data: {
            'upload_id': 'upload-ref-999',
            'method': 'PUT',
            'url': 'https://r2.storage.feedbackos.dev/screen.jpg',
            'headers': {'content-type': 'image/jpeg'},
            'expires_at': DateTime.now()
                .add(const Duration(minutes: 15))
                .toIso8601String(),
          },
        ),
      );

      // 2. Mock feedback submit
      Map<String, dynamic>? capturedFeedbackPayload;
      when(
        () => mockHttpClient.post<Map<String, dynamic>>(
          ApiEndpoints.feedback,
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
          includeAuthHeaders: any(named: 'includeAuthHeaders'),
        ),
      ).thenAnswer(
        (invocation) async {
          capturedFeedbackPayload =
              invocation.namedArguments[#data] as Map<String, dynamic>?;
          return Response(
            requestOptions: RequestOptions(path: ApiEndpoints.feedback),
            statusCode: 201,
            data: {
              'id': 'item-created-123',
              'type': 'bug',
              'title': 'Bug with SS',
              'description': 'Description',
              'status': 'open',
              'is_public': false,
              'created_at': '2026-10-14T00:00:00Z',
            },
          );
        },
      );

      final attachment = ScreenshotAttachment(
        fileName: 'screen.jpg',
        contentType: 'image/jpeg',
        bytes: Uint8List.fromList([1, 2, 3, 4, 5]),
      );

      final result = await FeedbackOS.instance.submitFeedback(
        type: FeedbackType.bug,
        title: 'Bug with SS',
        attachments: [attachment],
      );

      expect(result.status, equals(FeedbackSubmitStatus.sent));
      expect(result.itemId, equals('item-created-123'));
      expect(dummyUploader.uploadedBytes, equals(attachment.bytes));
      expect(capturedFeedbackPayload, isNotNull);
      expect(capturedFeedbackPayload!['screenshot_upload_ids'],
          equals(['upload-ref-999']));
    });
  });

  group('FeedbackOS Board & Roadmap Facade Operations', () {
    setUp(() async {
      when(
        () => mockHttpClient.get<Map<String, dynamic>>(
          ApiEndpoints.config(testKey),
          cancelToken: any(named: 'cancelToken'),
          includeAuthHeaders: any(named: 'includeAuthHeaders'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.config(testKey)),
          statusCode: 200,
          data: {
            'app_id': 'app_123',
            'config_version': 1,
            'enabled': true,
            'board': {'enabled': true},
            'roadmap': {'enabled': true},
            'categories': ['UI', 'General'],
            'statuses': ['open', 'in_progress', 'planned', 'shipped'],
            'limits': {
              'max_screenshots': 3,
              'max_screenshot_bytes': 5242880,
              'screenshot_types': ['image/jpeg', 'image/png'],
            },
          },
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

    test('getBoard returns BoardPage when board is enabled', () async {
      when(
        () => mockHttpClient.get<Map<String, dynamic>>(
          ApiEndpoints.board,
          queryParameters: any(named: 'queryParameters'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.board),
          statusCode: 200,
          data: {
            'data': [
              {
                'id': 'b_1',
                'title': 'Feature Idea',
                'status': 'open',
                'vote_count': 10,
                'has_voted': false,
                'is_mine': false,
              }
            ],
            'next_cursor': 'cursor_999',
          },
        ),
      );

      final page = await FeedbackOS.instance.getBoard();

      expect(page.items.length, 1);
      expect(page.items.first.title, 'Feature Idea');
      expect(page.nextCursor, 'cursor_999');
    });

    test(
        'getBoard throws validation exception when board is disabled in config',
        () async {
      await FeedbackOS.instance.reset();
      when(
        () => mockHttpClient.get<Map<String, dynamic>>(
          ApiEndpoints.config(testKey),
          cancelToken: any(named: 'cancelToken'),
          includeAuthHeaders: any(named: 'includeAuthHeaders'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.config(testKey)),
          statusCode: 200,
          data: {
            'app_id': 'app_123',
            'config_version': 1,
            'enabled': true,
            'board': {'enabled': false},
            'roadmap': {'enabled': true},
            'categories': [],
            'statuses': [],
            'limits': {
              'max_screenshots': 3,
              'max_screenshot_bytes': 5242880,
              'screenshot_types': ['image/jpeg'],
            },
          },
        ),
      );

      await FeedbackOS.instance.initializeTest(
        publishableKey: testKey,
        deviceIdStore: inMemoryDeviceStore,
        submissionStore: inMemorySubmissionStore,
        httpClient: mockHttpClient,
        deviceInfoProvider: const StaticDeviceInfoProvider(),
      );

      expect(
        () => FeedbackOS.instance.getBoard(),
        throwsA(isA<FeedbackOsValidationException>().having(
          (e) => e.code,
          'code',
          'feature_disabled',
        )),
      );
    });

    test('getRoadmap returns Roadmap when enabled', () async {
      when(
        () => mockHttpClient.get<Map<String, dynamic>>(
          ApiEndpoints.roadmap,
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.roadmap),
          statusCode: 200,
          data: {
            'planned': [
              {
                'id': 'r_1',
                'title': 'Roadmap Item',
                'status': 'planned',
                'vote_count': 5,
                'has_voted': true,
                'is_mine': true,
              }
            ],
            'in_progress': [],
            'shipped': [],
          },
        ),
      );

      final roadmap = await FeedbackOS.instance.getRoadmap();

      expect(roadmap.planned.length, 1);
      expect(roadmap.planned.first.id, 'r_1');
    });

    test('voteItem and unvoteItem return updated VoteResult', () async {
      when(
        () => mockHttpClient.post<Map<String, dynamic>>(
          ApiEndpoints.itemVote('item_1'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.itemVote('item_1')),
          statusCode: 200,
          data: {'vote_count': 11, 'has_voted': true},
        ),
      );

      final vote = await FeedbackOS.instance.voteItem(itemId: 'item_1');
      expect(vote.voteCount, 11);
      expect(vote.hasVoted, isTrue);

      when(
        () => mockHttpClient.delete<Map<String, dynamic>>(
          ApiEndpoints.itemVote('item_1'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.itemVote('item_1')),
          statusCode: 200,
          data: {'vote_count': 10, 'has_voted': false},
        ),
      );

      final unvote = await FeedbackOS.instance.unvoteItem(itemId: 'item_1');
      expect(unvote.voteCount, 10);
      expect(unvote.hasVoted, isFalse);
    });
  });

  group('FeedbackOS Threads Facade Operations', () {
    setUp(() async {
      await FeedbackOS.instance.initializeTest(
        publishableKey: testKey,
        deviceIdStore: inMemoryDeviceStore,
        submissionStore: inMemorySubmissionStore,
        httpClient: mockHttpClient,
        deviceInfoProvider: const StaticDeviceInfoProvider(),
      );
    });

    test('getUnreadCount returns integer count', () async {
      when(
        () => mockHttpClient.get<Map<String, dynamic>>(
          ApiEndpoints.meUnread,
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.meUnread),
          statusCode: 200,
          data: {'count': 7},
        ),
      );

      final count = await FeedbackOS.instance.getUnreadCount();
      expect(count, 7);
    });

    test('getMyItems returns list of user items', () async {
      when(
        () => mockHttpClient.get<Map<String, dynamic>>(
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
                'title': 'My Report',
                'type': 'bug',
                'status': 'open',
                'has_unread': true,
              }
            ]
          },
        ),
      );

      final items = await FeedbackOS.instance.getMyItems();
      expect(items.length, 1);
      expect(items.first.title, 'My Report');
      expect(items.first.hasUnread, isTrue);
    });

    test('getThreadDetail returns detail with replies and events', () async {
      when(
        () => mockHttpClient.get<Map<String, dynamic>>(
          ApiEndpoints.meItemDetail('item_123'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions:
              RequestOptions(path: ApiEndpoints.meItemDetail('item_123')),
          statusCode: 200,
          data: {
            'id': 'item_123',
            'title': 'My Thread',
            'description': 'Details',
            'type': 'feature',
            'status': 'planned',
            'replies': [
              {
                'id': 'rep_1',
                'body': 'Great suggestion!',
                'author_type': 'admin',
              }
            ],
            'events': [],
          },
        ),
      );

      final detail =
          await FeedbackOS.instance.getThreadDetail(itemId: 'item_123');
      expect(detail.id, 'item_123');
      expect(detail.replies.length, 1);
      expect(detail.replies.first.isAdmin, isTrue);
    });

    test('sendReply posts message and returns ThreadReply', () async {
      when(
        () => mockHttpClient.post<Map<String, dynamic>>(
          ApiEndpoints.meItemReplies('item_123'),
          data: {'body': 'Thanks!'},
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions:
              RequestOptions(path: ApiEndpoints.meItemReplies('item_123')),
          statusCode: 201,
          data: {
            'id': 'rep_2',
            'body': 'Thanks!',
            'author_type': 'user',
          },
        ),
      );

      final reply = await FeedbackOS.instance.sendReply(
        itemId: 'item_123',
        message: 'Thanks!',
      );

      expect(reply.id, 'rep_2');
      expect(reply.body, 'Thanks!');
      expect(reply.isUser, isTrue);
    });

    test('markThreadRead calls mark read endpoint without error', () async {
      when(
        () => mockHttpClient.post<dynamic>(
          ApiEndpoints.meItemRead('item_123'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions:
              RequestOptions(path: ApiEndpoints.meItemRead('item_123')),
          statusCode: 204,
        ),
      );

      await FeedbackOS.instance.markThreadRead(itemId: 'item_123');
      verify(
        () => mockHttpClient.post<dynamic>(
          ApiEndpoints.meItemRead('item_123'),
          cancelToken: null,
        ),
      ).called(1);
    });
  });
}

class _FakeBinaryUploader implements BinaryUploader {
  Uint8List? uploadedBytes;

  @override
  Future<void> uploadBinary({
    required UploadReservation reservation,
    required Uint8List bytes,
    CancelToken? cancelToken,
  }) async {
    uploadedBytes = bytes;
  }
}
