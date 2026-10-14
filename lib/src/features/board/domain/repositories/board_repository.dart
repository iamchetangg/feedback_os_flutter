import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/board_page.dart';
import '../entities/roadmap.dart';
import '../entities/vote_result.dart';

abstract interface class BoardRepository {
  /// Fetches paginated board items sorted by [sort] ('top' or 'new').
  Future<Either<Failure, BoardPage>> getBoard({
    String sort = 'top',
    String? cursor,
    int limit = 25,
    CancelToken? cancelToken,
  });

  /// Fetches roadmap items grouped by status (planned, in_progress, shipped).
  Future<Either<Failure, Roadmap>> getRoadmap({
    CancelToken? cancelToken,
  });

  /// Adds an upvote from the current device for [itemId].
  Future<Either<Failure, VoteResult>> voteItem({
    required String itemId,
    CancelToken? cancelToken,
  });

  /// Removes an upvote from the current device for [itemId].
  Future<Either<Failure, VoteResult>> unvoteItem({
    required String itemId,
    CancelToken? cancelToken,
  });
}
