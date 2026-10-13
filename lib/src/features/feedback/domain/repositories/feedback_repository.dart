import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/feedback_item.dart';
import '../entities/feedback_submission.dart';
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

  Future<Either<Failure, FeedbackItem>> submitFeedback(
    FeedbackSubmission submission, {
    CancelToken? cancelToken,
  });
}
