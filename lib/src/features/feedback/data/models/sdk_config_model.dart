import '../../domain/entities/sdk_config_entity.dart';

class SdkBoardConfigModel extends SdkBoardConfig {
  const SdkBoardConfigModel({required super.enabled});

  factory SdkBoardConfigModel.fromJson(Map<String, dynamic> json) {
    return SdkBoardConfigModel(
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {'enabled': enabled};
}

class SdkRoadmapConfigModel extends SdkRoadmapConfig {
  const SdkRoadmapConfigModel({required super.enabled});

  factory SdkRoadmapConfigModel.fromJson(Map<String, dynamic> json) {
    return SdkRoadmapConfigModel(
      enabled: json['enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {'enabled': enabled};
}

class SdkLimitsConfigModel extends SdkLimitsConfig {
  const SdkLimitsConfigModel({
    required super.maxScreenshots,
    required super.maxScreenshotBytes,
    required super.screenshotTypes,
  });

  factory SdkLimitsConfigModel.fromJson(Map<String, dynamic> json) {
    return SdkLimitsConfigModel(
      maxScreenshots: json['max_screenshots'] as int? ?? 3,
      maxScreenshotBytes: json['max_screenshot_bytes'] as int? ?? 5242880,
      screenshotTypes: (json['screenshot_types'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['image/jpeg', 'image/png'],
    );
  }

  Map<String, dynamic> toJson() => {
        'max_screenshots': maxScreenshots,
        'max_screenshot_bytes': maxScreenshotBytes,
        'screenshot_types': screenshotTypes,
      };
}

class SdkConfigModel extends SdkConfig {
  const SdkConfigModel({
    required super.appId,
    required super.configVersion,
    required super.enabled,
    required super.board,
    required super.roadmap,
    required super.categories,
    required super.statuses,
    required super.limits,
  });

  factory SdkConfigModel.fromJson(Map<String, dynamic> json) {
    return SdkConfigModel(
      appId: json['app_id'] as String? ?? '',
      configVersion: json['config_version'] as int? ?? 1,
      enabled: json['enabled'] as bool? ?? false,
      board: SdkBoardConfigModel.fromJson(
        (json['board'] as Map<String, dynamic>?) ?? {},
      ),
      roadmap: SdkRoadmapConfigModel.fromJson(
        (json['roadmap'] as Map<String, dynamic>?) ?? {},
      ),
      categories: (json['categories'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      statuses: (json['statuses'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      limits: SdkLimitsConfigModel.fromJson(
        (json['limits'] as Map<String, dynamic>?) ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'app_id': appId,
        'config_version': configVersion,
        'enabled': enabled,
        'board': (board as SdkBoardConfigModel).toJson(),
        'roadmap': (roadmap as SdkRoadmapConfigModel).toJson(),
        'categories': categories,
        'statuses': statuses,
        'limits': (limits as SdkLimitsConfigModel).toJson(),
      };
}
