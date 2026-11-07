import 'dart:math' as math;
import 'dart:typed_data';
import 'package:feedback_os_flutter/src/core/utils/image_compressor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;

void main() {
  group('ImageCompressor Tests', () {
    test('preserves small image without re-encoding when already under 256 KB', () {
      final image = img.Image(width: 100, height: 100);
      img.fill(image, color: img.ColorRgba8(255, 0, 0, 255));
      final bytes = Uint8List.fromList(img.encodePng(image));

      expect(bytes.lengthInBytes, lessThan(256 * 1024));

      final attachment = ImageCompressor.compressAttachment(
        bytes: bytes,
        fileName: 'small_test.png',
      );

      expect(attachment.byteSize, equals(bytes.lengthInBytes));
      expect(attachment.contentType, equals('image/png'));
      expect(attachment.fileName, equals('small_test.png'));
    });

    test(
        'compresses large image to strictly under 256 KB while preserving original resolution',
        () {
      // Create a large image with random noise so PNG cannot compress it below 256 KB
      final random = math.Random(42);
      const width = 1200;
      const height = 800;
      final image = img.Image(width: width, height: height);
      for (int y = 0; y < height; y++) {
        for (int x = 0; x < width; x++) {
          image.setPixelRgba(
            x,
            y,
            random.nextInt(256),
            random.nextInt(256),
            random.nextInt(256),
            255,
          );
        }
      }

      // Encode as uncompressed / maximum quality PNG (will be well over 500 KB)
      final largeBytes = Uint8List.fromList(img.encodePng(image));
      expect(largeBytes.lengthInBytes, greaterThan(256 * 1024));

      final attachment = ImageCompressor.compressAttachment(
        bytes: largeBytes,
        fileName: 'screenshot_large.png',
      );

      // Verify size is strictly <= 256 KB
      expect(attachment.byteSize, lessThanOrEqualTo(256 * 1024));
      expect(attachment.contentType, equals('image/jpeg'));
      expect(attachment.fileName, equals('screenshot_large.jpg'));

      // Decode the compressed result and verify resolution is identical!
      final decodedCompressed = img.decodeImage(attachment.bytes);
      expect(decodedCompressed, isNotNull);
      expect(decodedCompressed!.width, equals(width));
      expect(decodedCompressed.height, equals(height));
    });
  });
}
