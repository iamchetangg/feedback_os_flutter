import 'package:equatable/equatable.dart';

/// Base Failure class representing domain failures.
abstract class Failure extends Equatable {
  final String message;
  final String? code;
  final int? statusCode;

  const Failure(this.message, {this.code, this.statusCode});

  @override
  List<Object?> get props => [message, code, statusCode];
}

final class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.statusCode})
      : super(code: 'network_error');
}

final class AuthenticationFailure extends Failure {
  const AuthenticationFailure(
    super.message, {
    super.code = 'invalid_key',
    super.statusCode = 401,
  });
}

final class SubscriptionFailure extends Failure {
  const SubscriptionFailure(
    super.message, {
    super.code = 'subscription_required',
    super.statusCode = 402,
  });
}

final class ValidationFailure extends Failure {
  const ValidationFailure(
    super.message, {
    super.code = 'invalid_request',
    super.statusCode = 400,
  });
}

final class RateLimitFailure extends Failure {
  final Duration? retryAfter;

  const RateLimitFailure(
    super.message, {
    super.statusCode = 429,
    this.retryAfter,
  }) : super(code: 'rate_limited');

  @override
  List<Object?> get props => [...super.props, retryAfter];
}

final class PayloadTooLargeFailure extends Failure {
  const PayloadTooLargeFailure(
    super.message, {
    super.statusCode = 413,
  }) : super(code: 'payload_too_large');
}

final class UploadNotFoundFailure extends Failure {
  const UploadNotFoundFailure(
    super.message, {
    super.statusCode = 404,
  }) : super(code: 'upload_not_found');
}

final class UploadInvalidFailure extends Failure {
  const UploadInvalidFailure(
    super.message, {
    super.statusCode = 422,
  }) : super(code: 'upload_invalid');
}

final class StorageFailure extends Failure {
  const StorageFailure(super.message) : super(code: 'storage_error');
}

final class FeatureDisabledFailure extends Failure {
  const FeatureDisabledFailure(
    super.message, {
    super.code = 'feature_disabled',
    super.statusCode = 403,
  });
}

final class ServerFailure extends Failure {
  const ServerFailure(
    super.message, {
    super.code = 'internal_error',
    super.statusCode = 500,
  });
}
