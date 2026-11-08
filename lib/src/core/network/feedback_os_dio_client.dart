import 'package:dio/dio.dart';
import '../../config/feedback_os_options.dart';
import '../errors/exceptions.dart';
import '../../features/feedback/data/models/api_error_model.dart';
import 'api_endpoints.dart';

/// Contract for FeedbackOS HTTP client operations.
abstract interface class FeedbackOsHttpClient {
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool includeAuthHeaders = true,
  });

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool includeAuthHeaders = true,
  });

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool includeAuthHeaders = true,
  });
}

/// Dio implementation of FeedbackOsHttpClient.
class FeedbackOsDioClient implements FeedbackOsHttpClient {
  final Dio _dio;
  final String _publishableKey;
  final Future<String> Function() _getDeviceId;
  final FeedbackOSOptions _options;

  FeedbackOsDioClient({
    required String publishableKey,
    required Future<String> Function() getDeviceId,
    required FeedbackOSOptions options,
    Dio? customDio,
  })  : _publishableKey = publishableKey,
        _getDeviceId = getDeviceId,
        _options = options,
        _dio = customDio ??
            Dio(
              BaseOptions(
                baseUrl: ApiEndpoints.productionBaseUrl.toString(),
                connectTimeout: options.connectTimeout,
                receiveTimeout: options.receiveTimeout,
                headers: {
                  'Accept': 'application/json',
                  'Content-Type': 'application/json',
                },
              ),
            );

  Future<Map<String, String>> _buildAuthHeaders() async {
    final deviceId = await _getDeviceId();
    return {
      ApiEndpoints.headerApiKey: _publishableKey,
      ApiEndpoints.headerDevice: deviceId,
    };
  }

  @override
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool includeAuthHeaders = true,
  }) async {
    try {
      final requestOptions = options ?? Options();
      if (includeAuthHeaders) {
        final authHeaders = await _buildAuthHeaders();
        requestOptions.headers = {
          ...?requestOptions.headers,
          ...authHeaders,
        };
      }

      return await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: requestOptions,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool includeAuthHeaders = true,
  }) async {
    try {
      final requestOptions = options ?? Options();
      if (includeAuthHeaders) {
        final authHeaders = await _buildAuthHeaders();
        requestOptions.headers = {
          ...?requestOptions.headers,
          ...authHeaders,
        };
      }

      return await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  @override
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    bool includeAuthHeaders = true,
  }) async {
    try {
      final requestOptions = options ?? Options();
      if (includeAuthHeaders) {
        final authHeaders = await _buildAuthHeaders();
        requestOptions.headers = {
          ...?requestOptions.headers,
          ...authHeaders,
        };
      }

      return await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: requestOptions,
        cancelToken: cancelToken,
      );
    } on DioException catch (e) {
      throw _handleDioException(e);
    }
  }

  /// Access the active options.
  FeedbackOSOptions get options => _options;

  FeedbackOsException _handleDioException(DioException e) {
    if (e.type == DioExceptionType.cancel) {
      return const FeedbackOsNetworkException('Request was cancelled',
          statusCode: 499);
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return FeedbackOsNetworkException(
        'Network error or timeout connecting to FeedbackOS server.',
        details: e.message,
      );
    }

    final response = e.response;
    if (response != null) {
      final statusCode = response.statusCode;
      Duration? retryAfter;
      final retryAfterHeader = response.headers.value('retry-after');
      if (retryAfterHeader != null) {
        final seconds = int.tryParse(retryAfterHeader);
        if (seconds != null) {
          retryAfter = Duration(seconds: seconds);
        }
      }

      if (response.data is Map<String, dynamic>) {
        try {
          final errorModel = ApiErrorModel.fromJson(
            response.data as Map<String, dynamic>,
          );
          return errorModel.toException(
            statusCode: statusCode,
            retryAfter: retryAfter,
          );
        } catch (_) {
          // If body parsing fails, fallback below
        }
      }

      return switch (statusCode) {
        401 => const FeedbackOsAuthenticationException(
            'Authentication failed. Invalid or revoked key.',
            statusCode: 401,
          ),
        402 => const FeedbackOsSubscriptionException(
            'FeedbackOS subscription required or expired.',
            statusCode: 402,
          ),
        400 => const FeedbackOsValidationException(
            'Invalid request payload.',
            statusCode: 400,
          ),
        413 => const FeedbackOsPayloadTooLargeException(
            'Request payload too large.',
            statusCode: 413,
          ),
        429 => FeedbackOsRateLimitException(
            'Too many requests. Please slow down.',
            statusCode: 429,
            retryAfter: retryAfter,
          ),
        _ => FeedbackOsServerException(
            'Server responded with HTTP $statusCode',
            statusCode: statusCode ?? 500,
            details: response.data,
          ),
      };
    }

    return FeedbackOsNetworkException(
      e.message ?? 'Unknown network failure occurred',
      details: e.error,
    );
  }
}
