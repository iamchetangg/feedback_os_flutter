import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../repositories/feedback_repository.dart';

class IdentifyUserUseCase {
  final FeedbackRepository _repository;

  const IdentifyUserUseCase(this._repository);

  Future<Either<Failure, void>> call(
    String? externalUserId, {
    CancelToken? cancelToken,
  }) {
    return _repository.identify(externalUserId, cancelToken: cancelToken);
  }
}
