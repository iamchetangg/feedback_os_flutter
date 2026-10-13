import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/sdk_config_entity.dart';
import '../repositories/feedback_repository.dart';

class GetSdkConfigUseCase {
  final FeedbackRepository _repository;

  const GetSdkConfigUseCase(this._repository);

  Future<Either<Failure, SdkConfig>> call(
    String publishableKey, {
    CancelToken? cancelToken,
  }) {
    return _repository.getConfig(publishableKey, cancelToken: cancelToken);
  }
}
