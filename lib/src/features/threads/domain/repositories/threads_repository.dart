import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/my_feedback_item.dart';
import '../entities/thread_detail.dart';
import '../entities/thread_reply.dart';
import '../entities/unread_count.dart';

abstract interface class ThreadsRepository {
  /// Fetches unread count for current user / device.
  Future<Either<Failure, UnreadCount>> getUnreadCount({
    CancelToken? cancelToken,
  });

  /// Fetches all feedback items submitted by current user / device.
  Future<Either<Failure, List<MyFeedbackItem>>> getMyItems({
    CancelToken? cancelToken,
  });

  /// Fetches thread details including discussion replies and status events.
  Future<Either<Failure, ThreadDetail>> getThreadDetail({
    required String itemId,
    CancelToken? cancelToken,
  });

  /// Posts a reply message to the feedback thread.
  Future<Either<Failure, ThreadReply>> sendReply({
    required String itemId,
    required String message,
    CancelToken? cancelToken,
  });

  /// Marks all unread updates in a thread as read.
  Future<Either<Failure, void>> markThreadRead({
    required String itemId,
    CancelToken? cancelToken,
  });
}
