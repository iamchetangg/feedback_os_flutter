import 'dart:typed_data';
import 'package:equatable/equatable.dart';

/// Represents a local screenshot attachment ready for upload.
class ScreenshotAttachment extends Equatable {
  /// File name or identifier for display.
  final String fileName;

  /// MIME content type: must be 'image/jpeg' or 'image/png'.
  final String contentType;

  /// Binary raw image bytes.
  final Uint8List bytes;

  /// Associated upload ID once reserved and successfully transmitted.
  final String? uploadId;

  /// Optional local file path on disk (if sourced from disk).
  final String? localFilePath;

  const ScreenshotAttachment({
    required this.fileName,
    required this.contentType,
    required this.bytes,
    this.uploadId,
    this.localFilePath,
  });

  /// Size in bytes.
  int get byteSize => bytes.lengthInBytes;

  /// Maximum allowed size in bytes per the OpenAPI contract (5 MiB).
  static const int maxByteSize = 5242880;

  /// Allowed MIME types per OpenAPI contract.
  static const List<String> supportedMimeTypes = [
    'image/jpeg',
    'image/png',
  ];

  /// Validates that the attachment complies with FeedbackOS OpenAPI constraints.
  void validate() {
    if (!supportedMimeTypes.contains(contentType.toLowerCase())) {
      throw ArgumentError(
        'Unsupported image type "$contentType". Only image/jpeg and image/png are supported.',
      );
    }
    if (byteSize <= 0) {
      throw ArgumentError('Image file cannot be empty.');
    }
    if (byteSize > maxByteSize) {
      throw ArgumentError(
        'Image exceeds the maximum allowed size of 5 MiB (${(byteSize / (1024 * 1024)).toStringAsFixed(2)} MiB).',
      );
    }
  }

  ScreenshotAttachment copyWith({
    String? fileName,
    String? contentType,
    Uint8List? bytes,
    String? uploadId,
    String? localFilePath,
  }) {
    return ScreenshotAttachment(
      fileName: fileName ?? this.fileName,
      contentType: contentType ?? this.contentType,
      bytes: bytes ?? this.bytes,
      uploadId: uploadId ?? this.uploadId,
      localFilePath: localFilePath ?? this.localFilePath,
    );
  }

  @override
  List<Object?> get props => [
        fileName,
        contentType,
        bytes,
        uploadId,
        localFilePath,
      ];
}
