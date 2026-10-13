import 'package:flutter_test/flutter_test.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';
import 'package:feedback_os_flutter/src/features/feedback/data/models/feedback_submission_model.dart';

void main() {
  group('FeedbackSubmissionModel', () {
    const testDevice = FeedbackDeviceInfo(
      osVersion: 'iOS 17.5',
      appVersion: '1.2.0',
      build: '42',
      deviceModel: 'iPhone14,2',
      locale: 'en-US',
    );

    test('serializes exact snake_case JSON matching OpenAPI schema', () {
      const submission = FeedbackSubmission(
        clientSubmissionId: 'sub_client_12345678',
        type: FeedbackType.bug,
        title: 'Checkout button broken',
        description: 'Tapping Pay does nothing',
        category: 'Payments',
        device: testDevice,
        screenshotUploadIds: [
          'a1b2c3d4-e5f6-7890-abcd-ef1234567890',
        ],
      );

      final model = FeedbackSubmissionModel.fromEntity(submission);
      final json = model.toJson();

      expect(json['client_submission_id'], equals('sub_client_12345678'));
      expect(json['type'], equals('bug'));
      expect(json['title'], equals('Checkout button broken'));
      expect(json['description'], equals('Tapping Pay does nothing'));
      expect(json['category'], equals('Payments'));
      expect(
          json['device'],
          equals({
            'os_version': 'iOS 17.5',
            'app_version': '1.2.0',
            'build': '42',
            'device_model': 'iPhone14,2',
            'locale': 'en-US',
          }));
      expect(
        json['screenshot_upload_ids'],
        equals(['a1b2c3d4-e5f6-7890-abcd-ef1234567890']),
      );
    });

    test('omits optional category, build, and locale when not present', () {
      const submission = FeedbackSubmission(
        clientSubmissionId: 'sub_client_12345678',
        type: FeedbackType.feature,
        title: 'Dark mode',
        device: FeedbackDeviceInfo(
          osVersion: 'Android 14',
          appVersion: '2.0.0',
          deviceModel: 'Pixel 8',
        ),
      );

      final model = FeedbackSubmissionModel.fromEntity(submission);
      final json = model.toJson();

      expect(json.containsKey('category'), isFalse);
      expect(
          json['device'],
          equals({
            'os_version': 'Android 14',
            'app_version': '2.0.0',
            'device_model': 'Pixel 8',
          }));
      expect(json['screenshot_upload_ids'], isEmpty);
    });

    test('deserializes from JSON round-trip correctly', () {
      final json = {
        'client_submission_id': 'sub_client_12345678',
        'type': 'feature',
        'title': 'New Feature',
        'description': 'Details here',
        'category': 'Roadmap',
        'device': {
          'os_version': 'macOS 14.5',
          'app_version': '1.0.0',
          'device_model': 'MacBookPro18,1',
        },
        'screenshot_upload_ids': <String>[],
      };

      final model = FeedbackSubmissionModel.fromJson(json);
      expect(model.clientSubmissionId, equals('sub_client_12345678'));
      expect(model.type, equals(FeedbackType.feature));
      expect(model.title, equals('New Feature'));
      expect(model.category, equals('Roadmap'));
      expect(model.device.deviceModel, equals('MacBookPro18,1'));
    });

    test('validates submission constraints', () {
      // Too short clientSubmissionId (< 8 chars)
      expect(
        () => const FeedbackSubmission(
          clientSubmissionId: 'short',
          type: FeedbackType.bug,
          title: 'Title',
          device: testDevice,
        ).validate(),
        throwsA(isA<ArgumentError>()),
      );

      // Empty title
      expect(
        () => const FeedbackSubmission(
          clientSubmissionId: 'valid_sub_id_1234',
          type: FeedbackType.bug,
          title: '   ',
          device: testDevice,
        ).validate(),
        throwsA(isA<ArgumentError>()),
      );

      // Category too long (> 50 chars)
      expect(
        () => FeedbackSubmission(
          clientSubmissionId: 'valid_sub_id_1234',
          type: FeedbackType.bug,
          title: 'Title',
          category: 'a' * 51,
          device: testDevice,
        ).validate(),
        throwsA(isA<ArgumentError>()),
      );

      // Too many screenshots (> 3)
      expect(
        () => const FeedbackSubmission(
          clientSubmissionId: 'valid_sub_id_1234',
          type: FeedbackType.bug,
          title: 'Title',
          device: testDevice,
          screenshotUploadIds: ['id1', 'id2', 'id3', 'id4'],
        ).validate(),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
