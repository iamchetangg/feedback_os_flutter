import 'package:flutter_test/flutter_test.dart';
import 'package:feedback_os_flutter/src/features/feedback/data/models/sdk_config_model.dart';

void main() {
  group('SdkConfigModel', () {
    test('parses exact OpenAPI config response correctly', () {
      final json = {
        'app_id': '1c0e8260-63ee-4213-a70d-f06f88da777c',
        'config_version': 2,
        'enabled': true,
        'board': {
          'enabled': true,
        },
        'roadmap': {
          'enabled': false,
        },
        'categories': ['Bugs', 'Billing', 'UI/UX'],
        'statuses': ['open', 'planned', 'in_progress', 'shipped', 'closed'],
        'limits': {
          'max_screenshots': 3,
          'max_screenshot_bytes': 5242880,
          'screenshot_types': ['image/jpeg', 'image/png'],
        },
      };

      final model = SdkConfigModel.fromJson(json);

      expect(model.appId, equals('1c0e8260-63ee-4213-a70d-f06f88da777c'));
      expect(model.configVersion, equals(2));
      expect(model.enabled, isTrue);
      expect(model.board.enabled, isTrue);
      expect(model.roadmap.enabled, isFalse);
      expect(model.categories, equals(['Bugs', 'Billing', 'UI/UX']));
      expect(model.statuses,
          equals(['open', 'planned', 'in_progress', 'shipped', 'closed']));
      expect(model.limits.maxScreenshots, equals(3));
      expect(model.limits.maxScreenshotBytes, equals(5242880));
      expect(model.limits.screenshotTypes, equals(['image/jpeg', 'image/png']));

      // Roundtrip
      final serialized = model.toJson();
      expect(serialized['app_id'], equals(model.appId));
      expect(serialized['config_version'], equals(model.configVersion));
      expect(serialized['board']['enabled'], isTrue);
      expect(serialized['roadmap']['enabled'], isFalse);
    });

    test('tolerates missing optional fields with safe defaults', () {
      final json = {
        'app_id': '1c0e8260-63ee-4213-a70d-f06f88da777c',
      };

      final model = SdkConfigModel.fromJson(json);
      expect(model.appId, equals('1c0e8260-63ee-4213-a70d-f06f88da777c'));
      expect(model.configVersion, equals(1));
      expect(model.enabled, isFalse);
      expect(model.board.enabled, isFalse);
      expect(model.roadmap.enabled, isFalse);
      expect(model.categories, isEmpty);
      expect(model.limits.maxScreenshots, equals(3));
      expect(model.limits.maxScreenshotBytes, equals(5242880));
    });
  });
}
