import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/upload_reservation.dart';

/// Contract for uploading raw binary bytes directly to presigned storage destinations.
abstract interface class BinaryUploader {
  Future<void> uploadBinary({
    required UploadReservation reservation,
    required Uint8List bytes,
    CancelToken? cancelToken,
  });
}

/// Implementation using Dio that uploads raw bytes to presigned R2/S3 URLs
/// ensuring no SDK API credentials are leaked to third-party storage buckets.
class DioBinaryUploader implements BinaryUploader {
  final Dio _dio;

  DioBinaryUploader({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<void> uploadBinary({
    required UploadReservation reservation,
    required Uint8List bytes,
    CancelToken? cancelToken,
  }) async {
    // Check local expiry before uploading
    if (reservation.isExpired()) {
      throw const FeedbackOsUploadNotFoundException(
        'Upload reservation has expired. A fresh reservation is required.',
        statusCode: 410,
      );
    }

    try {
      // Build clean headers containing ONLY the reservation headers and content length.
      // Explicitly DO NOT include X-FeedbackOS-Key or X-FeedbackOS-Device.
      final cleanHeaders = <String, dynamic>{
        for (final entry in reservation.headers.entries)
          entry.key: entry.value,
        'content-length': bytes.lengthInBytes.toString(),
      };

      final response = await _dio.putUri(
        reservation.url,
        data: bytes,
        options: Options(
          headers: cleanHeaders,
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status >= 200 && status < 300,
        ),
        cancelToken: cancelToken,
      );

      if (response.statusCode == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        throw FeedbackOsServerException(
          'Upload destination returned unexpected status ${response.statusCode}',
          statusCode: response.statusCode ?? 500,
        );
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        throw const FeedbackOsNetworkException(
          'Upload was cancelled.',
          statusCode: 499,
        );
      }

      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.connectionError) {
        throw FeedbackOsNetworkException(
          'Network timeout or connection error during binary upload.',
          details: e.message,
        );
      }

      final statusCode = e.response?.statusCode;
      if (statusCode == 404) {
        throw FeedbackOsUploadNotFoundException(
          'Upload destination URL not found or expired.',
          statusCode: 404,
          details: e.response?.data,
        );
      }

      if (statusCode == 403) {
        throw FeedbackOsAuthenticationException(
          'Access denied to presigned upload destination.',
          code: 'upload_forbidden',
          statusCode: 403,
          details: e.response?.data,
        );
      }

      throw FeedbackOsServerException(
        'Storage upload failed with HTTP $statusCode',
        statusCode: statusCode ?? 500,
        details: e.response?.data,
      );
    }
  }
}
