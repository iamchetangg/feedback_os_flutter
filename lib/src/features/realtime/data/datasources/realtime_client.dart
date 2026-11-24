import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as ws_status;
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/feedback_os_event.dart';
import '../models/realtime_frame_parser.dart';

/// Opens a WebSocket channel to [uri] with the given handshake [headers].
///
/// Injectable so tests can supply a fake channel.
typedef RealtimeChannelFactory = WebSocketChannel Function(
  Uri uri,
  Map<String, String> headers,
);

/// Default mobile/desktop channel factory backed by `dart:io`.
WebSocketChannel defaultRealtimeChannelFactory(
  Uri uri,
  Map<String, String> headers,
) {
  return IOWebSocketChannel.connect(
    uri,
    headers: headers,
    connectTimeout: const Duration(seconds: 15),
  );
}

/// Derives the realtime stream URL (`ws://` / `wss://`) from the API base URL.
Uri buildRealtimeUri(Uri baseUrl) {
  final scheme = switch (baseUrl.scheme) {
    'https' || 'wss' => 'wss',
    _ => 'ws',
  };
  var basePath = baseUrl.path;
  while (basePath.endsWith('/')) {
    basePath = basePath.substring(0, basePath.length - 1);
  }
  return Uri(
    scheme: scheme,
    userInfo: baseUrl.userInfo.isEmpty ? null : baseUrl.userInfo,
    host: baseUrl.host,
    port: baseUrl.hasPort ? baseUrl.port : null,
    path: '$basePath${ApiEndpoints.meStream}',
  );
}

/// Low-level live notifications client.
///
/// Connects to `GET /v1/sdk/me/stream`, sends a text `ping` every
/// [pingInterval], parses JSON frames into [FeedbackOSEvent]s and reconnects
/// with exponential backoff plus jitter while [start]ed.
class RealtimeClient {
  final Uri _uri;
  final Future<Map<String, String>> Function() _headersProvider;
  final RealtimeChannelFactory _channelFactory;
  final Random _random;
  final void Function(String message)? _log;

  /// Interval between client `ping` frames (the server idle-closes silent
  /// sockets).
  final Duration pingInterval;

  /// First reconnect delay (before jitter).
  final Duration initialBackoff;

  /// Upper bound for reconnect delays.
  final Duration maxBackoff;

  /// After staying connected this long, the backoff resets to [initialBackoff].
  final Duration stableConnectionThreshold;

  /// Delay used when the server answers 503 (realtime disabled server-side)
  /// or 401 (bad key); retrying sooner is pointless.
  final Duration unavailableBackoff;

  /// Maximum time to wait for the WebSocket handshake.
  final Duration connectTimeout;

  /// Number of consecutive pings without any inbound frame after which the
  /// connection is considered dead and is recycled.
  final int maxUnansweredPings;

  final StreamController<FeedbackOSEvent> _events =
      StreamController<FeedbackOSEvent>.broadcast();
  final ValueNotifier<bool> _connected = ValueNotifier<bool>(false);

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  Timer? _stableTimer;

  bool _running = false;
  bool _disposed = false;
  int _generation = 0;
  int _attempt = 0;
  int _unansweredPings = 0;
  Duration? _lastScheduledDelay;

  RealtimeClient({
    required Uri uri,
    required Future<Map<String, String>> Function() headersProvider,
    RealtimeChannelFactory? channelFactory,
    Random? random,
    void Function(String message)? log,
    this.pingInterval = const Duration(seconds: 45),
    this.initialBackoff = const Duration(seconds: 1),
    this.maxBackoff = const Duration(minutes: 5),
    this.stableConnectionThreshold = const Duration(seconds: 60),
    this.unavailableBackoff = const Duration(minutes: 5),
    this.connectTimeout = const Duration(seconds: 20),
    this.maxUnansweredPings = 2,
  })  : _uri = uri,
        _headersProvider = headersProvider,
        _channelFactory = channelFactory ?? defaultRealtimeChannelFactory,
        _random = random ?? Random(),
        _log = log;

  /// The stream URL this client connects to.
  Uri get uri => _uri;

  /// Broadcast stream of parsed events. Survives reconnects; closed on
  /// [dispose].
  Stream<FeedbackOSEvent> get events => _events.stream;

  /// Whether the socket is currently open.
  ValueListenable<bool> get isConnected => _connected;

  /// Whether the client is started (connected or trying to reconnect).
  bool get isRunning => _running;

  @visibleForTesting
  int get reconnectAttempt => _attempt;

  @visibleForTesting
  Duration? get lastScheduledDelay => _lastScheduledDelay;

  @visibleForTesting
  bool get hasPendingReconnect => _reconnectTimer?.isActive ?? false;

  /// Starts connecting (no-op when already started).
  void start() {
    if (_disposed || _running) return;
    _running = true;
    unawaited(_connect());
  }

  /// Closes the socket and cancels any pending reconnect.
  Future<void> stop() async {
    _running = false;
    _generation++;
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _teardownChannel();
  }

  /// Stops the client and releases its stream and notifier.
  Future<void> dispose() async {
    if (_disposed) return;
    await stop();
    _disposed = true;
    await _events.close();
    _connected.dispose();
  }

  /// Computes the jittered delay for reconnect attempt number [attempt]
  /// ("equal jitter": half fixed, half random), capped at [maxBackoff].
  @visibleForTesting
  Duration computeBackoff(int attempt) {
    final capMs = maxBackoff.inMilliseconds;
    final exponent = attempt.clamp(0, 30);
    final baseMs =
        min(capMs, initialBackoff.inMilliseconds * pow(2, exponent).toInt());
    final half = baseMs ~/ 2;
    final jitter = half > 0 ? _random.nextInt(half + 1) : 0;
    return Duration(milliseconds: min(capMs, (baseMs - half) + jitter));
  }

  Future<void> _connect() async {
    final gen = ++_generation;
    final WebSocketChannel channel;
    try {
      final headers = await _headersProvider();
      if (!_isCurrent(gen)) return;
      _log?.call('Realtime: connecting to $_uri');
      channel = _channelFactory(_uri, headers);
      _channel = channel;
      await channel.ready.timeout(connectTimeout);
    } catch (error) {
      if (!_isCurrent(gen)) return;
      _log?.call('Realtime: connect failed ($error)');
      await _teardownChannel();
      _scheduleReconnect(_delayForError(error));
      return;
    }

    if (!_isCurrent(gen)) {
      unawaited(_closeQuietly(channel));
      return;
    }

    _subscription = channel.stream.listen(
      (frame) => _onFrame(frame, gen),
      onError: (Object error) => _onSocketClosed(gen, error),
      onDone: () => _onSocketClosed(gen, null),
      cancelOnError: true,
    );

    _unansweredPings = 0;
    _pingTimer = Timer.periodic(pingInterval, (_) => _sendPing(gen));
    _stableTimer = Timer(stableConnectionThreshold, () {
      if (_isCurrent(gen)) _attempt = 0;
    });
    _log?.call('Realtime: connected');
    _connected.value = true;
  }

  void _onFrame(Object? frame, int gen) {
    if (!_isCurrent(gen)) return;
    _unansweredPings = 0;
    final event = parseRealtimeFrame(frame);
    if (event != null && !_events.isClosed) {
      _events.add(event);
    }
  }

  void _sendPing(int gen) {
    if (!_isCurrent(gen)) return;
    if (_unansweredPings >= maxUnansweredPings) {
      _log?.call('Realtime: no response to pings, recycling connection');
      _onSocketClosed(gen, null);
      return;
    }
    _unansweredPings++;
    try {
      _channel?.sink.add('ping');
    } catch (_) {
      // Sink already closed: onDone will handle the reconnect.
    }
  }

  void _onSocketClosed(int gen, Object? error) {
    if (!_isCurrent(gen)) return;
    // Invalidate callbacks from this socket generation.
    _generation++;
    _log?.call(
      'Realtime: disconnected'
      '${error != null ? ' ($error)' : ''} code=${_channel?.closeCode}',
    );
    unawaited(_teardownChannel());
    _scheduleReconnect(_nextBackoff());
  }

  Duration _delayForError(Object error) {
    final status = _statusCodeOf(error);
    if (status == 503 || status == 401) return unavailableBackoff;
    return _nextBackoff();
  }

  Duration _nextBackoff() => computeBackoff(_attempt++);

  void _scheduleReconnect(Duration delay) {
    if (!_running || _disposed) return;
    _reconnectTimer?.cancel();
    _lastScheduledDelay = delay;
    _log?.call('Realtime: reconnecting in ${delay.inMilliseconds}ms');
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (_running && !_disposed) unawaited(_connect());
    });
  }

  Future<void> _teardownChannel() async {
    _pingTimer?.cancel();
    _pingTimer = null;
    _stableTimer?.cancel();
    _stableTimer = null;
    final sub = _subscription;
    _subscription = null;
    final channel = _channel;
    _channel = null;
    if (!_disposed) _connected.value = false;
    if (sub != null) unawaited(sub.cancel());
    if (channel != null) await _closeQuietly(channel);
  }

  Future<void> _closeQuietly(WebSocketChannel channel) async {
    try {
      await channel.sink.close(ws_status.normalClosure).timeout(
            const Duration(seconds: 2),
            onTimeout: () => null,
          );
    } catch (_) {}
  }

  bool _isCurrent(int gen) => _running && !_disposed && gen == _generation;

  /// Extracts the HTTP status of a failed upgrade. `dart:io` reports it as
  /// "..., HTTP status code: 503" in the exception text.
  static int? _statusCodeOf(Object error) {
    final match =
        RegExp(r'HTTP status code: (\d{3})').firstMatch(error.toString());
    return match == null ? null : int.tryParse(match.group(1)!);
  }
}
