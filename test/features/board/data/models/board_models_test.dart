import 'package:feedback_os_flutter/src/features/board/data/models/board_item_model.dart';
import 'package:feedback_os_flutter/src/features/board/data/models/board_page_model.dart';
import 'package:feedback_os_flutter/src/features/board/data/models/roadmap_model.dart';
import 'package:feedback_os_flutter/src/features/board/data/models/vote_result_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BoardItemModel', () {
    test('serializes to and from JSON', () {
      final json = {
        'id': 'item_123',
        'title': 'Add dark mode',
        'description': 'Dark mode would be great at night',
        'category': 'Theme',
        'status': 'planned',
        'vote_count': 15,
        'has_voted': true,
        'is_mine': false,
        'created_at': '2026-10-14T00:00:00.000Z',
      };

      final model = BoardItemModel.fromJson(json);

      expect(model.id, 'item_123');
      expect(model.title, 'Add dark mode');
      expect(model.description, 'Dark mode would be great at night');
      expect(model.category, 'Theme');
      expect(model.status, 'planned');
      expect(model.voteCount, 15);
      expect(model.hasVoted, isTrue);
      expect(model.isMine, isFalse);
      expect(model.createdAt, DateTime.parse('2026-10-14T00:00:00.000Z'));

      final serialized = model.toJson();
      expect(serialized['id'], 'item_123');
      expect(serialized['title'], 'Add dark mode');
      expect(serialized['vote_count'], 15);
      expect(serialized['has_voted'], isTrue);
    });

    test('handles missing optional fields gracefully', () {
      final json = {
        'id': 'item_456',
        'title': 'Minimal item',
        'status': 'open',
      };

      final model = BoardItemModel.fromJson(json);

      expect(model.id, 'item_456');
      expect(model.title, 'Minimal item');
      expect(model.description, '');
      expect(model.category, isNull);
      expect(model.voteCount, 0);
      expect(model.hasVoted, isFalse);
      expect(model.isMine, isFalse);
    });
  });

  group('BoardPageModel', () {
    test('parses paginated list with cursor', () {
      final json = {
        'data': [
          {
            'id': 'item_1',
            'title': 'Item 1',
            'status': 'open',
            'vote_count': 5,
            'has_voted': false,
            'is_mine': true,
          },
        ],
        'next_cursor': 'cursor_abc123',
      };

      final page = BoardPageModel.fromJson(json);

      expect(page.items.length, 1);
      expect(page.items.first.id, 'item_1');
      expect(page.nextCursor, 'cursor_abc123');

      final serialized = page.toJson();
      expect((serialized['data'] as List).length, 1);
      expect(serialized['next_cursor'], 'cursor_abc123');
    });
  });

  group('RoadmapModel', () {
    test('parses planned, in_progress, and shipped sections', () {
      final json = {
        'planned': [
          {
            'id': 'p1',
            'title': 'Planned 1',
            'status': 'planned',
            'vote_count': 10,
            'has_voted': true,
            'is_mine': false,
          }
        ],
        'in_progress': [
          {
            'id': 'ip1',
            'title': 'In Progress 1',
            'status': 'in_progress',
            'vote_count': 25,
            'has_voted': false,
            'is_mine': true,
          }
        ],
        'shipped': [
          {
            'id': 's1',
            'title': 'Shipped 1',
            'status': 'shipped',
            'vote_count': 50,
            'has_voted': true,
            'is_mine': false,
          }
        ],
      };

      final roadmap = RoadmapModel.fromJson(json);

      expect(roadmap.planned.length, 1);
      expect(roadmap.planned.first.id, 'p1');
      expect(roadmap.inProgress.length, 1);
      expect(roadmap.inProgress.first.id, 'ip1');
      expect(roadmap.shipped.length, 1);
      expect(roadmap.shipped.first.id, 's1');

      final serialized = roadmap.toJson();
      expect((serialized['planned'] as List).length, 1);
      expect((serialized['in_progress'] as List).length, 1);
      expect((serialized['shipped'] as List).length, 1);
    });
  });

  group('VoteResultModel', () {
    test('serializes vote count and state', () {
      final json = {
        'vote_count': 42,
        'has_voted': true,
      };

      final vote = VoteResultModel.fromJson(json);

      expect(vote.voteCount, 42);
      expect(vote.hasVoted, isTrue);

      final serialized = vote.toJson();
      expect(serialized['vote_count'], 42);
      expect(serialized['has_voted'], isTrue);
    });
  });
}
