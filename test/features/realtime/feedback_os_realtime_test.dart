import 'package:dio/dio.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';
import 'package:feedback_os_flutter/src/core/network/api_endpoints.dart';
import 'package:feedback_os_flutter/src/core/network/feedback_os_dio_client.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'helpers/fake_web_socket_channel.dart';

class MockFeedbackOsHttpClient extends Mock implements FeedbackOsHttpClient {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockFeedbackOsHttpClient http;
  late FakeChannelFactory factory;
  const testKey = 'fos_pk_test_realtime';
  const deviceId = '12345678-1234-1234-1234-123456789abc';
  Map<String, dynamic>? realtimeConfig;
  late int serverUnread;

  Map<String, dynamic> configJson() => {
        'app_id': 'app_1',
        'config_version': 1,
        'enabled': true,
        'board': {'enabled': true},
        'roadmap': {'enabled': true},
        if (realtimeConfig != null) 'realtime': realtimeConfig,
      };

  Future<void> init({FeedbackOSOptions? options}) async {
    final store = InMemorySubmissionStore();
    await store.open();
    await FeedbackOS.instance.initializeTest(
      publishableKey: testKey,
      options: options,
      deviceIdStore: InMemoryDeviceIdStore(initialDeviceId: deviceId),
      deviceInfoProvider: const StaticDeviceInfoProvider(),
      submissionStore: store,
      httpClient: http,
      realtimeChannelFactory: factory.call,
    );
    await pumpEventQueue();
  }

  setUp(() async {
    await FeedbackOS.instance.reset();
    http = MockFeedbackOsHttpClient();
    factory = FakeChannelFactory();
    realtimeConfig = {'enabled': true};
    serverUnread = 2;
    WidgetsBinding.instance
        .handleAppLifecycleStateChanged(AppLifecycleState.resumed);

    when(
      () => http.get<Map<String, dynamic>>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
        cancelToken: any(named: 'cancelToken'),
        includeAuthHeaders: any(named: 'includeAuthHeaders'),
      ),
    ).thenAnswer((invocation) async {
      final path = invocation.positionalArguments.first as String;
      final data = path == ApiEndpoints.meUnread
          ? <String, dynamic>{'count': serverUnread}
          : configJson();
      return Response(
        requestOptions: RequestOptions(path: path),
        statusCode: 200,
        data: data,
      );
    });
    when(
      () => http.post<void>(
        any(),
        data: any(named: 'data'),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
        cancelToken: any(named: 'cancelToken'),
        includeAuthHeaders: any(named: 'includeAuthHeaders'),
      ),
    ).thenAnswer(
      (invocation) async => Response(
        requestOptions: RequestOptions(path: ApiEndpoints.identify),
        statusCode: 204,
      ),
    );
  });

  tearDown(() async {
    await FeedbackOS.instance.reset();
  });

  test('connects after initialize when realtime is enabled in config',
      () async {
    await init();

    expect(factory.channels, hasLength(1));
    expect(
      factory.uris.single.toString(),
      'wss://api.feedbackos.dev/v1/sdk/me/stream',
    );
    expect(factory.headers.single, {
      'X-FeedbackOS-Key': testKey,
      'X-FeedbackOS-Device': deviceId,
    });
    expect(FeedbackOS.instance.isLiveConnected.value, isTrue);
    expect(FeedbackOS.instance.unreadCount.value, 2);
  });

  test('uses the configured baseUrl for the stream URL', () async {
    await init(
      options: FeedbackOSOptions(baseUrl: Uri.parse('http://10.0.2.2:8787')),
    );
    expect(
      factory.uris.single.toString(),
      'ws://10.0.2.2:8787/v1/sdk/me/stream',
    );
  });

  test('exposes live events and resyncs unreadCount', () async {
    await init();
    final received = <FeedbackOSEvent>[];
    final sub = FeedbackOS.instance.events.listen(received.add);

    factory.last.serverSend({
      'type': 'reply.created',
      'item_id': 'it_1',
      'reply_id': 'r_1',
      'author_name': 'Jane',
      'preview': 'We shipped it',
      'created_at': '2026-11-25T10:00:00Z',
    });
    await pumpEventQueue();

    expect(received.single, isA<ReplyReceived>());
    // unreadCount is re-fetched from the server after a short debounce.
    await Future<void>.delayed(const Duration(milliseconds: 400));
    expect(FeedbackOS.instance.unreadCount.value, 2);
    await sub.cancel();
  });

  test('does not connect when realtime is absent from config', () async {
    realtimeConfig = null;
    await init();
    expect(factory.channels, isEmpty);
    expect(FeedbackOS.instance.realtimeController, isNull);
    expect(FeedbackOS.instance.isLiveConnected.value, isFalse);
  });

  test('does not connect when liveNotifications is false', () async {
    await init(options: const FeedbackOSOptions(liveNotifications: false));
    expect(factory.channels, isEmpty);
    verifyNever(
      () => http.get<Map<String, dynamic>>(
        ApiEndpoints.config(testKey),
        queryParameters: any(named: 'queryParameters'),
        options: any(named: 'options'),
        cancelToken: any(named: 'cancelToken'),
        includeAuthHeaders: any(named: 'includeAuthHeaders'),
      ),
    );
  });

  test('identify restarts the live connection', () async {
    await init();
    final first = factory.last;

    await FeedbackOS.instance.identify(externalUserId: 'user_42');
    await pumpEventQueue();

    expect(first.sinkClosed, isTrue);
    expect(factory.channels, hasLength(2));
    expect(FeedbackOS.instance.isLiveConnected.value, isTrue);
  });

  test('reset() closes the socket and clears live state', () async {
    await init();
    final channel = factory.last;
    expect(FeedbackOS.instance.realtimeController, isNotNull);

    await FeedbackOS.instance.reset();

    expect(channel.sinkClosed, isTrue);
    expect(FeedbackOS.instance.realtimeController, isNull);
    expect(FeedbackOS.instance.isLiveConnected.value, isFalse);
    expect(FeedbackOS.instance.unreadCount.value, 0);

    // The events stream stays usable across reset/initialize cycles.
    final received = <FeedbackOSEvent>[];
    final sub = FeedbackOS.instance.events.listen(received.add);
    await init();
    factory.last.serverSend({
      'type': 'item.status_changed',
      'item_id': 'it_1',
      'from_status': 'open',
      'to_status': 'shipped',
      'created_at': '2026-11-25T10:00:00Z',
    });
    await pumpEventQueue();
    expect(received.single, isA<StatusChanged>());
    await sub.cancel();
  });
}
