import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/feedback_item.dart';
import '../../domain/entities/feedback_submission.dart';
import '../../domain/entities/sdk_config_entity.dart';
import '../../domain/entities/sdk_ping_entity.dart';
import '../../domain/repositories/feedback_repository.dart';
import '../datasources/feedback_remote_data_source.dart';
import '../models/feedback_submission_model.dart';

class FeedbackRepositoryImpl implements FeedbackRepository {
  final FeedbackRemoteDataSource _remoteDataSource;

  FeedbackRepositoryImpl({
    required FeedbackRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

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
  Future<Either<Failure, SdkConfig>> getConfig(
    String publishableKey, {
    CancelToken? cancelToken,
  }) async {
    try {
      final config = await _remoteDataSource.getConfig(
        publishableKey,
        cancelToken: cancelToken,
      );
      return Right(config);
    } on FeedbackOsException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, SdkPingResult>> ping({
    CancelToken? cancelToken,
  }) async {
    try {
      final result = await _remoteDataSource.ping(cancelToken: cancelToken);
      return Right(result);
    } on FeedbackOsException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> identify(
    String? externalUserId, {
    CancelToken? cancelToken,
  }) async {
    try {
      await _remoteDataSource.identify(
        externalUserId,
        cancelToken: cancelToken,
      );
      return const Right(null);
    } on FeedbackOsException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, FeedbackItem>> submitFeedback(
    FeedbackSubmission submission, {
    CancelToken? cancelToken,
  }) async {
    try {
      final model = FeedbackSubmissionModel.fromEntity(submission);
      final item = await _remoteDataSource.submitFeedback(
        model,
        cancelToken: cancelToken,
      );
      return Right(item);
    } on FeedbackOsException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
