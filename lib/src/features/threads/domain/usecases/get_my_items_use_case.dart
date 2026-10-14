import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/my_feedback_item.dart';
import '../repositories/threads_repository.dart';

class GetMyItemsUseCase {
  final ThreadsRepository _repository;

  GetMyItemsUseCase(this._repository);

  Future<Either<Failure, List<MyFeedbackItem>>> call({
    CancelToken? cancelToken,
  }) {
    return _repository.getMyItems(cancelToken: cancelToken);
  }
}
