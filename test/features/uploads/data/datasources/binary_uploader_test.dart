import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:feedback_os_flutter/feedback_os_flutter.dart';
import 'package:feedback_os_flutter/src/features/uploads/data/datasources/binary_uploader.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DioBinaryUploader', () {
    late Dio dio;
    late DioBinaryUploader uploader;
    late Map<String, dynamic> capturedHeaders;
    late dynamic capturedData;
    late Uri? capturedUri;
    late int mockStatusCode;

    setUp(() {
      dio = Dio();
      capturedHeaders = {};
      capturedData = null;
      capturedUri = null;
      mockStatusCode = 200;

      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedUri = options.uri;
            capturedHeaders = options.headers;
            capturedData = options.data;

            if (mockStatusCode >= 200 && mockStatusCode < 300) {
              handler.resolve(
                Response(
                  requestOptions: options,
                  statusCode: mockStatusCode,
                ),
              );
            } else {
              handler.reject(
                DioException(
                  requestOptions: options,
                  response: Response(
                    requestOptions: options,
                    statusCode: mockStatusCode,
                  ),
                  type: DioExceptionType.badResponse,
                ),
              );
            }
          },
        ),
      );

      uploader = DioBinaryUploader(dio: dio);
    });

    test('successfully uploads binary bytes with clean headers', () async {
      final bytes = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]);
      final reservation = UploadReservation(
        uploadId: 'test-upload-id',
        method: 'PUT',
        url: Uri.parse('https://r2.storage.feedbackos.dev/item.png'),
        headers: const {
          'content-type': 'image/png',
          'x-amz-acl': 'private',
        },
        expiresAt: DateTime.now().add(const Duration(minutes: 10)),
      );

      await uploader.uploadBinary(
        reservation: reservation,
        bytes: bytes,
      );

      expect(
        capturedUri,
        Uri.parse('https://r2.storage.feedbackos.dev/item.png'),
      );
      expect(capturedData, bytes);
      expect(capturedHeaders['content-type'], 'image/png');
      expect(capturedHeaders['x-amz-acl'], 'private');
      expect(capturedHeaders['content-length'], '8');

      // Security check: Never leak SDK API headers to storage bucket
      expect(capturedHeaders['X-FeedbackOS-Key'], isNull);
      expect(capturedHeaders['x-feedbackos-key'], isNull);
      expect(capturedHeaders['X-FeedbackOS-Device'], isNull);
      expect(capturedHeaders['x-feedbackos-device'], isNull);
    });

    test(
        'throws FeedbackOsUploadNotFoundException if reservation is already expired',
        () async {
      final bytes = Uint8List.fromList([1, 2, 3]);
      final reservation = UploadReservation(
        uploadId: 'expired-upload-id',
        method: 'PUT',
        url: Uri.parse('https://r2.storage.feedbackos.dev/item.png'),
        headers: const {'content-type': 'image/png'},
        expiresAt: DateTime.now().subtract(const Duration(seconds: 10)),
      );

      expect(
        () => uploader.uploadBinary(
          reservation: reservation,
          bytes: bytes,
        ),
        throwsA(
          isA<FeedbackOsUploadNotFoundException>().having(
            (e) => e.message,
            'message',
            contains('expired'),
          ),
        ),
      );
      expect(capturedUri, isNull); // Network call was never made
    });

    test(
        'throws FeedbackOsUploadNotFoundException on HTTP 404 from storage URL',
        () async {
      mockStatusCode = 404;
      final reservation = UploadReservation(
        uploadId: 'test-upload-id',
        method: 'PUT',
        url: Uri.parse('https://r2.storage.feedbackos.dev/item.png'),
        headers: const {'content-type': 'image/png'},
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );

      expect(
        () => uploader.uploadBinary(
          reservation: reservation,
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
        throwsA(isA<FeedbackOsUploadNotFoundException>()),
      );
    });

    test('throws FeedbackOsAuthenticationException on HTTP 403 forbidden',
        () async {
      mockStatusCode = 403;
      final reservation = UploadReservation(
        uploadId: 'test-upload-id',
        method: 'PUT',
        url: Uri.parse('https://r2.storage.feedbackos.dev/item.png'),
        headers: const {'content-type': 'image/png'},
        expiresAt: DateTime.now().add(const Duration(minutes: 5)),
      );

      expect(
        () => uploader.uploadBinary(
          reservation: reservation,
          bytes: Uint8List.fromList([1, 2, 3]),
        ),
        throwsA(isA<FeedbackOsAuthenticationException>()),
      );
    });
  });
}
