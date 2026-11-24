import 'dart:async';

import 'package:flutter/widgets.dart';

import '../data/datasources/realtime_client.dart';
import '../domain/entities/feedback_os_event.dart';

/// App-wide owner of the live notifications socket.
///
/// - Connects while the app is in the foreground (`resumed`) and closes the
///   socket when it goes to the background (`paused` / `hidden`). A brief
///   `inactive` (e.g. a system dialog) keeps the socket open.
/// - Reconciles [unreadCount] with the server on every (re)connect, because
///   missed events are not replayed.
/// - Optimistically increments [unreadCount] on events, then resyncs it
///   shortly after (debounced) so it never drifts from the server value.
class RealtimeController with WidgetsBindingObserver {
  final RealtimeClient _client;
  final Future<int> Function() _fetchUnreadCount;
  final ValueNotifier<int> _unreadCount;
  final ValueNotifier<bool> _isConnected;
  final void Function(FeedbackOSEvent event) _onEvent;
  final WidgetsBinding? _bindingOverride;
  final Duration _reconcileDebounce;
  final void Function(String message)? _log;

  StreamSubscription<FeedbackOSEvent>? _eventSubscription;
  Timer? _reconcileTimer;
  bool _started = false;
  bool _disposed = false;

  RealtimeController({
    required RealtimeClient client,
    required Future<int> Function() fetchUnreadCount,
    required ValueNotifier<int> unreadCount,
    required ValueNotifier<bool> isConnected,
    required void Function(FeedbackOSEvent event) onEvent,
    WidgetsBinding? binding,
    Duration reconcileDebounce = const Duration(seconds: 2),
    void Function(String message)? log,
  })  : _client = client,
        _fetchUnreadCount = fetchUnreadCount,
        _unreadCount = unreadCount,
        _isConnected = isConnected,
        _onEvent = onEvent,
        _bindingOverride = binding,
        _reconcileDebounce = reconcileDebounce,
        _log = log;

  WidgetsBinding get _binding => _bindingOverride ?? WidgetsBinding.instance;

  /// The underlying socket client.
  RealtimeClient get client => _client;

  bool get isStarted => _started && !_disposed;

  /// Registers the lifecycle observer and connects if the app is foregrounded.
  void start() {
    if (_started || _disposed) return;
    _started = true;
    _binding.addObserver(this);
    _client.isConnected.addListener(_onConnectionChanged);
    _eventSubscription = _client.events.listen(_handleEvent);
    if (!_isBackground(_binding.lifecycleState)) {
      _client.start();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (_disposed) return;
    if (state == AppLifecycleState.resumed) {
      _client.start();
    } else if (_isBackground(state)) {
      unawaited(_client.stop());
    }
  }

  /// Fetches the server unread count and publishes it to [_unreadCount].
  Future<void> reconcileUnread() async {
    if (_disposed) return;
    _reconcileTimer?.cancel();
    _reconcileTimer = null;
    try {
      final count = await _fetchUnreadCount();
      if (!_disposed) _unreadCount.value = count;
    } catch (error) {
      _log?.call('Realtime: unread reconcile failed ($error)');
    }
  }

  /// Stops listening to lifecycle changes and closes the socket for good.
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    _reconcileTimer?.cancel();
    _reconcileTimer = null;
    if (_started) {
      _binding.removeObserver(this);
      _client.isConnected.removeListener(_onConnectionChanged);
    }
    final subscription = _eventSubscription;
    _eventSubscription = null;
    if (subscription != null) unawaited(subscription.cancel());
    _isConnected.value = false;
    await _client.dispose();
  }

  void _onConnectionChanged() {
    if (_disposed) return;
    final connected = _client.isConnected.value;
    _isConnected.value = connected;
    if (connected) unawaited(reconcileUnread());
  }

  void _handleEvent(FeedbackOSEvent event) {
    if (_disposed) return;
    _unreadCount.value = _unreadCount.value + 1;
    _onEvent(event);
    _reconcileTimer?.cancel();
    _reconcileTimer = Timer(_reconcileDebounce, () {
      unawaited(reconcileUnread());
    });
  }

  static bool _isBackground(AppLifecycleState? state) =>
      state == AppLifecycleState.paused ||
      state == AppLifecycleState.hidden ||
      state == AppLifecycleState.detached;
}
