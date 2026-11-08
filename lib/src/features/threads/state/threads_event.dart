import 'package:equatable/equatable.dart';

abstract class ThreadsEvent extends Equatable {
  const ThreadsEvent();

  @override
  List<Object?> get props => [];
}

class MyItemsStarted extends ThreadsEvent {
  const MyItemsStarted();
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

class ThreadPollingStarted extends ThreadsEvent {
  final String itemId;
  final Duration? interval;

  const ThreadPollingStarted(this.itemId, {this.interval});

  @override
  List<Object?> get props => [itemId, interval];
}

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
