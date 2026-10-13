import 'package:equatable/equatable.dart';

class SdkBoardConfig extends Equatable {
  final bool enabled;

  const SdkBoardConfig({required this.enabled});

  @override
  List<Object?> get props => [enabled];
}

class SdkRoadmapConfig extends Equatable {
  final bool enabled;

  const SdkRoadmapConfig({required this.enabled});

  @override
  List<Object?> get props => [enabled];
}

class SdkLimitsConfig extends Equatable {
  final int maxScreenshots;
  final int maxScreenshotBytes;
  final List<String> screenshotTypes;

  const SdkLimitsConfig({
    required this.maxScreenshots,
    required this.maxScreenshotBytes,
    required this.screenshotTypes,
  });

  @override
  List<Object?> get props =>
      [maxScreenshots, maxScreenshotBytes, screenshotTypes];
}

class SdkConfig extends Equatable {
  final String appId;
  final int configVersion;
  final bool enabled;
  final SdkBoardConfig board;
  final SdkRoadmapConfig roadmap;
  final List<String> categories;
  final List<String> statuses;
  final SdkLimitsConfig limits;

  const SdkConfig({
    required this.appId,
    required this.configVersion,
    required this.enabled,
    required this.board,
    required this.roadmap,
    required this.categories,
    required this.statuses,
    required this.limits,
  });

  @override
  List<Object?> get props => [
        appId,
        configVersion,
        enabled,
        board,
        roadmap,
        categories,
        statuses,
        limits,
      ];
}
