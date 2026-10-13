import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';
import 'package:feedback_os_flutter/src/core/network/feedback_os_dio_client.dart';

class MockFeedbackOsHttpClient extends Mock implements FeedbackOsHttpClient {}

void main() {
  late MockFeedbackOsHttpClient mockHttpClient;
  late InMemoryDeviceIdStore inMemoryStore;
  const testKey = 'fos_pk_test_live_123';
  const testDeviceId = '12345678-1234-1234-1234-123456789abc';

  setUp(() async {
    mockHttpClient = MockFeedbackOsHttpClient();
    inMemoryStore = InMemoryDeviceIdStore(initialDeviceId: testDeviceId);
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
        deviceIdStore: inMemoryStore,
        httpClient: mockHttpClient,
      );

      expect(FeedbackOS.instance.isInitialized, isTrue);
      expect(FeedbackOS.instance.publishableKey, equals(testKey));
      expect(await FeedbackOS.instance.getDeviceId(), equals(testDeviceId));
    });

    test('calling initialize repeatedly with identical key is idempotent',
        () async {
      await FeedbackOS.instance.initialize(
        publishableKey: testKey,
        deviceIdStore: inMemoryStore,
        httpClient: mockHttpClient,
      );

      // Second call with same key should succeed without throwing
      await FeedbackOS.instance.initialize(
        publishableKey: testKey,
        deviceIdStore: inMemoryStore,
        httpClient: mockHttpClient,
      );

      expect(FeedbackOS.instance.isInitialized, isTrue);
    });

    test('calling initialize with different key throws without reset()',
        () async {
      await FeedbackOS.instance.initialize(
        publishableKey: testKey,
        deviceIdStore: inMemoryStore,
        httpClient: mockHttpClient,
      );

      expect(
        () => FeedbackOS.instance.initialize(
          publishableKey: 'fos_pk_different_project_456',
          deviceIdStore: inMemoryStore,
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
        deviceIdStore: inMemoryStore,
        httpClient: mockHttpClient,
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
  });
}
