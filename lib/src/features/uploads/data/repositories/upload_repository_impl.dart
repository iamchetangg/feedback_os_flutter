import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/upload_reservation.dart';
import '../../domain/repositories/upload_repository.dart';
import '../datasources/binary_uploader.dart';
import '../datasources/upload_remote_data_source.dart';

class UploadRepositoryImpl implements UploadRepository {
  final UploadRemoteDataSource _remoteDataSource;
  final BinaryUploader _binaryUploader;

  UploadRepositoryImpl({
    required UploadRemoteDataSource remoteDataSource,
    required BinaryUploader binaryUploader,
  })  : _remoteDataSource = remoteDataSource,
        _binaryUploader = binaryUploader;

  Failure _mapExceptionToFailure(FeedbackOsException e) {
    return switch (e) {
      FeedbackOsAuthenticationException() => AuthenticationFailure(
          e.message,
          code: e.code,
          statusCode: e.statusCode,
        ),
      FeedbackOsSubscriptionException() => SubscriptionFailure(
          e.message,
          code: e.code,
          statusCode: e.statusCode,
        ),
      FeedbackOsValidationException() => ValidationFailure(
          e.message,
          code: e.code,
          statusCode: e.statusCode,
        ),
      FeedbackOsRateLimitException() => RateLimitFailure(
          e.message,
          statusCode: e.statusCode,
          retryAfter: e.retryAfter,
        ),
      FeedbackOsPayloadTooLargeException() => PayloadTooLargeFailure(
          e.message,
          statusCode: e.statusCode,
        ),
      FeedbackOsUploadNotFoundException() => UploadNotFoundFailure(
          e.message,
          statusCode: e.statusCode,
        ),
      FeedbackOsUploadInvalidException() => UploadInvalidFailure(
          e.message,
          statusCode: e.statusCode,
        ),
      FeedbackOsNetworkException() => NetworkFailure(
          e.message,
          statusCode: e.statusCode,
        ),
      FeedbackOsStorageException() => StorageFailure(e.message),
      FeedbackOsServerException() => ServerFailure(
          e.message,
          code: e.code,
          statusCode: e.statusCode,
        ),
    };
  }

  @override
  Future<Either<Failure, UploadReservation>> reserveUpload({
    required String contentType,
    required int byteSize,
    CancelToken? cancelToken,
  }) async {
    try {
      final reservation = await _remoteDataSource.reserveUpload(
        contentType: contentType,
        byteSize: byteSize,
        cancelToken: cancelToken,
      );
      return Right(reservation);
    } on FeedbackOsException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Unit>> uploadBinary({
    required UploadReservation reservation,
    required Uint8List bytes,
    CancelToken? cancelToken,
  }) async {
    try {
      await _binaryUploader.uploadBinary(
        reservation: reservation,
        bytes: bytes,
        cancelToken: cancelToken,
      );
      return const Right(unit);
    } on FeedbackOsException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
