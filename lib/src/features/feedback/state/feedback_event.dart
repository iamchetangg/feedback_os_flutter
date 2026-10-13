import 'package:equatable/equatable.dart';
import '../domain/entities/feedback_type.dart';

sealed class FeedbackEvent extends Equatable {
  const FeedbackEvent();

  @override
  List<Object?> get props => [];
}

final class FeedbackFormStarted extends FeedbackEvent {
  final FeedbackType initialType;

  const FeedbackFormStarted({this.initialType = FeedbackType.bug});

  @override
  List<Object?> get props => [initialType];
}

final class FeedbackTypeChanged extends FeedbackEvent {
  final FeedbackType type;

  const FeedbackTypeChanged(this.type);

  @override
  List<Object?> get props => [type];
}

final class FeedbackTitleChanged extends FeedbackEvent {
  final String title;

  const FeedbackTitleChanged(this.title);

  @override
  List<Object?> get props => [title];
}

final class FeedbackDescriptionChanged extends FeedbackEvent {
  final String description;

  const FeedbackDescriptionChanged(this.description);

  @override
  List<Object?> get props => [description];
}

final class FeedbackCategoryChanged extends FeedbackEvent {
  final String? category;

  const FeedbackCategoryChanged(this.category);

  @override
  List<Object?> get props => [category];
}

final class FeedbackSubmitted extends FeedbackEvent {
  const FeedbackSubmitted();
}

final class FeedbackReset extends FeedbackEvent {
  const FeedbackReset();
}
