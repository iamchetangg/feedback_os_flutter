import 'package:flutter/foundation.dart';
import 'entities/feedback_os_event.dart';

/// Bridge between the app-wide realtime channel and feature blocs.
///
/// Lets a bloc react to live events, know whether the socket is connected
/// (so it can fall back to polling), report which thread is on screen and
/// request an unread count resync after marking a thread read.
class RealtimeLink {
  /// Broadcast stream of live events. Survives reconnects.
  final Stream<FeedbackOSEvent> events;

  /// Whether the live socket is currently connected.
  final ValueListenable<bool> isConnected;

  /// Called after a thread was marked read on the server.
  final Future<void> Function() onThreadRead;

  /// Called when a thread detail screen starts/stops showing [itemId].
  final void Function(String itemId) onThreadWatched;
  final void Function(String itemId) onThreadUnwatched;

  const RealtimeLink({
    required this.events,
    required this.isConnected,
    required this.onThreadRead,
    required this.onThreadWatched,
    required this.onThreadUnwatched,
  });
}
