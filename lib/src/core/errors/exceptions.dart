/// Base exception class for all FeedbackOS SDK errors.
sealed class FeedbackOsException implements Exception {
  final String message;
  final String? code;
  final int? statusCode;
  final dynamic details;

  const FeedbackOsException(
    this.message, {
    this.code,
    this.statusCode,
    this.details,
  });

  @override
  String toString() =>
      'FeedbackOsException(code: $code, statusCode: $statusCode, message: $message)';
}

/// Thrown when network transport, DNS, or connectivity fails or times out.
final class FeedbackOsNetworkException extends FeedbackOsException {
  const FeedbackOsNetworkException(
    super.message, {
    super.statusCode,
    super.details,
  }) : super(code: 'network_error');
}

/// Thrown when authentication credentials (API key or device) fail (HTTP 401).
final class FeedbackOsAuthenticationException extends FeedbackOsException {
  const FeedbackOsAuthenticationException(
    super.message, {
    super.code = 'invalid_key',
    super.statusCode = 401,
    super.details,
  });
}

/// Thrown when account trial or subscription is expired/restricted (HTTP 402).
final class FeedbackOsSubscriptionException extends FeedbackOsException {
  const FeedbackOsSubscriptionException(
    super.message, {
    super.code = 'subscription_required',
    super.statusCode = 402,
    super.details,
  });
}

/// Thrown when client request payload is invalid or bounds exceeded (HTTP 400).
final class FeedbackOsValidationException extends FeedbackOsException {
  const FeedbackOsValidationException(
    super.message, {
    super.code = 'invalid_request',
    super.statusCode = 400,
    super.details,
  });
}

/// Thrown when client is rate limited (HTTP 429).
final class FeedbackOsRateLimitException extends FeedbackOsException {
  final Duration? retryAfter;

  const FeedbackOsRateLimitException(
    super.message, {
    super.statusCode = 429,
    super.details,
    this.retryAfter,
  }) : super(code: 'rate_limited');
}

/// Thrown when request body exceeds maximum allowed size (HTTP 413).
final class FeedbackOsPayloadTooLargeException extends FeedbackOsException {
  const FeedbackOsPayloadTooLargeException(
    super.message, {
    super.statusCode = 413,
    super.details,
  }) : super(code: 'payload_too_large');
}

/// Thrown when local persistent storage or secure storage fails.
final class FeedbackOsStorageException extends FeedbackOsException {
  const FeedbackOsStorageException(
    super.message, {
    super.details,
  }) : super(code: 'storage_error');
}

/// Thrown when an upload reservation is not found (HTTP 404).
final class FeedbackOsUploadNotFoundException extends FeedbackOsException {
  const FeedbackOsUploadNotFoundException(
    super.message, {
    super.code = 'upload_not_found',
    super.statusCode = 404,
    super.details,
  });
}

/// Thrown when an uploaded file is invalid or corrupt (HTTP 422).
final class FeedbackOsUploadInvalidException extends FeedbackOsException {
  const FeedbackOsUploadInvalidException(
    super.message, {
    super.code = 'upload_invalid',
    super.statusCode = 422,
    super.details,
  });
}

/// Thrown when server responds with 5xx or unhandled status codes.
final class FeedbackOsServerException extends FeedbackOsException {
  const FeedbackOsServerException(
    super.message, {
    super.code = 'internal_error',
    super.statusCode = 500,
    super.details,
  });
}

