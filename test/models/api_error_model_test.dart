import 'package:flutter_test/flutter_test.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';
import 'package:feedback_os_flutter/src/features/feedback/data/models/api_error_model.dart';

void main() {
  group('ApiErrorModel', () {
    test('parses nested error envelope', () {
      final json = {
        'error': {
          'code': 'invalid_key',
          'message': 'API key is missing or revoked',
          'details': null,
        }
      };

      final model = ApiErrorModel.fromJson(json);
      expect(model.code, equals('invalid_key'));
      expect(model.message, equals('API key is missing or revoked'));
      expect(model.details, isNull);
    });

    test('parses flat error structure gracefully', () {
      final json = {
        'code': 'subscription_required',
        'message': 'Account plan expired',
      };

      final model = ApiErrorModel.fromJson(json);
      expect(model.code, equals('subscription_required'));
      expect(model.message, equals('Account plan expired'));
    });

    test(
        'maps invalid_key to FeedbackOsAuthenticationException and AuthenticationFailure',
        () {
      const model = ApiErrorModel(
        code: 'invalid_key',
        message: 'Invalid key provided',
      );

      final exception = model.toException(statusCode: 401);
      expect(exception, isA<FeedbackOsAuthenticationException>());
      expect(exception.statusCode, equals(401));

      final failure = model.toFailure(statusCode: 401);
      expect(failure, isA<AuthenticationFailure>());
      expect(failure.statusCode, equals(401));
    });

    test('maps rate_limited with retryAfter', () {
      const model = ApiErrorModel(
        code: 'rate_limited',
        message: 'Too many requests',
      );

      const retryAfter = Duration(seconds: 30);
      final exception =
          model.toException(statusCode: 429, retryAfter: retryAfter);
      expect(exception, isA<FeedbackOsRateLimitException>());
      expect((exception as FeedbackOsRateLimitException).retryAfter,
          equals(retryAfter));

      final failure = model.toFailure(statusCode: 429, retryAfter: retryAfter);
      expect(failure, isA<RateLimitFailure>());
      expect((failure as RateLimitFailure).retryAfter, equals(retryAfter));
    });

    test('maps unknown codes gracefully to ServerException and ServerFailure',
        () {
      const model = ApiErrorModel(
        code: 'something_weird_from_backend',
        message: 'Something went wrong',
      );

      final exception = model.toException(statusCode: 500);
      expect(exception, isA<FeedbackOsServerException>());
      expect(exception.code, equals('something_weird_from_backend'));

      final failure = model.toFailure(statusCode: 500);
      expect(failure, isA<ServerFailure>());
      expect(failure.code, equals('something_weird_from_backend'));
    });
  });
}
