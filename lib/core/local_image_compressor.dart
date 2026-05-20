import 'dart:convert';
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

class LocalImageCompressor {
  LocalImageCompressor._();

  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pickAndCompress({
    ImageSource source = ImageSource.gallery,
    int maxSide = 1280,
    int jpegQuality = 72,
  }) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 90);
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      return base64Encode(bytes);
    }

    final resized = _resizeIfNeeded(decoded, maxSide);
    final jpgBytes = img.encodeJpg(resized, quality: jpegQuality);
    return base64Encode(jpgBytes);
  }

  static img.Image _resizeIfNeeded(img.Image source, int maxSide) {
    final width = source.width;
    final height = source.height;
    final longest = width > height ? width : height;
    if (longest <= maxSide) return source;

    if (width >= height) {
      return img.copyResize(source, width: maxSide, interpolation: img.Interpolation.average);
    }
    return img.copyResize(source, height: maxSide, interpolation: img.Interpolation.average);
  }

  static Uint8List decodeBase64Image(String value) {
    return base64Decode(value);
  }
}
