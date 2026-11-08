import '../../domain/entities/feedback_submission.dart';
import '../../domain/entities/feedback_type.dart';
import 'feedback_device_info_model.dart';

class FeedbackSubmissionModel extends FeedbackSubmission {
  const FeedbackSubmissionModel({
    required super.clientSubmissionId,
    required super.type,
    required super.title,
    super.description = '',
    super.category,
    super.platform,
    required super.device,
    super.screenshotUploadIds = const [],
  });

  factory FeedbackSubmissionModel.fromEntity(FeedbackSubmission entity) {
    entity.validate();
    return FeedbackSubmissionModel(
      clientSubmissionId: entity.clientSubmissionId,
      type: entity.type,
      title: entity.title.trim(),
      description: entity.description.trim(),
      category: entity.category?.trim(),
      platform: entity.platform?.trim(),
      device: FeedbackDeviceInfoModel.fromEntity(entity.device),
      screenshotUploadIds: entity.screenshotUploadIds,
    );
  }

  factory FeedbackSubmissionModel.fromJson(Map<String, dynamic> json) {
    return FeedbackSubmissionModel(
      clientSubmissionId: json['client_submission_id'] as String,
      type: FeedbackType.fromString(json['type'] as String),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      category: json['category'] as String?,
      platform: json['platform'] as String?,
      device: FeedbackDeviceInfoModel.fromJson(
        json['device'] as Map<String, dynamic>,
      ),
      screenshotUploadIds: (json['screenshot_upload_ids'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'client_submission_id': clientSubmissionId,
      'type': type.value,
      'title': title,
      'description': description,
      if (category != null && category!.isNotEmpty) 'category': category,
      if (platform != null && platform!.isNotEmpty) 'platform': platform,
      'device': FeedbackDeviceInfoModel.fromEntity(device).toJson(),
      'screenshot_upload_ids': screenshotUploadIds,
    };
  }
}
