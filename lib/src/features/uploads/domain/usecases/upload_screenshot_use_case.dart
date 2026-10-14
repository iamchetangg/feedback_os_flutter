import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/screenshot_attachment.dart';
import '../repositories/upload_repository.dart';

/// Use case that orchestrates reserving a presigned URL, validating constraints,
/// and transmitting binary bytes directly to the storage destination.
class UploadScreenshotUseCase {
  final UploadRepository repository;

  const UploadScreenshotUseCase(this.repository);

  /// Executes upload of a screenshot attachment, returning its confirmed [uploadId] on success.
  Future<Either<Failure, String>> call({
    required ScreenshotAttachment attachment,
    CancelToken? cancelToken,
  }) async {
    try {
      attachment.validate();
    } catch (e) {
      return Left(ValidationFailure(e.toString()));
    }

    final reservationResult = await repository.reserveUpload(
      contentType: attachment.contentType,
      byteSize: attachment.byteSize,
      cancelToken: cancelToken,
    );

    return reservationResult.match(
      (failure) => Left(failure),
      (reservation) async {
        final uploadResult = await repository.uploadBinary(
          reservation: reservation,
          bytes: attachment.bytes,
          cancelToken: cancelToken,
        );

        return uploadResult.match(
          (failure) => Left(failure),
          (_) => Right(reservation.uploadId),
        );
      },
    );
  }
}
