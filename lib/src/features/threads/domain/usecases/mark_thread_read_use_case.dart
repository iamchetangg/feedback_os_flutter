import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/threads_repository.dart';

class MarkThreadReadUseCase {
  final ThreadsRepository _repository;

  MarkThreadReadUseCase(this._repository);

  Future<Either<Failure, void>> call({
    required String itemId,
    CancelToken? cancelToken,
  }) {
    return _repository.markThreadRead(
      itemId: itemId,
      cancelToken: cancelToken,
    );
  }
}
