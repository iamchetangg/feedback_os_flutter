import 'package:feedback_os_flutter/src/features/threads/data/models/my_feedback_item_model.dart';
import 'package:feedback_os_flutter/src/features/threads/data/models/thread_detail_model.dart';
import 'package:feedback_os_flutter/src/features/threads/data/models/thread_event_model.dart';
import 'package:feedback_os_flutter/src/features/threads/data/models/thread_reply_model.dart';
import 'package:feedback_os_flutter/src/features/threads/data/models/unread_count_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnreadCountModel', () {
    test('serializes to and from JSON', () {
      final json = {'count': 4};
      final model = UnreadCountModel.fromJson(json);

      expect(model.count, 4);
      expect(model.toJson(), {'count': 4});
    });

    test('defaults count to 0 when missing', () {
      final model = UnreadCountModel.fromJson(const {});
      expect(model.count, 0);
    });
  });

  group('MyFeedbackItemModel', () {
    test('serializes to and from JSON', () {
      final json = {
        'id': 'fb_1',
        'title': 'Crashing on payment',
        'type': 'bug',
        'category': 'Payments',
        'status': 'in_progress',
        'has_unread': true,
        'last_activity_at': '2026-10-14T02:00:00.000Z',
        'created_at': '2026-10-14T00:00:00.000Z',
      };

      final model = MyFeedbackItemModel.fromJson(json);

      expect(model.id, 'fb_1');
      expect(model.title, 'Crashing on payment');
      expect(model.type, 'bug');
      expect(model.category, 'Payments');
      expect(model.status, 'in_progress');
      expect(model.hasUnread, isTrue);
      expect(model.lastActivityAt, DateTime.parse('2026-10-14T02:00:00.000Z'));
      expect(model.createdAt, DateTime.parse('2026-10-14T00:00:00.000Z'));

      final serialized = model.toJson();
      expect(serialized['id'], 'fb_1');
      expect(serialized['has_unread'], isTrue);
    });
  });

  group('ThreadReplyModel', () {
    test('serializes to and from JSON and exposes helpers', () {
      final json = {
        'id': 'reply_1',
        'body': 'We deployed a fix in v1.2',
        'author_type': 'admin',
        'created_at': '2026-10-14T03:00:00.000Z',
      };

      final model = ThreadReplyModel.fromJson(json);

      expect(model.id, 'reply_1');
      expect(model.body, 'We deployed a fix in v1.2');
      expect(model.authorType, 'admin');
      expect(model.isAdmin, isTrue);
      expect(model.isUser, isFalse);

      final userReply = ThreadReplyModel.fromJson(const {
        'id': 'reply_2',
        'body': 'Thank you!',
        'author_type': 'user',
        'created_at': '2026-10-14T04:00:00.000Z',
      });
      expect(userReply.isUser, isTrue);
      expect(userReply.isAdmin, isFalse);
    });
  });

  group('ThreadEventModel', () {
    test('serializes to and from JSON', () {
      final json = {
        'id': 'evt_1',
        'type': 'status_changed',
        'old_status': 'open',
        'new_status': 'in_progress',
        'created_at': '2026-10-14T01:00:00.000Z',
      };

      final model = ThreadEventModel.fromJson(json);

      expect(model.id, 'evt_1');
      expect(model.type, 'status_changed');
      expect(model.oldStatus, 'open');
      expect(model.newStatus, 'in_progress');

      final serialized = model.toJson();
      expect(serialized['old_status'], 'open');
      expect(serialized['new_status'], 'in_progress');
    });
  });

  group('ThreadDetailModel', () {
    test('serializes complete thread with nested replies and events', () {
      final json = {
        'id': 'fb_1',
        'title': 'Crashing on payment',
        'description': 'Details here',
        'type': 'bug',
        'category': 'Payments',
        'status': 'in_progress',
        'created_at': '2026-10-14T00:00:00.000Z',
        'replies': [
          {
            'id': 'r1',
            'body': 'Looking into it',
            'author_type': 'admin',
            'created_at': '2026-10-14T01:00:00.000Z',
          }
        ],
        'events': [
          {
            'id': 'e1',
            'type': 'status_changed',
            'old_status': 'open',
            'new_status': 'in_progress',
            'created_at': '2026-10-14T00:30:00.000Z',
          }
        ],
      };

      final detail = ThreadDetailModel.fromJson(json);

      expect(detail.id, 'fb_1');
      expect(detail.replies.length, 1);
      expect(detail.replies.first.id, 'r1');
      expect(detail.events.length, 1);
      expect(detail.events.first.id, 'e1');

      final serialized = detail.toJson();
      expect((serialized['replies'] as List).length, 1);
      expect((serialized['events'] as List).length, 1);
    });
  });
}
