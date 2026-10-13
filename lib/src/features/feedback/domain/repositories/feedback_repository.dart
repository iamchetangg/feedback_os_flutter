import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/sdk_config_entity.dart';
import '../entities/sdk_ping_entity.dart';

abstract interface class FeedbackRepository {
  Future<Either<Failure, SdkConfig>> getConfig(
    String publishableKey, {
    CancelToken? cancelToken,
  });

  Future<Either<Failure, SdkPingResult>> ping({
    CancelToken? cancelToken,
  });

  Future<Either<Failure, void>> identify(
    String? externalUserId, {
    CancelToken? cancelToken,
  });
}
