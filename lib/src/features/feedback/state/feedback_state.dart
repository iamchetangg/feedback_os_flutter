import 'package:equatable/equatable.dart';
import '../domain/entities/feedback_submit_result.dart';
import '../domain/entities/feedback_type.dart';

enum FeedbackFormStatus {
  initial,
  loadingConfig,
  ready,
  submitting,
  success,
  failure,
}

class FeedbackState extends Equatable {
  final FeedbackFormStatus status;
  final FeedbackType type;
  final String title;
  final String description;
  final String? category;
  final List<String> availableCategories;
  final FeedbackSubmitResult? submissionResult;
  final String? errorMessage;

  const FeedbackState({
    this.status = FeedbackFormStatus.initial,
    this.type = FeedbackType.bug,
    this.title = '',
    this.description = '',
    this.category,
    this.availableCategories = const [],
    this.submissionResult,
    this.errorMessage,
  });

  bool get isSubmitting => status == FeedbackFormStatus.submitting;
  bool get isSuccess => status == FeedbackFormStatus.success;
  bool get isFailure => status == FeedbackFormStatus.failure;
  bool get canSubmit =>
      title.trim().isNotEmpty && status != FeedbackFormStatus.submitting;

  FeedbackState copyWith({
    FeedbackFormStatus? status,
    FeedbackType? type,
    String? title,
    String? description,
    String? Function()? category,
    List<String>? availableCategories,
    FeedbackSubmitResult? submissionResult,
    String? errorMessage,
  }) {
    return FeedbackState(
      status: status ?? this.status,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category != null ? category() : this.category,
      availableCategories: availableCategories ?? this.availableCategories,
      submissionResult: submissionResult ?? this.submissionResult,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        type,
        title,
        description,
        category,
        availableCategories,
        submissionResult,
        errorMessage,
      ];
}
