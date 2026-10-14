import 'package:flutter_bloc/flutter_bloc.dart';
import '../domain/usecases/get_my_items_use_case.dart';
import '../domain/usecases/get_thread_detail_use_case.dart';
import '../domain/usecases/get_unread_count_use_case.dart';
import '../domain/usecases/mark_thread_read_use_case.dart';
import '../domain/usecases/send_reply_use_case.dart';
import 'threads_event.dart';
import 'threads_state.dart';

class ThreadsBloc extends Bloc<ThreadsEvent, ThreadsState> {
  final GetMyItemsUseCase _getMyItemsUseCase;
  final GetThreadDetailUseCase _getThreadDetailUseCase;
  final GetUnreadCountUseCase _getUnreadCountUseCase;
  final SendReplyUseCase _sendReplyUseCase;
  final MarkThreadReadUseCase _markThreadReadUseCase;

  ThreadsBloc({
    required GetMyItemsUseCase getMyItemsUseCase,
    required GetThreadDetailUseCase getThreadDetailUseCase,
    required GetUnreadCountUseCase getUnreadCountUseCase,
    required SendReplyUseCase sendReplyUseCase,
    required MarkThreadReadUseCase markThreadReadUseCase,
    ThreadsState? initialState,
  })  : _getMyItemsUseCase = getMyItemsUseCase,
        _getThreadDetailUseCase = getThreadDetailUseCase,
        _getUnreadCountUseCase = getUnreadCountUseCase,
        _sendReplyUseCase = sendReplyUseCase,
        _markThreadReadUseCase = markThreadReadUseCase,
        super(initialState ?? const ThreadsState()) {
    on<MyItemsStarted>(_onMyItemsStarted);
    on<ThreadDetailStarted>(_onThreadDetailStarted);
    on<ThreadReplySubmitted>(_onThreadReplySubmitted);
    on<ThreadReadMarked>(_onThreadReadMarked);
  }

  Future<void> _onMyItemsStarted(
    MyItemsStarted event,
    Emitter<ThreadsState> emit,
  ) async {
    emit(state.copyWith(
      status: ThreadsStatus.loading,
      errorMessage: null,
    ));

    final itemsResult = await _getMyItemsUseCase();
    final unreadResult = await _getUnreadCountUseCase();

    final unreadCount = unreadResult.fold((_) => 0, (res) => res.count);

    itemsResult.fold(
      (failure) => emit(state.copyWith(
        status: ThreadsStatus.failure,
        errorMessage: failure.message,
      )),
      (items) => emit(state.copyWith(
        status: ThreadsStatus.success,
        items: items,
        unreadCount: unreadCount,
      )),
    );
  }

  Future<void> _onThreadDetailStarted(
    ThreadDetailStarted event,
    Emitter<ThreadsState> emit,
  ) async {
    emit(state.copyWith(
      status: ThreadsStatus.loading,
      errorMessage: null,
    ));

    final result = await _getThreadDetailUseCase(itemId: event.itemId);

    await result.fold(
      (failure) async {
        emit(state.copyWith(
          status: ThreadsStatus.failure,
          errorMessage: failure.message,
        ));
      },
      (detail) async {
        emit(state.copyWith(
          status: ThreadsStatus.success,
          selectedThread: detail,
        ));

        // Mark read asynchronously and update local unread state
        await _markThreadReadUseCase(itemId: event.itemId);
        final updatedItems = state.items.map((item) {
          if (item.id == event.itemId) {
            return item;
          }
          return item;
        }).toList();

        emit(state.copyWith(
          items: updatedItems,
          unreadCount: (state.unreadCount - 1).clamp(0, 999999),
        ));
      },
    );
  }

  Future<void> _onThreadReplySubmitted(
    ThreadReplySubmitted event,
    Emitter<ThreadsState> emit,
  ) async {
    if (state.selectedThread == null || state.isSendingReply) return;

    emit(state.copyWith(isSendingReply: true, errorMessage: null));

    final result = await _sendReplyUseCase(
      itemId: event.itemId,
      message: event.message,
    );

    result.fold(
      (failure) => emit(state.copyWith(
        isSendingReply: false,
        errorMessage: failure.message,
      )),
      (newReply) {
        final currentThread = state.selectedThread!;
        final updatedThread = currentThread.copyWith(
          replies: [...currentThread.replies, newReply],
        );
        emit(state.copyWith(
          isSendingReply: false,
          selectedThread: updatedThread,
        ));
      },
    );
  }

  Future<void> _onThreadReadMarked(
    ThreadReadMarked event,
    Emitter<ThreadsState> emit,
  ) async {
    await _markThreadReadUseCase(itemId: event.itemId);
  }
}
