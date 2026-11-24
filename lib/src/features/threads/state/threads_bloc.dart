import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../realtime/domain/entities/feedback_os_event.dart';
import '../../realtime/domain/realtime_link.dart';
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

  final RealtimeLink? _realtime;

  Timer? _pollingTimer;
  StreamSubscription<FeedbackOSEvent>? _realtimeSubscription;

  /// Thread currently shown on a detail screen (set by [ThreadPollingStarted]).
  String? _watchedItemId;
  Duration _pollingInterval = const Duration(seconds: 4);

  /// Whether "My requests" has been loaded by this bloc (and should therefore
  /// refresh on live events).
  bool _myItemsLoaded = false;

  ThreadsBloc({
    required GetMyItemsUseCase getMyItemsUseCase,
    required GetThreadDetailUseCase getThreadDetailUseCase,
    required GetUnreadCountUseCase getUnreadCountUseCase,
    required SendReplyUseCase sendReplyUseCase,
    required MarkThreadReadUseCase markThreadReadUseCase,
    RealtimeLink? realtime,
    ThreadsState? initialState,
  })  : _realtime = realtime,
        _getMyItemsUseCase = getMyItemsUseCase,
        _getThreadDetailUseCase = getThreadDetailUseCase,
        _getUnreadCountUseCase = getUnreadCountUseCase,
        _sendReplyUseCase = sendReplyUseCase,
        _markThreadReadUseCase = markThreadReadUseCase,
        super(initialState ?? const ThreadsState()) {
    on<MyItemsStarted>(_onMyItemsStarted);
    on<ThreadDetailStarted>(_onThreadDetailStarted);
    on<ThreadReplySubmitted>(_onThreadReplySubmitted);
    on<ThreadReadMarked>(_onThreadReadMarked);
    on<ThreadPollingStarted>(_onThreadPollingStarted);
    on<ThreadPollingStopped>(_onThreadPollingStopped);
    on<ThreadDetailRefreshed>(_onThreadDetailRefreshed);
    on<MyItemsRefreshed>(_onMyItemsRefreshed);
    on<ThreadRealtimeEventReceived>(_onRealtimeEventReceived);
    on<ThreadRealtimeConnectionChanged>(_onRealtimeConnectionChanged);

    final realtime = _realtime;
    if (realtime != null) {
      _realtimeSubscription = realtime.events.listen((event) {
        if (!isClosed) add(ThreadRealtimeEventReceived(event));
      });
      realtime.isConnected.addListener(_onRealtimeConnectivity);
    }
  }

  bool get _isLive => _realtime?.isConnected.value ?? false;

  void _onRealtimeConnectivity() {
    if (!isClosed) {
      add(ThreadRealtimeConnectionChanged(_realtime!.isConnected.value));
    }
  }

  Future<void> _notifyThreadRead() async {
    try {
      await _realtime?.onThreadRead();
    } catch (_) {}
  }

  Future<void> _onMyItemsStarted(
    MyItemsStarted event,
    Emitter<ThreadsState> emit,
  ) async {
    _myItemsLoaded = true;
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
    // 1. Optimistically clear unread status on the selected item in local items
    bool wasUnread = false;
    final updatedItems = state.items.map((item) {
      if (item.id == event.itemId) {
        if (item.hasUnread) wasUnread = true;
        return item.copyWith(hasUnread: false);
      }
      return item;
    }).toList();

    emit(state.copyWith(
      status: ThreadsStatus.loading,
      errorMessage: null,
      items: updatedItems,
      unreadCount: wasUnread
          ? (state.unreadCount - 1).clamp(0, 999999)
          : state.unreadCount,
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

        // Mark read asynchronously on server, then resync the global
        // unread counter with the server value.
        await _markThreadReadUseCase(itemId: event.itemId);
        await _notifyThreadRead();
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

        // Re-fetch immediately to sync status and timestamps with server
        add(ThreadDetailRefreshed(event.itemId, isSilent: true));
      },
    );
  }

  Future<void> _onThreadReadMarked(
    ThreadReadMarked event,
    Emitter<ThreadsState> emit,
  ) async {
    bool wasUnread = false;
    final updatedItems = state.items.map((item) {
      if (item.id == event.itemId) {
        if (item.hasUnread) wasUnread = true;
        return item.copyWith(hasUnread: false);
      }
      return item;
    }).toList();

    emit(state.copyWith(
      items: updatedItems,
      unreadCount: wasUnread
          ? (state.unreadCount - 1).clamp(0, 999999)
          : state.unreadCount,
    ));

    await _markThreadReadUseCase(itemId: event.itemId);
    await _notifyThreadRead();
  }

  void _onThreadPollingStarted(
    ThreadPollingStarted event,
    Emitter<ThreadsState> emit,
  ) {
    final previous = _watchedItemId;
    if (previous != event.itemId) {
      if (previous != null) _realtime?.onThreadUnwatched(previous);
      _realtime?.onThreadWatched(event.itemId);
    }
    _watchedItemId = event.itemId;
    _pollingInterval = event.interval ?? const Duration(seconds: 4);
    _syncPollingTimer();
  }

  void _onThreadPollingStopped(
    ThreadPollingStopped event,
    Emitter<ThreadsState> emit,
  ) {
    _stopWatching();
  }

  void _stopWatching() {
    final previous = _watchedItemId;
    _watchedItemId = null;
    if (previous != null) _realtime?.onThreadUnwatched(previous);
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /// Polls the watched thread only while the live socket is not connected.
  void _syncPollingTimer() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    final itemId = _watchedItemId;
    if (itemId == null || _isLive) return;
    _pollingTimer = Timer.periodic(_pollingInterval, (_) {
      if (!isClosed) {
        add(ThreadDetailRefreshed(itemId, isSilent: true));
      }
    });
  }

  bool get isPolling => _pollingTimer?.isActive ?? false;

  void _onRealtimeConnectionChanged(
    ThreadRealtimeConnectionChanged event,
    Emitter<ThreadsState> emit,
  ) {
    _syncPollingTimer();
    final itemId = _watchedItemId;
    if (event.isConnected && itemId != null) {
      // Events are not replayed: catch up on anything missed while offline.
      add(ThreadDetailRefreshed(itemId, isSilent: true));
    }
  }

  Future<void> _onRealtimeEventReceived(
    ThreadRealtimeEventReceived event,
    Emitter<ThreadsState> emit,
  ) async {
    final itemId = event.event.itemId;
    if (itemId == _watchedItemId) {
      // The user is looking at this thread: refresh it and keep it read.
      add(ThreadDetailRefreshed(itemId, isSilent: true));
      await _markThreadReadUseCase(itemId: itemId);
      await _notifyThreadRead();
    }
    if (_myItemsLoaded && !isClosed) {
      add(const MyItemsRefreshed());
    }
  }

  Future<void> _onMyItemsRefreshed(
    MyItemsRefreshed event,
    Emitter<ThreadsState> emit,
  ) async {
    final itemsResult = await _getMyItemsUseCase();
    final unreadResult = await _getUnreadCountUseCase();

    itemsResult.fold(
      (_) {},
      (items) => emit(state.copyWith(
        status: ThreadsStatus.success,
        items: items,
        unreadCount:
            unreadResult.fold((_) => state.unreadCount, (r) => r.count),
      )),
    );
  }

  Future<void> _onThreadDetailRefreshed(
    ThreadDetailRefreshed event,
    Emitter<ThreadsState> emit,
  ) async {
    if (!event.isSilent) {
      emit(state.copyWith(
        status: ThreadsStatus.loading,
        errorMessage: null,
      ));
    }

    final result = await _getThreadDetailUseCase(itemId: event.itemId);

    result.fold(
      (failure) {
        if (!event.isSilent) {
          emit(state.copyWith(
            status: ThreadsStatus.failure,
            errorMessage: failure.message,
          ));
        }
      },
      (detail) {
        emit(state.copyWith(
          selectedThread: detail,
          status: ThreadsStatus.success,
        ));
      },
    );
  }

  @override
  Future<void> close() async {
    _stopWatching();
    _realtime?.isConnected.removeListener(_onRealtimeConnectivity);
    final subscription = _realtimeSubscription;
    _realtimeSubscription = null;
    if (subscription != null) unawaited(subscription.cancel());
    return super.close();
  }
}
