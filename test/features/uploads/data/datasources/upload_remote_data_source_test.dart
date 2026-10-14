import 'package:dio/dio.dart';
import 'package:feedback_os_flutter/src/core/network/api_endpoints.dart';
import 'package:feedback_os_flutter/src/core/network/feedback_os_dio_client.dart';
import 'package:feedback_os_flutter/src/features/uploads/data/datasources/upload_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockFeedbackOsHttpClient extends Mock implements FeedbackOsHttpClient {}

void main() {
  group('UploadRemoteDataSourceImpl', () {
    late MockFeedbackOsHttpClient mockClient;
    late UploadRemoteDataSourceImpl dataSource;

    setUp(() {
      mockClient = MockFeedbackOsHttpClient();
      dataSource = UploadRemoteDataSourceImpl(client: mockClient);
    });

    test(
        'successfully requests upload reservation with correct path, headers, and body',
        () async {
      final responsePayload = {
        'upload_id': '45f3c099-231a-4713-94c0-fdb2422ca2ff',
        'method': 'PUT',
        'url': 'https://r2.feedbackos.dev/bucket/photo.jpg',
        'headers': {'content-type': 'image/jpeg'},
        'expires_at': '2026-10-14T06:00:00.000Z',
      };

      when(
        () => mockClient.post<Map<String, dynamic>>(
          ApiEndpoints.uploads,
          data: {
            'content_type': 'image/jpeg',
            'byte_size': 4096,
          },
          cancelToken: any(named: 'cancelToken'),
          includeAuthHeaders: true,
        ),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: ApiEndpoints.uploads),
          statusCode: 201,
          data: responsePayload,
        ),
      );

      final result = await dataSource.reserveUpload(
        contentType: 'image/jpeg',
        byteSize: 4096,
      );

      expect(result.uploadId, '45f3c099-231a-4713-94c0-fdb2422ca2ff');
      expect(result.method, 'PUT');
      expect(
          result.url, Uri.parse('https://r2.feedbackos.dev/bucket/photo.jpg'));
      expect(result.headers['content-type'], 'image/jpeg');

      verify(
        () => mockClient.post<Map<String, dynamic>>(
          ApiEndpoints.uploads,
          data: {
            'content_type': 'image/jpeg',
            'byte_size': 4096,
          },
          cancelToken: any(named: 'cancelToken'),
          includeAuthHeaders: true,
        ),
      ).called(1);
    });
  });
}
