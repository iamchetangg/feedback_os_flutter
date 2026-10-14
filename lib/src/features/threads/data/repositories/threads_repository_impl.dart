import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/my_feedback_item.dart';
import '../../domain/entities/thread_detail.dart';
import '../../domain/entities/thread_reply.dart';
import '../../domain/entities/unread_count.dart';
import '../../domain/repositories/threads_repository.dart';
import '../datasources/threads_remote_data_source.dart';

class ThreadsRepositoryImpl implements ThreadsRepository {
  final ThreadsRemoteDataSource _remoteDataSource;

  ThreadsRepositoryImpl({
    required ThreadsRemoteDataSource remoteDataSource,
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
  Future<Either<Failure, UnreadCount>> getUnreadCount({
    CancelToken? cancelToken,
  }) async {
    try {
      final unread = await _remoteDataSource.getUnreadCount(
        cancelToken: cancelToken,
      );
      return Right(unread);
    } on FeedbackOsException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<MyFeedbackItem>>> getMyItems({
    CancelToken? cancelToken,
  }) async {
    try {
      final items = await _remoteDataSource.getMyItems(
        cancelToken: cancelToken,
      );
      return Right(items);
    } on FeedbackOsException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ThreadDetail>> getThreadDetail({
    required String itemId,
    CancelToken? cancelToken,
  }) async {
    try {
      final detail = await _remoteDataSource.getThreadDetail(
        itemId: itemId,
        cancelToken: cancelToken,
      );
      return Right(detail);
    } on FeedbackOsException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, ThreadReply>> sendReply({
    required String itemId,
    required String message,
    CancelToken? cancelToken,
  }) async {
    try {
      final reply = await _remoteDataSource.sendReply(
        itemId: itemId,
        message: message,
        cancelToken: cancelToken,
      );
      return Right(reply);
    } on FeedbackOsException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markThreadRead({
    required String itemId,
    CancelToken? cancelToken,
  }) async {
    try {
      await _remoteDataSource.markThreadRead(
        itemId: itemId,
        cancelToken: cancelToken,
      );
      return const Right(null);
    } on FeedbackOsException catch (e) {
      return Left(_mapExceptionToFailure(e));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}
