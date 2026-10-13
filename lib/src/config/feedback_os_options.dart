import 'package:equatable/equatable.dart';

/// Configuration options for initializing the FeedbackOS SDK.
class FeedbackOSOptions extends Equatable {
  /// Base URL of the FeedbackOS API backend.
  /// Defaults to production: `https://api.feedbackos.dev`.
  final Uri baseUrl;

  /// HTTP connect timeout. Defaults to 15 seconds.
  final Duration connectTimeout;

  /// HTTP receive timeout. Defaults to 15 seconds.
  final Duration receiveTimeout;

  /// Whether debug logging is enabled.
  /// Note: Sensitive data (keys, payloads, images) are never logged.
  final bool debugLogging;

  /// Maximum number of feedback items stored in the offline queue.
  /// Defaults to 500 items.
  final int maxOfflineQueueSize;

  /// Maximum age of queued items before expiry.
  /// Defaults to 7 days.
  final Duration queueItemTtl;

  static final Uri defaultProductionBaseUrl =
      Uri.parse('https://api.feedbackos.dev');

  static final Uri defaultStagingBaseUrl = Uri.parse(
    'https://feedbackos-api-staging.chetangaddam71.workers.dev',
  );

  static final Uri defaultLocalBaseUrl = Uri.parse('http://localhost:8787');

  FeedbackOSOptions({
    Uri? baseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 15),
    this.debugLogging = false,
    this.maxOfflineQueueSize = 500,
    this.queueItemTtl = const Duration(days: 7),
  }) : baseUrl = baseUrl ?? defaultProductionBaseUrl;

  /// Factory constructor for staging environment.
  /// Uses the verified staging Cloudflare Worker endpoint.
  factory FeedbackOSOptions.staging({
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 15),
    bool debugLogging = false,
  }) {
    return FeedbackOSOptions(
      baseUrl: defaultStagingBaseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      debugLogging: debugLogging,
    );
  }

  /// Factory constructor for local development.
  factory FeedbackOSOptions.local({
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 15),
    bool debugLogging = true,
  }) {
    return FeedbackOSOptions(
      baseUrl: defaultLocalBaseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      debugLogging: debugLogging,
    );
  }

  @override
  List<Object?> get props => [
        baseUrl,
        connectTimeout,
        receiveTimeout,
        debugLogging,
        maxOfflineQueueSize,
        queueItemTtl,
      ];
}
