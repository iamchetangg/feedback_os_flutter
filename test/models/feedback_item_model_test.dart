import 'package:flutter_test/flutter_test.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';
import 'package:feedback_os_flutter/src/features/feedback/data/models/feedback_item_model.dart';

void main() {
  group('FeedbackItemModel', () {
    test('parses exact OpenAPI feedback response correctly', () {
      final json = {
        'id': '1c0e8260-63ee-4213-a70d-f06f88da777c',
        'type': 'bug',
        'title': 'Checkout button unresponsive',
        'description': 'Tapping does nothing',
        'category': 'Payments',
        'status': 'open',
        'is_public': false,
        'created_at': '2026-10-13T12:00:00.000Z',
      };

      final model = FeedbackItemModel.fromJson(json);

      expect(model.id, equals('1c0e8260-63ee-4213-a70d-f06f88da777c'));
      expect(model.type, equals(FeedbackType.bug));
      expect(model.title, equals('Checkout button unresponsive'));
      expect(model.description, equals('Tapping does nothing'));
      expect(model.category, equals('Payments'));
      expect(model.status, equals('open'));
      expect(model.isPublic, isFalse);
      expect(model.createdAt.toUtc().year, equals(2026));

      final serialized = model.toJson();
      expect(serialized['id'], equals(model.id));
      expect(serialized['type'], equals('bug'));
      expect(serialized['is_public'], isFalse);
    });

    test('handles nullable category and default status', () {
      final json = {
        'id': '1c0e8260-63ee-4213-a70d-f06f88da777c',
        'type': 'feature',
        'title': 'Dark Mode',
        'description': '',
        'category': null,
        'status': 'planned',
        'is_public': true,
        'created_at': '2026-10-13T12:00:00.000Z',
      };

      final model = FeedbackItemModel.fromJson(json);
      expect(model.category, isNull);
      expect(model.type, equals(FeedbackType.feature));
      expect(model.isPublic, isTrue);
    });
  });
}
