import 'package:equatable/equatable.dart';
import 'feedback_device_info.dart';
import 'feedback_type.dart';

/// Domain entity representing a pending or active feedback submission.
class FeedbackSubmission extends Equatable {
  /// Stable idempotency key generated on client (8–64 chars).
  final String clientSubmissionId;

  /// Type: bug or feature.
  final FeedbackType type;

  /// Brief headline for the report.
  final String title;

  /// Detailed description or reproduction steps. Defaults to empty string.
  final String description;

  /// Optional category (e.g., 'UX', 'Billing'). Max 50 chars.
  final String? category;

  /// Optional platform identifier (e.g. 'ios', 'android', 'macos', 'web').
  final String? platform;

  /// Platform device metadata.
  final FeedbackDeviceInfo device;

  /// Upload IDs of presigned uploaded screenshots. Max 3.
  final List<String> screenshotUploadIds;

  const FeedbackSubmission({
    required this.clientSubmissionId,
    required this.type,
    required this.title,
    this.description = '',
    this.category,
    this.platform,
    required this.device,
    this.screenshotUploadIds = const [],
  });

  /// Validates model constraints against OpenAPI specification.
  void validate() {
    if (clientSubmissionId.length < 8 || clientSubmissionId.length > 64) {
      throw ArgumentError(
        'clientSubmissionId must be between 8 and 64 characters.',
      );
    }
    if (title.trim().isEmpty) {
      throw ArgumentError('title cannot be empty.');
    }
    if (category != null && category!.length > 50) {
      throw ArgumentError('category cannot exceed 50 characters.');
    }
    if (screenshotUploadIds.length > 3) {
      throw ArgumentError('Cannot attach more than 3 screenshots.');
    }
  }

  @override
  List<Object?> get props => [
        clientSubmissionId,
        type,
        title,
        description,
        category,
        platform,
        device,
        screenshotUploadIds,
      ];
}
