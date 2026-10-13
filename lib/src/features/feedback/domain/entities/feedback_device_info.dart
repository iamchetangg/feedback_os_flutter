import 'package:equatable/equatable.dart';

/// Captures device environment metadata accompanying feedback submissions.
class FeedbackDeviceInfo extends Equatable {
  final String osVersion;
  final String appVersion;
  final String? build;
  final String deviceModel;
  final String? locale;

  const FeedbackDeviceInfo({
    required this.osVersion,
    required this.appVersion,
    this.build,
    required this.deviceModel,
    this.locale,
  });

  /// Creates a sanitized copy conforming strictly to OpenAPI length bounds.
  FeedbackDeviceInfo sanitized() {
    String truncate(String value, int maxLen) {
      final trimmed = value.trim();
      return trimmed.length > maxLen ? trimmed.substring(0, maxLen) : trimmed;
    }

    return FeedbackDeviceInfo(
      osVersion: truncate(osVersion.isEmpty ? 'unknown' : osVersion, 32),
      appVersion: truncate(appVersion.isEmpty ? '1.0.0' : appVersion, 32),
      build: build != null ? truncate(build!, 32) : null,
      deviceModel:
          truncate(deviceModel.isEmpty ? 'Generic Device' : deviceModel, 64),
      locale: locale != null ? truncate(locale!, 35) : null,
    );
  }

  @override
  List<Object?> get props =>
      [osVersion, appVersion, build, deviceModel, locale];
}
