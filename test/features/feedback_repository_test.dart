import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';
import 'package:feedback_os_flutter/src/features/feedback/data/datasources/feedback_remote_data_source.dart';
import 'package:feedback_os_flutter/src/features/feedback/data/models/feedback_item_model.dart';
import 'package:feedback_os_flutter/src/features/feedback/data/models/feedback_submission_model.dart';
import 'package:feedback_os_flutter/src/features/feedback/data/models/sdk_config_model.dart';
import 'package:feedback_os_flutter/src/features/feedback/data/models/sdk_ping_model.dart';
import 'package:feedback_os_flutter/src/features/feedback/data/repositories/feedback_repository_impl.dart';

class MockFeedbackRemoteDataSource extends Mock
    implements FeedbackRemoteDataSource {}

void main() {
  late MockFeedbackRemoteDataSource mockDataSource;
  late FeedbackRepositoryImpl repository;

  setUpAll(() {
    registerFallbackValue(
      const FeedbackSubmissionModel(
        clientSubmissionId: 'fallback_id_1234',
        type: FeedbackType.bug,
        title: 'Title',
        device: FeedbackDeviceInfo(
          osVersion: 'os',
          appVersion: 'app',
          deviceModel: 'model',
        ),
      ),
    );
  });

  setUp(() {
    mockDataSource = MockFeedbackRemoteDataSource();
    repository = FeedbackRepositoryImpl(remoteDataSource: mockDataSource);
  });

  group('FeedbackRepository.getConfig', () {
    const testKey = 'fos_pk_test_123';
    const testConfigModel = SdkConfigModel(
      appId: '1c0e8260-63ee-4213-a70d-f06f88da777c',
      configVersion: 1,
      enabled: true,
      board: SdkBoardConfigModel(enabled: true),
      roadmap: SdkRoadmapConfigModel(enabled: true),
      categories: ['UI'],
      statuses: ['open'],
      limits: SdkLimitsConfigModel(
        maxScreenshots: 3,
        maxScreenshotBytes: 5000000,
        screenshotTypes: ['image/png'],
      ),
    );

    test('returns Right(SdkConfig) on success', () async {
      when(() => mockDataSource.getConfig(testKey,
              cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => testConfigModel);

      final result = await repository.getConfig(testKey);

      expect(result.isRight(), isTrue);
      result.match(
        (failure) => fail('Expected Right, got $failure'),
        (config) {
          expect(config.appId, equals('1c0e8260-63ee-4213-a70d-f06f88da777c'));
          expect(config.enabled, isTrue);
        },
      );
    });

    test('returns Left(AuthenticationFailure) on invalid key exception',
        () async {
      when(() => mockDataSource.getConfig(testKey,
          cancelToken: any(named: 'cancelToken'))).thenThrow(
        const FeedbackOsAuthenticationException(
          'Invalid publishable key',
          code: 'invalid_key',
          statusCode: 401,
        ),
      );

      final result = await repository.getConfig(testKey);

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) {
          expect(failure, isA<AuthenticationFailure>());
          expect(failure.message, equals('Invalid publishable key'));
        },
        (_) => fail('Expected Left, got Right'),
      );
    });
  });

  group('FeedbackRepository.ping', () {
    test('returns Right(SdkPingResult) on success', () async {
      const pingModel = SdkPingModel(
        ok: true,
        appId: '1c0e8260-63ee-4213-a70d-f06f88da777c',
      );

      when(() => mockDataSource.ping(cancelToken: any(named: 'cancelToken')))
          .thenAnswer((_) async => pingModel);

      final result = await repository.ping();

      expect(result.isRight(), isTrue);
      result.match(
        (failure) => fail('Expected Right'),
        (ping) {
          expect(ping.ok, isTrue);
          expect(ping.appId, equals('1c0e8260-63ee-4213-a70d-f06f88da777c'));
        },
      );
    });
  });

  group('FeedbackRepository.identify', () {
    test('returns Right(null) on 204 success', () async {
      when(() => mockDataSource.identify(any(),
          cancelToken: any(named: 'cancelToken'))).thenAnswer((_) async {});

      final result = await repository.identify('user_123');

      expect(result.isRight(), isTrue);
    });

    test('returns Left(ValidationFailure) on 400 invalid request', () async {
      when(() => mockDataSource.identify(any(),
          cancelToken: any(named: 'cancelToken'))).thenThrow(
        const FeedbackOsValidationException('external_user_id too long',
            statusCode: 400),
      );

      final result = await repository.identify('user_123');

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, isA<ValidationFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });

  group('FeedbackRepository.submitFeedback', () {
    const testSubmission = FeedbackSubmission(
      clientSubmissionId: 'sub_test_12345678',
      type: FeedbackType.bug,
      title: 'Crash on tap',
      device: FeedbackDeviceInfo(
        osVersion: 'Android 14',
        appVersion: '1.0.0',
        deviceModel: 'Pixel 8',
      ),
    );

    final expectedItem = FeedbackItemModel(
      id: '1c0e8260-63ee-4213-a70d-f06f88da777c',
      type: FeedbackType.bug,
      title: 'Crash on tap',
      description: '',
      category: null,
      status: 'open',
      isPublic: false,
      createdAt: DateTime.utc(2026, 10, 13, 12),
    );

    test('returns Right(FeedbackItem) on successful submission', () async {
      when(
        () => mockDataSource.submitFeedback(
          any(),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenAnswer((_) async => expectedItem);

      final result = await repository.submitFeedback(testSubmission);

      expect(result.isRight(), isTrue);
      result.match(
        (failure) => fail('Expected Right'),
        (item) {
          expect(item.id, equals('1c0e8260-63ee-4213-a70d-f06f88da777c'));
          expect(item.type, equals(FeedbackType.bug));
          expect(item.title, equals('Crash on tap'));
        },
      );
    });

    test('returns Left(AuthenticationFailure) on 401', () async {
      when(
        () => mockDataSource.submitFeedback(
          any(),
          cancelToken: any(named: 'cancelToken'),
        ),
      ).thenThrow(
        const FeedbackOsAuthenticationException('Invalid key', statusCode: 401),
      );

      final result = await repository.submitFeedback(testSubmission);

      expect(result.isLeft(), isTrue);
      result.match(
        (failure) => expect(failure, isA<AuthenticationFailure>()),
        (_) => fail('Expected Left'),
      );
    });
  });
}
