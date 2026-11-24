import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import '../../core/theme/theme.dart';
import '../core/network/api_endpoints.dart';

/// Configuration options for initializing the FeedbackOS SDK.
class FeedbackOSOptions extends Equatable {
  /// Base URL of the FeedbackOS API (e.g. `http://localhost:8787` or
  /// `http://10.0.2.2:8787` from the Android emulator).
  ///
  /// When `null`, the production API ([ApiEndpoints.productionBaseUrl]) is
  /// used. Read [resolvedBaseUrl] for the effective value. Both the HTTP
  /// client and the live notifications WebSocket derive from it.
  final Uri? baseUrl;

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

  /// Fallback short-polling interval for an open thread detail screen.
  ///
  /// Polling only runs while the live notifications socket is disconnected
  /// or disabled. Defaults to 4 seconds.
  final Duration threadPollingInterval;

  /// Whether to open a live WebSocket channel to receive creator replies and
  /// status changes in real time. Also requires realtime to be enabled for
  /// the project in the server SDK configuration. Defaults to `true`.
  final bool liveNotifications;

  /// Whether to show a lightweight in-app banner at the top of the screen
  /// when a live event arrives. Tapping it opens the related thread.
  /// Defaults to `false`.
  final bool showInAppNotificationBanner;

  /// Optional navigator key of the host app, used to show the in-app banner
  /// and to open threads from it. When omitted, the SDK looks up the root
  /// navigator of the app.
  final GlobalKey<NavigatorState>? navigatorKey;

  const FeedbackOSOptions({
    this.baseUrl,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 15),
    this.debugLogging = false,
    this.maxOfflineQueueSize = 500,
    this.queueItemTtl = const Duration(days: 7),
    this.theme = const FeedbackOSTheme(),
    this.threadPollingInterval = const Duration(seconds: 4),
    this.liveNotifications = true,
    this.showInAppNotificationBanner = false,
    this.navigatorKey,
  });

  /// The effective API base URL ([baseUrl] or the production URL).
  Uri get resolvedBaseUrl => baseUrl ?? ApiEndpoints.productionBaseUrl;

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
    bool? liveNotifications,
    bool? showInAppNotificationBanner,
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return FeedbackOSOptions(
      baseUrl: baseUrl ?? this.baseUrl,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      debugLogging: debugLogging ?? this.debugLogging,
      maxOfflineQueueSize: maxOfflineQueueSize ?? this.maxOfflineQueueSize,
      queueItemTtl: queueItemTtl ?? this.queueItemTtl,
      theme: theme ?? this.theme,
      threadPollingInterval:
          threadPollingInterval ?? this.threadPollingInterval,
      liveNotifications: liveNotifications ?? this.liveNotifications,
      showInAppNotificationBanner:
          showInAppNotificationBanner ?? this.showInAppNotificationBanner,
      navigatorKey: navigatorKey ?? this.navigatorKey,
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
        threadPollingInterval,
        liveNotifications,
        showInAppNotificationBanner,
        navigatorKey,
      ];
}
