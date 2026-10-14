import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/vote_result.dart';
import '../repositories/board_repository.dart';

class UnvoteItemUseCase {
  final BoardRepository _repository;

  UnvoteItemUseCase(this._repository);

  Future<Either<Failure, VoteResult>> call({
    required String itemId,
    CancelToken? cancelToken,
  }) {
    return _repository.unvoteItem(
      itemId: itemId,
      cancelToken: cancelToken,
    );
  }
}
