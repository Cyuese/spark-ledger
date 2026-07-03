import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

Future<String?> pickRawImageDataUrl() async {
  final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
  if (picked == null) {
    return null;
  }
  final bytes = await picked.readAsBytes();
  final mimeType = picked.mimeType ?? _mimeTypeForPath(picked.path);
  return 'data:$mimeType;base64,${base64Encode(bytes)}';
}

Future<String?> cropImageDataUrl({
  required String sourceDataUrl,
  required int targetWidth,
  required int targetHeight,
  required double zoom,
  required double offsetX,
  required double offsetY,
}) async {
  final bytes = _bytesFromDataUrl(sourceDataUrl);
  if (bytes == null) {
    return sourceDataUrl;
  }
  final source = img.decodeImage(bytes);
  if (source == null || source.width == 0 || source.height == 0) {
    return sourceDataUrl;
  }

  final targetRatio = targetWidth / targetHeight;
  final sourceRatio = source.width / source.height;
  late final double baseCropWidth;
  late final double baseCropHeight;

  if (sourceRatio > targetRatio) {
    baseCropHeight = source.height.toDouble();
    baseCropWidth = baseCropHeight * targetRatio;
  } else {
    baseCropWidth = source.width.toDouble();
    baseCropHeight = baseCropWidth / targetRatio;
  }

  final effectiveZoom = zoom.clamp(1.0, 3.0);
  final cropWidth = baseCropWidth / effectiveZoom;
  final cropHeight = baseCropHeight / effectiveZoom;
  final maxOffsetX = math.max(0, source.width - cropWidth) / 2;
  final maxOffsetY = math.max(0, source.height - cropHeight) / 2;
  final centerX = source.width / 2 + offsetX.clamp(-1.0, 1.0) * maxOffsetX;
  final centerY = source.height / 2 + offsetY.clamp(-1.0, 1.0) * maxOffsetY;
  final cropX = (centerX - cropWidth / 2)
      .clamp(0, source.width - cropWidth)
      .round();
  final cropY = (centerY - cropHeight / 2)
      .clamp(0, source.height - cropHeight)
      .round();

  final cropped = img.copyCrop(
    source,
    x: cropX,
    y: cropY,
    width: cropWidth.round().clamp(1, source.width),
    height: cropHeight.round().clamp(1, source.height),
  );
  final resized = img.copyResize(
    cropped,
    width: targetWidth,
    height: targetHeight,
    interpolation: img.Interpolation.average,
  );
  final encoded = img.encodeJpg(resized, quality: 86);
  return 'data:image/jpeg;base64,${base64Encode(encoded)}';
}

Uint8List? _bytesFromDataUrl(String dataUrl) {
  final commaIndex = dataUrl.indexOf(',');
  if (commaIndex == -1) {
    return null;
  }
  try {
    return base64Decode(dataUrl.substring(commaIndex + 1));
  } on FormatException {
    return null;
  }
}

String _mimeTypeForPath(String path) {
  final lower = path.toLowerCase();
  if (lower.endsWith('.png')) {
    return 'image/png';
  }
  if (lower.endsWith('.webp')) {
    return 'image/webp';
  }
  return 'image/jpeg';
}
