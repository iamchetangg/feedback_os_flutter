import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/vote_result.dart';
import '../repositories/board_repository.dart';

class VoteItemUseCase {
  final BoardRepository _repository;

  VoteItemUseCase(this._repository);

  Future<Either<Failure, VoteResult>> call({
    required String itemId,
    CancelToken? cancelToken,
  }) {
    return _repository.voteItem(
      itemId: itemId,
      cancelToken: cancelToken,
    );
  }
}
