import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/unread_count.dart';
import '../repositories/threads_repository.dart';

class GetUnreadCountUseCase {
  final ThreadsRepository _repository;

  GetUnreadCountUseCase(this._repository);

  Future<Either<Failure, UnreadCount>> call({
    CancelToken? cancelToken,
  }) {
    return _repository.getUnreadCount(cancelToken: cancelToken);
  }
}
