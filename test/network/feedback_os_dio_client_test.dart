import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';
import 'package:feedback_os_flutter/src/core/network/api_endpoints.dart';
import 'package:feedback_os_flutter/src/core/network/feedback_os_dio_client.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late MockDio mockDio;
  late FeedbackOsDioClient client;
  const testKey = 'fos_pk_test_12345';
  const testDeviceId = '11111111-2222-3333-4444-555555555555';

  setUp(() {
    mockDio = MockDio();
    registerFallbackValue(RequestOptions(path: ''));
    registerFallbackValue(Options());

    client = FeedbackOsDioClient(
      publishableKey: testKey,
      getDeviceId: () async => testDeviceId,
      options: FeedbackOSOptions.staging(),
      customDio: mockDio,
    );
  });

  group('FeedbackOsDioClient Header Handling', () {
    test('injects exact SDK headers on authenticated requests', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/sdk/ping'),
          statusCode: 200,
          data: {'ok': true, 'app_id': 'uuid'},
        ),
      );

      await client.get<Map<String, dynamic>>('/v1/sdk/ping');

      final captured = verify(
        () => mockDio.get<Map<String, dynamic>>(
          '/v1/sdk/ping',
          queryParameters: any(named: 'queryParameters'),
          options: captureAny(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).captured;

      final options = captured.first as Options;
      expect(options.headers?[ApiEndpoints.headerApiKey], equals(testKey));
      expect(options.headers?[ApiEndpoints.headerDevice], equals(testDeviceId));
    });

    test('omits SDK headers when includeAuthHeaders is false', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '/v1/sdk/config/key'),
          statusCode: 200,
          data: {'app_id': 'uuid'},
        ),
      );

      await client.get<Map<String, dynamic>>(
        '/v1/sdk/config/key',
        includeAuthHeaders: false,
      );

      final captured = verify(
        () => mockDio.get<Map<String, dynamic>>(
          '/v1/sdk/config/key',
          queryParameters: any(named: 'queryParameters'),
          options: captureAny(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).captured;

      final options = captured.first as Options;
      expect(options.headers?[ApiEndpoints.headerApiKey], isNull);
      expect(options.headers?[ApiEndpoints.headerDevice], isNull);
    });
  });

  group('FeedbackOsDioClient Error Mapping', () {
    test('maps 401 response with envelope to FeedbackOsAuthenticationException',
        () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/sdk/ping'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/sdk/ping'),
            statusCode: 401,
            data: {
              'error': {
                'code': 'invalid_key',
                'message': 'API key is missing or revoked',
              }
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => client.get<Map<String, dynamic>>('/v1/sdk/ping'),
        throwsA(isA<FeedbackOsAuthenticationException>()),
      );
    });

    test('maps 402 subscription required to FeedbackOsSubscriptionException',
        () async {
      when(
        () => mockDio.post<Map<String, dynamic>>(
          any(),
          data: any(named: 'data'),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/sdk/feedback'),
          response: Response(
            requestOptions: RequestOptions(path: '/v1/sdk/feedback'),
            statusCode: 402,
            data: {
              'error': {
                'code': 'subscription_required',
                'message': 'Trial expired',
              }
            },
          ),
          type: DioExceptionType.badResponse,
        ),
      );

      expect(
        () => client.post<Map<String, dynamic>>('/v1/sdk/feedback'),
        throwsA(isA<FeedbackOsSubscriptionException>()),
      );
    });

    test('maps connection timeout to FeedbackOsNetworkException', () async {
      when(
        () => mockDio.get<Map<String, dynamic>>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(
        DioException(
          requestOptions: RequestOptions(path: '/v1/sdk/ping'),
          type: DioExceptionType.connectionTimeout,
          message: 'Connection timed out',
        ),
      );

      expect(
        () => client.get<Map<String, dynamic>>('/v1/sdk/ping'),
        throwsA(isA<FeedbackOsNetworkException>()),
      );
    });
  });
}
