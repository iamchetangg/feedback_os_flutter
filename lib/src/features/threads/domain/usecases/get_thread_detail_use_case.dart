import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/thread_detail.dart';
import '../repositories/threads_repository.dart';

class GetThreadDetailUseCase {
  final ThreadsRepository _repository;

  GetThreadDetailUseCase(this._repository);

  Future<Either<Failure, ThreadDetail>> call({
    required String itemId,
    CancelToken? cancelToken,
  }) {
    return _repository.getThreadDetail(
      itemId: itemId,
      cancelToken: cancelToken,
    );
  }
}
