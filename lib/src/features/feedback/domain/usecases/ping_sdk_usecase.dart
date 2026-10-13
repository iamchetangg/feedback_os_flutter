import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/sdk_ping_entity.dart';
import '../repositories/feedback_repository.dart';

class PingSdkUseCase {
  final FeedbackRepository _repository;

  const PingSdkUseCase(this._repository);

  Future<Either<Failure, SdkPingResult>> call({
    CancelToken? cancelToken,
  }) {
    return _repository.ping(cancelToken: cancelToken);
  }
}
