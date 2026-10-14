import '../../domain/entities/upload_reservation.dart';

/// Data Transfer Object representing the OpenAPI UploadResponse.
class UploadReservationModel extends UploadReservation {
  const UploadReservationModel({
    required super.uploadId,
    required super.method,
    required super.url,
    required super.headers,
    required super.expiresAt,
  });

  factory UploadReservationModel.fromJson(Map<String, dynamic> json) {
    final headersMap = (json['headers'] as Map<String, dynamic>?)?.map(
          (k, v) => MapEntry(k.toLowerCase(), v.toString()),
        ) ??
        const {};

    return UploadReservationModel(
      uploadId: json['upload_id'] as String,
      method: (json['method'] as String?)?.toUpperCase() ?? 'PUT',
      url: Uri.parse(json['url'] as String),
      headers: headersMap,
      expiresAt: DateTime.parse(json['expires_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'upload_id': uploadId,
      'method': method,
      'url': url.toString(),
      'headers': headers,
      'expires_at': expiresAt.toUtc().toIso8601String(),
    };
  }
}
