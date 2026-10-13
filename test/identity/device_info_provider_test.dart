import 'package:flutter_test/flutter_test.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';

void main() {
  group('DeviceInfoProvider', () {
    test('StaticDeviceInfoProvider returns sanitized metadata', () async {
      const provider = StaticDeviceInfoProvider(
        deviceInfo: FeedbackDeviceInfo(
          osVersion: 'Android 14',
          appVersion: '2.5.0',
          build: '100',
          deviceModel: 'Pixel 8 Pro',
          locale: 'en-US',
        ),
      );

      final info = await provider.getDeviceInfo();
      expect(info.osVersion, equals('Android 14'));
      expect(info.appVersion, equals('2.5.0'));
      expect(info.build, equals('100'));
      expect(info.deviceModel, equals('Pixel 8 Pro'));
      expect(info.locale, equals('en-US'));
    });

    test('FeedbackDeviceInfo truncates bounds to conform to OpenAPI spec', () {
      final oversized = FeedbackDeviceInfo(
        osVersion: 'A' * 50, // max 32
        appVersion: 'B' * 50, // max 32
        build: 'C' * 50, // max 32
        deviceModel: 'D' * 100, // max 64
        locale: 'E' * 50, // max 35
      );

      final sanitized = oversized.sanitized();
      expect(sanitized.osVersion.length, equals(32));
      expect(sanitized.appVersion.length, equals(32));
      expect(sanitized.build?.length, equals(32));
      expect(sanitized.deviceModel.length, equals(64));
      expect(sanitized.locale?.length, equals(35));
    });
  });
}
