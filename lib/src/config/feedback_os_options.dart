import 'package:equatable/equatable.dart';
import '../../core/theme/theme.dart';
import '../core/network/api_endpoints.dart';

/// Configuration options for initializing the FeedbackOS SDK.
class FeedbackOSOptions extends Equatable {
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

  /// Periodic short-polling interval for active thread detail screen.
  /// Defaults to 4 seconds.
  final Duration threadPollingInterval;

  FeedbackOSOptions({
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 15),
    this.debugLogging = false,
    this.maxOfflineQueueSize = 500,
    this.queueItemTtl = const Duration(days: 7),
    this.theme = const FeedbackOSTheme(),
    this.threadPollingInterval = const Duration(seconds: 4),
  });

  /// Creates a copy of this configuration with the given fields replaced.
  FeedbackOSOptions copyWith({
    Uri? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    bool? debugLogging,
    int? maxOfflineQueueSize,
    Duration? queueItemTtl,
    FeedbackOSTheme? theme,
    Duration? threadPollingInterval,
  }) {
    return FeedbackOSOptions(
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      debugLogging: debugLogging ?? this.debugLogging,
      maxOfflineQueueSize: maxOfflineQueueSize ?? this.maxOfflineQueueSize,
      queueItemTtl: queueItemTtl ?? this.queueItemTtl,
      theme: theme ?? this.theme,
      threadPollingInterval:
          threadPollingInterval ?? this.threadPollingInterval,
    );
  }

  @override
  List<Object?> get props => [
        connectTimeout,
        receiveTimeout,
        debugLogging,
        maxOfflineQueueSize,
        queueItemTtl,
        theme,
        threadPollingInterval,
      ];
}
