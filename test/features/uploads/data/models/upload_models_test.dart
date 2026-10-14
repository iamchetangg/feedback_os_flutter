import 'package:feedback_os_flutter/src/features/uploads/data/models/create_upload_request_model.dart';
import 'package:feedback_os_flutter/src/features/uploads/data/models/upload_reservation_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Upload Models Test', () {
    test('CreateUploadRequestModel serializes to JSON matching OpenAPI spec', () {
      const model = CreateUploadRequestModel(
        contentType: 'image/png',
        byteSize: 10240,
      );

      final json = model.toJson();
      expect(json, {
        'content_type': 'image/png',
        'byte_size': 10240,
      });

      final fromJson = CreateUploadRequestModel.fromJson(json);
      expect(fromJson, equals(model));
    });

    test('UploadReservationModel parses exact OpenAPI 201 response JSON', () {
      final json = {
        'upload_id': '8e27c1a2-8924-4f0f-8f81-5f07a21764eb',
        'method': 'PUT',
        'url': 'https://r2.feedbackos.dev/uploads/8e27c1a2.png',
        'headers': {
          'content-type': 'image/png',
          'x-amz-server-side-encryption': 'AES256',
        },
        'expires_at': '2026-10-14T05:00:00.000Z',
      };

      final model = UploadReservationModel.fromJson(json);

      expect(model.uploadId, '8e27c1a2-8924-4f0f-8f81-5f07a21764eb');
      expect(model.method, 'PUT');
      expect(
        model.url,
        Uri.parse('https://r2.feedbackos.dev/uploads/8e27c1a2.png'),
      );
      expect(model.headers['content-type'], 'image/png');
      expect(model.headers['x-amz-server-side-encryption'], 'AES256');
      expect(
        model.expiresAt,
        DateTime.parse('2026-10-14T05:00:00.000Z'),
      );
      expect(
        model.isExpired(buffer: Duration.zero),
        isTrue, // since 2026-10-14T05:00:00.000Z is past relative to test runtime if current time is past or future
      );

      final outputJson = model.toJson();
      expect(outputJson['upload_id'], model.uploadId);
      expect(outputJson['method'], 'PUT');
      expect(outputJson['url'], model.url.toString());
      expect(outputJson['headers'], model.headers);
      expect(outputJson['expires_at'], '2026-10-14T05:00:00.000Z');
    });
  });
}
