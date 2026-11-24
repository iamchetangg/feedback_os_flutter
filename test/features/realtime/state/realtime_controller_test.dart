import 'package:fake_async/fake_async.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';
import 'package:feedback_os_flutter/src/features/realtime/data/datasources/realtime_client.dart';
import 'package:feedback_os_flutter/src/features/realtime/state/realtime_controller.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_web_socket_channel.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  group('RealtimeController', () {
    late FakeChannelFactory factory;
    late ValueNotifier<int> unread;
    late ValueNotifier<bool> connected;
    late List<FeedbackOSEvent> forwarded;
    late int serverUnread;
    late int fetchCalls;

    RealtimeController buildController() {
      final client = RealtimeClient(
        uri: Uri.parse('ws://localhost:8787/v1/sdk/me/stream'),
        headersProvider: () async => {},
        channelFactory: factory.call,
        random: MaxRandom(),
      );
      return RealtimeController(
        client: client,
        fetchUnreadCount: () async {
          fetchCalls++;
          return serverUnread;
        },
        unreadCount: unread,
        isConnected: connected,
        onEvent: forwarded.add,
        binding: binding,
      );
    }

    setUp(() {
      factory = FakeChannelFactory();
      unread = ValueNotifier<int>(0);
      connected = ValueNotifier<bool>(false);
      forwarded = [];
      serverUnread = 3;
      fetchCalls = 0;
      binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    });

    test('connects on start and reconciles unread count on connect', () {
      fakeAsync((async) {
        final controller = buildController()..start();
        async.flushMicrotasks();

        expect(factory.channels, hasLength(1));
        expect(connected.value, isTrue);
        expect(fetchCalls, 1);
        expect(unread.value, 3);

        controller.dispose();
        async.flushMicrotasks();
      });
    });

    test('closes on paused, reconnects and reconciles again on resumed', () {
      fakeAsync((async) {
        final controller = buildController()..start();
        async.flushMicrotasks();
        final first = factory.last;

        binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        async.flushMicrotasks();
        expect(first.sinkClosed, isTrue);
        expect(connected.value, isFalse);

        // No reconnect while backgrounded.
        async.elapse(const Duration(minutes: 10));
        expect(factory.channels, hasLength(1));

        serverUnread = 5;
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        async.flushMicrotasks();
        expect(factory.channels, hasLength(2));
        expect(connected.value, isTrue);
        expect(fetchCalls, 2);
        expect(unread.value, 5);

        controller.dispose();
        async.flushMicrotasks();
      });
    });

    test('inactive alone keeps the socket open', () {
      fakeAsync((async) {
        final controller = buildController()..start();
        async.flushMicrotasks();

        binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
        async.flushMicrotasks();
        expect(connected.value, isTrue);
        expect(factory.last.sinkClosed, isFalse);

        controller.dispose();
        async.flushMicrotasks();
      });
    });

    test('forwards events, increments unread, then resyncs (debounced)', () {
      fakeAsync((async) {
        final controller = buildController()..start();
        async.flushMicrotasks();
        expect(unread.value, 3);

        factory.last.serverSend({
          'type': 'reply.created',
          'item_id': 'it_1',
          'reply_id': 'r_1',
          'author_name': null,
          'preview': 'Hi',
          'created_at': '2026-11-25T10:00:00Z',
        });
        async.flushMicrotasks();
        expect(forwarded.single, isA<ReplyReceived>());
        expect(unread.value, 4);

        serverUnread = 4;
        async.elapse(const Duration(seconds: 2));
        expect(fetchCalls, 2);
        expect(unread.value, 4);

        controller.dispose();
        async.flushMicrotasks();
      });
    });

    test('dispose closes the socket and stops reacting to lifecycle', () {
      fakeAsync((async) {
        final controller = buildController()..start();
        async.flushMicrotasks();
        final channel = factory.last;

        controller.dispose();
        async.flushMicrotasks();
        expect(channel.sinkClosed, isTrue);
        expect(connected.value, isFalse);

        binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        async.flushMicrotasks();
        expect(factory.channels, hasLength(1));
        expect(async.pendingTimers, isEmpty);
      });
    });
  });
}
