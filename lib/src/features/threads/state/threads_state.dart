import 'package:equatable/equatable.dart';
import '../domain/entities/my_feedback_item.dart';
import '../domain/entities/thread_detail.dart';

enum ThreadsStatus { initial, loading, success, failure }

class ThreadsState extends Equatable {
  final ThreadsStatus status;
  final List<MyFeedbackItem> items;
  final ThreadDetail? selectedThread;
  final int unreadCount;
  final bool isSendingReply;
  final String? errorMessage;

  const ThreadsState({
    this.status = ThreadsStatus.initial,
    this.items = const [],
    this.selectedThread,
    this.unreadCount = 0,
    this.isSendingReply = false,
    this.errorMessage,
  });

  ThreadsState copyWith({
    ThreadsStatus? status,
    List<MyFeedbackItem>? items,
    ThreadDetail? selectedThread,
    int? unreadCount,
    bool? isSendingReply,
    String? errorMessage,
  }) {
    return ThreadsState(
      status: status ?? this.status,
      items: items ?? this.items,
      selectedThread: selectedThread ?? this.selectedThread,
      unreadCount: unreadCount ?? this.unreadCount,
      isSendingReply: isSendingReply ?? this.isSendingReply,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        items,
        selectedThread,
        unreadCount,
        isSendingReply,
        errorMessage,
      ];
}
