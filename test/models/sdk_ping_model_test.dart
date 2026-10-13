import 'package:flutter_test/flutter_test.dart';
import 'package:feedback_os_flutter/src/features/feedback/data/models/sdk_ping_model.dart';

void main() {
  group('SdkPingModel', () {
    test('parses exact OpenAPI ping response correctly', () {
      final json = {
        'ok': true,
        'app_id': '1c0e8260-63ee-4213-a70d-f06f88da777c',
      };

      final model = SdkPingModel.fromJson(json);

      expect(model.ok, isTrue);
      expect(model.appId, equals('1c0e8260-63ee-4213-a70d-f06f88da777c'));
      expect(model.toJson(), equals(json));
    });
  });
}
