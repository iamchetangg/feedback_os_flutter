import 'package:equatable/equatable.dart';
import '../../realtime/domain/entities/feedback_os_event.dart';

abstract class ThreadsEvent extends Equatable {
  const ThreadsEvent();

  @override
  List<Object?> get props => [];
}

class MyItemsStarted extends ThreadsEvent {
  const MyItemsStarted();
}

/// Silently re-fetches "My requests" and the unread count (no loading state).
class MyItemsRefreshed extends ThreadsEvent {
  const MyItemsRefreshed();
}

class ThreadDetailStarted extends ThreadsEvent {
  final String itemId;

  const ThreadDetailStarted(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

class ThreadReplySubmitted extends ThreadsEvent {
  final String itemId;
  final String message;

  const ThreadReplySubmitted({
    required this.itemId,
    required this.message,
  });

  @override
  List<Object?> get props => [itemId, message];
}

class ThreadReadMarked extends ThreadsEvent {
  final String itemId;

  const ThreadReadMarked(this.itemId);

  @override
  List<Object?> get props => [itemId];
}

/// Starts watching [itemId] on the thread detail screen.
///
/// The thread refreshes on live events for [itemId]. Periodic polling every
/// [interval] only runs while the live socket is disconnected or disabled,
/// and starts/stops automatically as the connection state changes.
class ThreadPollingStarted extends ThreadsEvent {
  final String itemId;
  final Duration? interval;

  const ThreadPollingStarted(this.itemId, {this.interval});

  @override
  List<Object?> get props => [itemId, interval];
}

/// Stops watching the current thread (and any fallback polling).
class ThreadPollingStopped extends ThreadsEvent {
  const ThreadPollingStopped();
}

class ThreadDetailRefreshed extends ThreadsEvent {
  final String itemId;
  final bool isSilent;

  const ThreadDetailRefreshed(this.itemId, {this.isSilent = true});

  @override
  List<Object?> get props => [itemId, isSilent];
}

/// Internal: a live event arrived from the realtime channel.
class ThreadRealtimeEventReceived extends ThreadsEvent {
  final FeedbackOSEvent event;

  const ThreadRealtimeEventReceived(this.event);

  @override
  List<Object?> get props => [event];
}

/// Internal: the realtime socket connected or disconnected.
class ThreadRealtimeConnectionChanged extends ThreadsEvent {
  final bool isConnected;

  const ThreadRealtimeConnectionChanged(this.isConnected);

  @override
  List<Object?> get props => [isConnected];
}
