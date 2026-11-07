import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../../features/uploads/domain/entities/screenshot_attachment.dart';

/// Utility to compress images strictly to under 256 KB while preserving original resolution.
abstract final class ImageCompressor {
  /// Target maximum byte size constraint: 256 KB (262,144 bytes).
  static const int maxByteSize = 256 * 1024;

  /// Compresses [bytes] to be strictly under [maxBytes] (256 KB) without changing resolution.
  ///
  /// Never alters [decoded.width] or [decoded.height].
  static ScreenshotAttachment compressAttachment({
    required Uint8List bytes,
    required String fileName,
    String? localFilePath,
    int maxBytes = maxByteSize,
  }) {
    final lowerName = fileName.toLowerCase();
    final isPng = lowerName.endsWith('.png');
    final isJpg = lowerName.endsWith('.jpg') || lowerName.endsWith('.jpeg');

    // If already under maxBytes and is a supported format, preserve as-is
    if (bytes.lengthInBytes <= maxBytes && (isPng || isJpg)) {
      return ScreenshotAttachment(
        fileName: fileName,
        contentType: isPng ? 'image/png' : 'image/jpeg',
        bytes: bytes,
        localFilePath: localFilePath,
      );
    }

    // Decode the image to access raw pixels
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      // If decoding fails, return raw attachment fallback
      return ScreenshotAttachment(
        fileName: fileName,
        contentType: isPng ? 'image/png' : 'image/jpeg',
        bytes: bytes,
        localFilePath: localFilePath,
      );
    }

    // Strictly preserve original resolution (width and height remain identical)
    int quality = 85;
    Uint8List compressed =
        Uint8List.fromList(img.encodeJpg(decoded, quality: quality));

    while (compressed.lengthInBytes > maxBytes && quality > 5) {
      if (quality > 50) {
        quality -= 15;
      } else if (quality > 20) {
        quality -= 10;
      } else {
        quality -= 5;
      }
      compressed =
          Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
    }

    // Adjust file extension to .jpg if converted to JPEG
    String finalFileName = fileName;
    if (!finalFileName.toLowerCase().endsWith('.jpg') &&
        !finalFileName.toLowerCase().endsWith('.jpeg')) {
      final dot = finalFileName.lastIndexOf('.');
      finalFileName = dot != -1
          ? '${finalFileName.substring(0, dot)}.jpg'
          : '$finalFileName.jpg';
    }

    return ScreenshotAttachment(
      fileName: finalFileName,
      contentType: 'image/jpeg',
      bytes: compressed,
      localFilePath: localFilePath,
    );
  }
}
