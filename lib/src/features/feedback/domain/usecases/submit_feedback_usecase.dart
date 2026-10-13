import 'package:dio/dio.dart';
import 'package:fpdart/fpdart.dart';
import '../../../../core/errors/failures.dart';
import '../entities/feedback_item.dart';
import '../entities/feedback_submission.dart';
import '../repositories/feedback_repository.dart';

class SubmitFeedbackUseCase {
  final FeedbackRepository _repository;

  const SubmitFeedbackUseCase(this._repository);

  Future<Either<Failure, FeedbackItem>> call(
    FeedbackSubmission submission, {
    CancelToken? cancelToken,
  }) {
    return _repository.submitFeedback(submission, cancelToken: cancelToken);
  }
}
