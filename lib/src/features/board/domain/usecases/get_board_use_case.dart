import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/board_page.dart';
import '../repositories/board_repository.dart';

class GetBoardUseCase {
  final BoardRepository _repository;

  GetBoardUseCase(this._repository);

  Future<Either<Failure, BoardPage>> call({
    String sort = 'top',
    String? cursor,
    int limit = 25,
    CancelToken? cancelToken,
  }) {
    return _repository.getBoard(
      sort: sort,
      cursor: cursor,
      limit: limit,
      cancelToken: cancelToken,
    );
  }
}
