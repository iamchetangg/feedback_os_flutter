import 'package:equatable/equatable.dart';
import '../../core/theme/theme.dart';
import '../core/network/api_endpoints.dart';

/// Configuration options for initializing the FeedbackOS SDK.
class FeedbackOSOptions extends Equatable {
  /// Base URL of the FeedbackOS API backend.
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

  /// User-defined colors and theming for the SDK UI components.
  final FeedbackOSTheme theme;

  FeedbackOSOptions({
    Uri? baseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 15),
    this.debugLogging = false,
    this.maxOfflineQueueSize = 500,
    this.queueItemTtl = const Duration(days: 7),
    this.theme = const FeedbackOSTheme(),
  }) : baseUrl = baseUrl ?? ApiEndpoints.productionBaseUrl;

  /// Factory constructor for staging environment.
  /// Uses the verified staging Cloudflare Worker endpoint.
  factory FeedbackOSOptions.staging({
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 15),
    bool debugLogging = false,
    FeedbackOSTheme theme = const FeedbackOSTheme(),
  }) {
    return FeedbackOSOptions(
      baseUrl: ApiEndpoints.stagingBaseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      debugLogging: debugLogging,
      theme: theme,
    );
  }

  /// Factory constructor for local development.
  factory FeedbackOSOptions.local({
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 15),
    bool debugLogging = true,
    FeedbackOSTheme theme = const FeedbackOSTheme(),
  }) {
    return FeedbackOSOptions(
      baseUrl: ApiEndpoints.localBaseUrl,
      connectTimeout: connectTimeout,
      receiveTimeout: receiveTimeout,
      debugLogging: debugLogging,
      theme: theme,
    );
  }

  /// Creates a copy of this configuration with the given fields replaced.
  FeedbackOSOptions copyWith({
    Uri? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    bool? debugLogging,
    int? maxOfflineQueueSize,
    Duration? queueItemTtl,
    FeedbackOSTheme? theme,
  }) {
    return FeedbackOSOptions(
      baseUrl: baseUrl ?? this.baseUrl,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      debugLogging: debugLogging ?? this.debugLogging,
      maxOfflineQueueSize: maxOfflineQueueSize ?? this.maxOfflineQueueSize,
      queueItemTtl: queueItemTtl ?? this.queueItemTtl,
      theme: theme ?? this.theme,
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
        theme,
      ];
}
