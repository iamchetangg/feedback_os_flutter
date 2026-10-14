import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/thread_reply.dart';
import '../repositories/threads_repository.dart';

class SendReplyUseCase {
  final ThreadsRepository _repository;

  SendReplyUseCase(this._repository);

  Future<Either<Failure, ThreadReply>> call({
    required String itemId,
    required String message,
    CancelToken? cancelToken,
  }) {
    final trimmed = message.trim();
    if (trimmed.isEmpty) {
      return Future.value(
        const Left(ValidationFailure('Reply message cannot be empty.')),
      );
    }

    return _repository.sendReply(
      itemId: itemId,
      message: trimmed,
      cancelToken: cancelToken,
    );
  }
}
