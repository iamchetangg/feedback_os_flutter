import 'package:equatable/equatable.dart';
import '../../uploads/domain/entities/screenshot_attachment.dart';
import '../domain/entities/feedback_type.dart';

sealed class FeedbackEvent extends Equatable {
  const FeedbackEvent();

  @override
  List<Object?> get props => [];
}

final class FeedbackFormStarted extends FeedbackEvent {
  final FeedbackType initialType;
  final List<ScreenshotAttachment> initialAttachments;

  const FeedbackFormStarted({
    this.initialType = FeedbackType.bug,
    this.initialAttachments = const [],
  });

  @override
  List<Object?> get props => [initialType, initialAttachments];
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

final class FeedbackAttachmentAdded extends FeedbackEvent {
  final ScreenshotAttachment attachment;

  const FeedbackAttachmentAdded(this.attachment);

  @override
  List<Object?> get props => [attachment];
}

final class FeedbackAttachmentRemoved extends FeedbackEvent {
  final int index;

  const FeedbackAttachmentRemoved(this.index);

  @override
  List<Object?> get props => [index];
}

final class FeedbackSubmitted extends FeedbackEvent {
  const FeedbackSubmitted();
}

final class FeedbackReset extends FeedbackEvent {
  const FeedbackReset();
}
