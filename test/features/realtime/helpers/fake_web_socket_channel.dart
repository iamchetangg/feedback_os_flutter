import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:mocktail/mocktail.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// In-memory [WebSocketChannel] for realtime tests.
class FakeWebSocketChannel extends Fake implements WebSocketChannel {
  final StreamController<dynamic> _incoming = StreamController<dynamic>();
  final Completer<void> _ready = Completer<void>();
  final List<dynamic> sent = [];
  bool sinkClosed = false;
  int? sinkCloseCode;

  FakeWebSocketChannel({Object? connectError}) {
    if (connectError != null) {
      _ready.future.ignore();
      _ready.completeError(connectError);
    } else {
      _ready.complete();
    }
  }

  @override
  Future<void> get ready => _ready.future;

  @override
  Stream<dynamic> get stream => _incoming.stream;

  @override
  late final WebSocketSink sink = _FakeSink(this);

  @override
  int? get closeCode => null;

  @override
  String? get closeReason => null;

  /// Server sends a raw text frame.
  void serverSend(Object frame) =>
      _incoming.add(frame is String ? frame : jsonEncode(frame));

  /// Server closes the connection.
  Future<void> serverClose() => _incoming.close();
}

class _FakeSink extends Fake implements WebSocketSink {
  final FakeWebSocketChannel channel;
  _FakeSink(this.channel);

  @override
  void add(dynamic data) {
    if (channel.sinkClosed) throw StateError('sink closed');
    channel.sent.add(data);
  }

  @override
  Future<void> close([int? closeCode, String? closeReason]) async {
    channel.sinkClosed = true;
    channel.sinkCloseCode = closeCode;
  }

  @override
  Future<void> get done => Future<void>.value();
}

/// Records every channel the client opens; optionally fails connects.
class FakeChannelFactory {
  final List<FakeWebSocketChannel> channels = [];
  final List<Uri> uris = [];
  final List<Map<String, String>> headers = [];

  /// When non-null, the next connects fail with this error.
  Object? connectError;

  WebSocketChannel call(Uri uri, Map<String, String> h) {
    uris.add(uri);
    headers.add(h);
    final channel = FakeWebSocketChannel(connectError: connectError);
    channels.add(channel);
    return channel;
  }

  FakeWebSocketChannel get last => channels.last;
}

/// Random that always returns the upper bound (no jitter reduction).
class MaxRandom implements Random {
  @override
  int nextInt(int max) => max - 1;
  @override
  double nextDouble() => 0.999;
  @override
  bool nextBool() => true;
}
