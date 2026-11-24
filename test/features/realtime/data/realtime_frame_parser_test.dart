import 'package:feedback_os_flutter/feedback_os_flutter.dart';
import 'package:feedback_os_flutter/src/features/realtime/data/datasources/realtime_client.dart';
import 'package:feedback_os_flutter/src/features/realtime/data/models/realtime_frame_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseRealtimeFrame', () {
    test('parses reply.created', () {
      final event = parseRealtimeFrame(
        '{"type":"reply.created","item_id":"it_1","reply_id":"r_1",'
        '"author_name":"Jane","preview":"Fixed in 2.1",'
        '"created_at":"2026-11-25T10:00:00Z"}',
      );
      expect(
        event,
        ReplyReceived(
          itemId: 'it_1',
          replyId: 'r_1',
          authorName: 'Jane',
          preview: 'Fixed in 2.1',
          createdAt: DateTime.utc(2026, 11, 25, 10),
        ),
      );
    });

    test('reply.created with null author_name', () {
      final event = parseRealtimeFrame(
        '{"type":"reply.created","item_id":"it_1","reply_id":"r_1",'
        '"author_name":null,"preview":"Hi","created_at":"2026-11-25T10:00:00Z"}',
      ) as ReplyReceived;
      expect(event.authorName, isNull);
    });

    test('parses item.status_changed', () {
      final event = parseRealtimeFrame(
        '{"type":"item.status_changed","item_id":"it_2","from_status":"open",'
        '"to_status":"shipped","created_at":"2026-11-25T10:00:00Z"}',
      );
      expect(
        event,
        StatusChanged(
          itemId: 'it_2',
          fromStatus: 'open',
          toStatus: 'shipped',
          createdAt: DateTime.utc(2026, 11, 25, 10),
        ),
      );
    });

    test('ignores hello, pong, unknown types and malformed frames', () {
      expect(parseRealtimeFrame('{"type":"hello"}'), isNull);
      expect(parseRealtimeFrame('pong'), isNull);
      expect(
          parseRealtimeFrame('{"type":"vote.created","item_id":"x"}'), isNull);
      expect(parseRealtimeFrame('{not json'), isNull);
      expect(parseRealtimeFrame('[1,2]'), isNull);
      expect(parseRealtimeFrame(null), isNull);
      expect(parseRealtimeFrame(<int>[1, 2]), isNull);
      // Missing required fields.
      expect(
          parseRealtimeFrame('{"type":"reply.created","item_id":"x"}'), isNull);
    });
  });

  group('buildRealtimeUri', () {
    test('https base -> wss stream url', () {
      expect(
        buildRealtimeUri(Uri.parse('https://api.feedbackos.dev')).toString(),
        'wss://api.feedbackos.dev/v1/sdk/me/stream',
      );
    });

    test('http localhost with port and trailing slash -> ws', () {
      expect(
        buildRealtimeUri(Uri.parse('http://10.0.2.2:8787/')).toString(),
        'ws://10.0.2.2:8787/v1/sdk/me/stream',
      );
    });

    test('keeps a base path prefix', () {
      expect(
        buildRealtimeUri(Uri.parse('https://example.com/api')).toString(),
        'wss://example.com/api/v1/sdk/me/stream',
      );
    });
  });
}
