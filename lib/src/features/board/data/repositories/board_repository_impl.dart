import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/board_page.dart';
import '../../domain/entities/roadmap.dart';
import '../../domain/entities/vote_result.dart';
import '../../domain/repositories/board_repository.dart';
import '../datasources/board_remote_data_source.dart';

class BoardRepositoryImpl implements BoardRepository {
  final BoardRemoteDataSource _remoteDataSource;

  BoardRepositoryImpl({
    required BoardRemoteDataSource remoteDataSource,
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
      FeedbackOsUploadNotFoundException() => UploadNotFoundFailure(
          e.message,
          statusCode: e.statusCode,
        ),
      FeedbackOsUploadInvalidException() => UploadInvalidFailure(
          e.message,
          statusCode: e.statusCode,
        ),
      FeedbackOsServerException() => ServerFailure(
          e.message,
          code: e.code,
          statusCode: e.statusCode,
        ),
    };
  }

  @override
  Future<Either<Failure, BoardPage>> getBoard({
    String sort = 'top',
    String? cursor,
    int limit = 25,
    CancelToken? cancelToken,
  }) async {
    try {
      final page = await _remoteDataSource.getBoard(
        sort: sort,
        cursor: cursor,
        limit: limit,
        cancelToken: cancelToken,
      );
      return Right(page);
    } on FeedbackOsException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Roadmap>> getRoadmap({
    CancelToken? cancelToken,
  }) async {
    try {
      final roadmap = await _remoteDataSource.getRoadmap(
        cancelToken: cancelToken,
      );
      return Right(roadmap);
    } on FeedbackOsException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VoteResult>> voteItem({
    required String itemId,
    CancelToken? cancelToken,
  }) async {
    try {
      final result = await _remoteDataSource.voteItem(
        itemId: itemId,
        cancelToken: cancelToken,
      );
      return Right(result);
    } on FeedbackOsException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, VoteResult>> unvoteItem({
    required String itemId,
    CancelToken? cancelToken,
  }) async {
    try {
      final result = await _remoteDataSource.unvoteItem(
        itemId: itemId,
        cancelToken: cancelToken,
      );
      return Right(result);
    } on FeedbackOsException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
