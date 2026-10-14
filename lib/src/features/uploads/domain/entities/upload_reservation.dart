import 'package:equatable/equatable.dart';

/// Represents a presigned upload reservation returned by the FeedbackOS API.
class UploadReservation extends Equatable {
  /// Unique identifier of the reserved upload (UUIDv4).
  final String uploadId;

  /// HTTP method to use for uploading the binary content (typically 'PUT').
  final String method;

  /// Presigned destination URL (e.g., Cloudflare R2 bucket URL).
  final Uri url;

  /// Exact headers required by the presigned upload request.
  final Map<String, String> headers;

  /// Timestamp when the presigned upload URL expires.
  final DateTime expiresAt;

  const UploadReservation({
    required this.uploadId,
    required this.method,
    required this.url,
    required this.headers,
    required this.expiresAt,
  });

  /// Checks whether the reservation has expired or is about to expire within the given buffer.
  bool isExpired({Duration buffer = const Duration(seconds: 30)}) {
    return DateTime.now().toUtc().isAfter(expiresAt.toUtc().subtract(buffer));
  }

  @override
  List<Object?> get props => [
        uploadId,
        method,
        url,
        headers,
        expiresAt,
      ];
}
