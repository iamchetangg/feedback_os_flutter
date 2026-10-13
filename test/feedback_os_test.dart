import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';
import 'package:feedback_os_flutter/src/core/network/feedback_os_dio_client.dart';

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
        () => FeedbackOS.instance.initialize(publishableKey: ''),
        throwsA(isA<FeedbackOsValidationException>()),
      );
    });

    test('throws FeedbackOsValidationException when key has invalid prefix',
        () async {
      expect(
        () => FeedbackOS.instance.initialize(publishableKey: 'secret_key_123'),
        throwsA(isA<FeedbackOsValidationException>()),
      );
    });

    test('initializes successfully with valid key without requiring network',
        () async {
      await FeedbackOS.instance.initialize(
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
      await FeedbackOS.instance.initialize(
        publishableKey: testKey,
        deviceIdStore: inMemoryDeviceStore,
        submissionStore: inMemorySubmissionStore,
        httpClient: mockHttpClient,
        deviceInfoProvider: const StaticDeviceInfoProvider(),
      );

      // Second call with same key should succeed without throwing
      await FeedbackOS.instance.initialize(
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
      await FeedbackOS.instance.initialize(
        publishableKey: testKey,
        deviceIdStore: inMemoryDeviceStore,
        submissionStore: inMemorySubmissionStore,
        httpClient: mockHttpClient,
        deviceInfoProvider: const StaticDeviceInfoProvider(),
      );

      expect(
        () => FeedbackOS.instance.initialize(
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
      await FeedbackOS.instance.initialize(
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
      await FeedbackOS.instance.initialize(
        publishableKey: testKey,
        deviceIdStore: inMemoryDeviceStore,
        submissionStore: inMemorySubmissionStore,
        httpClient: mockHttpClient,
        deviceInfoProvider: const StaticDeviceInfoProvider(),
        options: FeedbackOSOptions(maxOfflineQueueSize: 1),
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
  });
}
