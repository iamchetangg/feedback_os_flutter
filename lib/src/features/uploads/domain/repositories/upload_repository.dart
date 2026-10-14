import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/upload_reservation.dart';

/// Repository contract for screenshot upload reservation and transmission.
abstract interface class UploadRepository {
  /// Reserves a presigned upload URL from the FeedbackOS API.
  Future<Either<Failure, UploadReservation>> reserveUpload({
    required String contentType,
    required int byteSize,
    CancelToken? cancelToken,
  });

  /// Transmits raw binary bytes directly to the presigned storage destination
  /// using only the headers provided by the reservation.
  Future<Either<Failure, Unit>> uploadBinary({
    required UploadReservation reservation,
    required Uint8List bytes,
    CancelToken? cancelToken,
  });
}
