import 'package:fake_async/fake_async.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';
import 'package:feedback_os_flutter/src/features/realtime/data/datasources/realtime_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/fake_web_socket_channel.dart';

void main() {
  group('RealtimeClient', () {
    late FakeChannelFactory factory;

    RealtimeClient buildClient() => RealtimeClient(
          uri: Uri.parse('ws://localhost:8787/v1/sdk/me/stream'),
          headersProvider: () async => {
            'X-FeedbackOS-Key': 'fos_pk_test',
            'X-FeedbackOS-Device': 'device-1',
          },
          channelFactory: factory.call,
          random: MaxRandom(),
        );

    setUp(() {
      factory = FakeChannelFactory();
    });

    test('connects with auth headers and parses frames, ignoring unknown types',
        () {
      fakeAsync((async) {
        final client = buildClient();
        final received = <FeedbackOSEvent>[];
        client.events.listen(received.add);

        client.start();
        async.flushMicrotasks();

        expect(factory.channels, hasLength(1));
        expect(factory.headers.single, {
          'X-FeedbackOS-Key': 'fos_pk_test',
          'X-FeedbackOS-Device': 'device-1',
        });
        expect(client.isConnected.value, isTrue);

        factory.last.serverSend({'type': 'hello'});
        factory.last.serverSend({
          'type': 'reply.created',
          'item_id': 'it_1',
          'reply_id': 'r_1',
          'author_name': 'Jane',
          'preview': 'Hello',
          'created_at': '2026-11-25T10:00:00Z',
        });
        factory.last.serverSend({'type': 'something.new', 'item_id': 'x'});
        factory.last.serverSend('pong');
        factory.last.serverSend({
          'type': 'item.status_changed',
          'item_id': 'it_1',
          'from_status': 'open',
          'to_status': 'shipped',
          'created_at': '2026-11-25T10:00:00Z',
        });
        async.flushMicrotasks();

        expect(received, hasLength(2));
        expect(received[0], isA<ReplyReceived>());
        expect((received[1] as StatusChanged).toStatus, 'shipped');

        client.dispose();
        async.flushMicrotasks();
      });
    });

    test('sends a text ping every 45s while connected', () {
      fakeAsync((async) {
        final client = buildClient();
        client.start();
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 44));
        expect(factory.last.sent, isEmpty);

        async.elapse(const Duration(seconds: 1));
        expect(factory.last.sent, ['ping']);

        factory.last.serverSend('pong');
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 45));
        expect(factory.last.sent, ['ping', 'ping']);

        client.dispose();
        async.flushMicrotasks();
      });
    });

    test('recycles the connection when pings go unanswered', () {
      fakeAsync((async) {
        final client = buildClient();
        client.start();
        async.flushMicrotasks();
        final first = factory.last;

        // Two unanswered pings, then the third tick detects a dead socket.
        async.elapse(const Duration(seconds: 135));
        expect(first.sinkClosed, isTrue);
        expect(client.isConnected.value, isFalse);

        async.elapse(const Duration(seconds: 2));
        expect(factory.channels, hasLength(2));
        expect(client.isConnected.value, isTrue);

        client.dispose();
        async.flushMicrotasks();
      });
    });

    test('backoff grows exponentially with jitter and caps at 5 minutes', () {
      final client = buildClient();
      expect(client.computeBackoff(0), const Duration(seconds: 1));
      expect(client.computeBackoff(1), const Duration(seconds: 2));
      expect(client.computeBackoff(3), const Duration(seconds: 8));
      expect(client.computeBackoff(20), const Duration(minutes: 5));

      // Jitter keeps delays within [base/2, base].
      final jittered = RealtimeClient(
        uri: Uri.parse('ws://x'),
        headersProvider: () async => {},
        channelFactory: factory.call,
      );
      for (var i = 0; i < 50; i++) {
        final d = jittered.computeBackoff(4);
        expect(d.inMilliseconds, inInclusiveRange(8000, 16000));
      }
    });

    test('reconnects with increasing delays after connect failures', () {
      fakeAsync((async) {
        factory.connectError = Exception('connection refused');
        final client = buildClient();
        client.start();
        async.flushMicrotasks();

        expect(factory.channels, hasLength(1));
        expect(client.lastScheduledDelay, const Duration(seconds: 1));

        async.elapse(const Duration(seconds: 1));
        expect(factory.channels, hasLength(2));
        expect(client.lastScheduledDelay, const Duration(seconds: 2));

        async.elapse(const Duration(seconds: 2));
        expect(factory.channels, hasLength(3));
        expect(client.lastScheduledDelay, const Duration(seconds: 4));

        client.dispose();
        async.flushMicrotasks();
      });
    });

    test('backs off 5 minutes on HTTP 503', () {
      fakeAsync((async) {
        factory.connectError = Exception(
          "WebSocketException: Connection to 'ws://x' was not upgraded to "
          'websocket, HTTP status code: 503',
        );
        final client = buildClient();
        client.start();
        async.flushMicrotasks();

        expect(client.lastScheduledDelay, const Duration(minutes: 5));
        async.elapse(const Duration(minutes: 4, seconds: 59));
        expect(factory.channels, hasLength(1));
        async.elapse(const Duration(seconds: 1));
        expect(factory.channels, hasLength(2));

        client.dispose();
        async.flushMicrotasks();
      });
    });

    test('backoff resets after a stable connection', () {
      fakeAsync((async) {
        factory.connectError = Exception('down');
        final client = buildClient();
        client.start();
        async.flushMicrotasks();
        async.elapse(const Duration(seconds: 1)); // attempt 2
        async.elapse(const Duration(seconds: 2)); // attempt 3
        expect(client.reconnectAttempt, 3);

        factory.connectError = null;
        async.elapse(const Duration(seconds: 4));
        expect(client.isConnected.value, isTrue);

        // Stay connected past the stability threshold.
        factory.last.serverSend('pong');
        async.elapse(const Duration(seconds: 44));
        factory.last.serverSend('pong');
        async.elapse(const Duration(seconds: 20));
        expect(client.reconnectAttempt, 0);

        factory.last.serverClose();
        async.flushMicrotasks();
        expect(client.isConnected.value, isFalse);
        expect(client.lastScheduledDelay, const Duration(seconds: 1));

        client.dispose();
        async.flushMicrotasks();
      });
    });

    test('stop closes the socket and cancels pending reconnects', () {
      fakeAsync((async) {
        final client = buildClient();
        client.start();
        async.flushMicrotasks();
        final channel = factory.last;

        client.stop();
        async.flushMicrotasks();
        expect(channel.sinkClosed, isTrue);
        expect(client.isConnected.value, isFalse);
        expect(client.isRunning, isFalse);

        async.elapse(const Duration(minutes: 10));
        expect(factory.channels, hasLength(1));
        expect(async.pendingTimers, isEmpty);

        client.dispose();
        async.flushMicrotasks();
      });
    });
  });
}
