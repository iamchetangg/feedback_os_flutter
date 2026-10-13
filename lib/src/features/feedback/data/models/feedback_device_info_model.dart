import '../../domain/entities/feedback_device_info.dart';

class FeedbackDeviceInfoModel extends FeedbackDeviceInfo {
  const FeedbackDeviceInfoModel({
    required super.osVersion,
    required super.appVersion,
    super.build,
    required super.deviceModel,
    super.locale,
  });

  factory FeedbackDeviceInfoModel.fromEntity(FeedbackDeviceInfo entity) {
    final sanitized = entity.sanitized();
    return FeedbackDeviceInfoModel(
      osVersion: sanitized.osVersion,
      appVersion: sanitized.appVersion,
      build: sanitized.build,
      deviceModel: sanitized.deviceModel,
      locale: sanitized.locale,
    );
  }

  factory FeedbackDeviceInfoModel.fromJson(Map<String, dynamic> json) {
    return FeedbackDeviceInfoModel(
      osVersion: json['os_version'] as String? ?? 'unknown',
      appVersion: json['app_version'] as String? ?? '1.0.0',
      build: json['build'] as String?,
      deviceModel: json['device_model'] as String? ?? 'Generic Device',
      locale: json['locale'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'os_version': osVersion,
      'app_version': appVersion,
      if (build != null && build!.isNotEmpty) 'build': build,
      'device_model': deviceModel,
      if (locale != null && locale!.isNotEmpty) 'locale': locale,
    };
  }
}
