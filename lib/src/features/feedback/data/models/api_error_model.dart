import 'package:equatable/equatable.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';

class ApiErrorModel extends Equatable {
  final String code;
  final String message;
  final dynamic details;

  const ApiErrorModel({
    required this.code,
    required this.message,
    this.details,
  });

  factory ApiErrorModel.fromJson(Map<String, dynamic> json) {
    final errorObj = json['error'] is Map<String, dynamic>
        ? json['error'] as Map<String, dynamic>
        : json;

    return ApiErrorModel(
      code: errorObj['code']?.toString() ?? 'internal_error',
      message: errorObj['message']?.toString() ?? 'An unknown error occurred.',
      details: errorObj['details'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'error': {
        'code': code,
        'message': message,
        if (details != null) 'details': details,
      },
    };
  }

  /// Converts this model to a typed FeedbackOsException based on code & HTTP status.
  FeedbackOsException toException({int? statusCode, Duration? retryAfter}) {
    return switch (code) {
      'unauthorized' || 'invalid_key' => FeedbackOsAuthenticationException(
          message,
          code: code,
          statusCode: statusCode ?? 401,
          details: details,
        ),
      'subscription_required' => FeedbackOsSubscriptionException(
          message,
          code: code,
          statusCode: statusCode ?? 402,
          details: details,
        ),
      'invalid_request' => FeedbackOsValidationException(
          message,
          code: code,
          statusCode: statusCode ?? 400,
          details: details,
        ),
      'payload_too_large' => FeedbackOsPayloadTooLargeException(
          message,
          statusCode: statusCode ?? 413,
          details: details,
        ),
      'rate_limited' => FeedbackOsRateLimitException(
          message,
          statusCode: statusCode ?? 429,
          details: details,
          retryAfter: retryAfter,
        ),
      'upload_not_found' => FeedbackOsUploadNotFoundException(
          message,
          statusCode: statusCode ?? 404,
          details: details,
        ),
      'upload_invalid' => FeedbackOsUploadInvalidException(
          message,
          statusCode: statusCode ?? 422,
          details: details,
        ),
      _ => FeedbackOsServerException(
          message,
          code: code,
          statusCode: statusCode ?? 500,
          details: details,
        ),
    };
  }

  /// Converts this model to a domain Failure.
  Failure toFailure({int? statusCode, Duration? retryAfter}) {
    return switch (code) {
      'unauthorized' || 'invalid_key' => AuthenticationFailure(
          message,
          code: code,
          statusCode: statusCode ?? 401,
        ),
      'subscription_required' => SubscriptionFailure(
          message,
          code: code,
          statusCode: statusCode ?? 402,
        ),
      'invalid_request' => ValidationFailure(
          message,
          code: code,
          statusCode: statusCode ?? 400,
        ),
      'payload_too_large' => PayloadTooLargeFailure(
          message,
          statusCode: statusCode ?? 413,
        ),
      'rate_limited' => RateLimitFailure(
          message,
          statusCode: statusCode ?? 429,
          retryAfter: retryAfter,
        ),
      'upload_not_found' => UploadNotFoundFailure(
          message,
          statusCode: statusCode ?? 404,
        ),
      'upload_invalid' => UploadInvalidFailure(
          message,
          statusCode: statusCode ?? 422,
        ),
      _ => ServerFailure(
          message,
          code: code,
          statusCode: statusCode ?? 500,
        ),
    };
  }

  @override
  List<Object?> get props => [code, message, details];
}
