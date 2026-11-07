import 'package:image_picker/image_picker.dart';
import '../../features/uploads/domain/entities/screenshot_attachment.dart';
import 'image_compressor.dart';

/// Default screenshot picker using [ImagePicker] from device gallery.
///
/// Automatically compresses the picked image strictly to under 256 KB
/// without modifying original resolution.
Future<ScreenshotAttachment?> defaultScreenshotPicker({
  ImagePicker? customPicker,
}) async {
  final picker = customPicker ?? ImagePicker();
  final pickedFile = await picker.pickImage(source: ImageSource.gallery);
  if (pickedFile == null) return null;

  final bytes = await pickedFile.readAsBytes();
  return ImageCompressor.compressAttachment(
    bytes: bytes,
    fileName: pickedFile.name.isNotEmpty ? pickedFile.name : 'screenshot.jpg',
    localFilePath: pickedFile.path,
  );
}
