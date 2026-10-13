import '../../domain/entities/sdk_ping_entity.dart';

class SdkPingModel extends SdkPingResult {
  const SdkPingModel({
    required super.ok,
    required super.appId,
  });

  factory SdkPingModel.fromJson(Map<String, dynamic> json) {
    return SdkPingModel(
      ok: json['ok'] as bool? ?? false,
      appId: json['app_id'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'ok': ok,
        'app_id': appId,
      };
}
