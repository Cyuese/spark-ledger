// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

Future<String?> pickAvatarDataUrl() {
  return _pickImageDataUrl();
}

Future<String?> pickAssetCoverDataUrl() {
  return _pickImageDataUrl(cropWidth: 1200, cropHeight: 520);
}

Future<String?> _pickImageDataUrl({int? cropWidth, int? cropHeight}) {
  final completer = Completer<String?>();
  final input = html.FileUploadInputElement()
    ..accept = 'image/*'
    ..click();

  input.onChange.first.then((_) {
    final file = input.files?.isEmpty ?? true ? null : input.files!.first;
    if (file == null) {
      completer.complete(null);
      return;
    }
    final reader = html.FileReader();
    reader.onLoad.first.then((_) async {
      final dataUrl = reader.result as String?;
      if (dataUrl == null || cropWidth == null || cropHeight == null) {
        completer.complete(dataUrl);
        return;
      }
      completer.complete(
        await _centerCropDataUrl(
          dataUrl: dataUrl,
          targetWidth: cropWidth,
          targetHeight: cropHeight,
        ),
      );
    });
    reader.onError.first.then((_) => completer.complete(null));
    reader.readAsDataUrl(file);
  });

  return completer.future;
}

Future<String?> _centerCropDataUrl({
  required String dataUrl,
  required int targetWidth,
  required int targetHeight,
}) async {
  final image = html.ImageElement(src: dataUrl);
  try {
    await image.onLoad.first;
  } on Object {
    return dataUrl;
  }

  final sourceWidth = image.naturalWidth;
  final sourceHeight = image.naturalHeight;
  if (sourceWidth == 0 || sourceHeight == 0) {
    return dataUrl;
  }

  final targetRatio = targetWidth / targetHeight;
  final sourceRatio = sourceWidth / sourceHeight;
  late final num cropWidth;
  late final num cropHeight;
  late final num cropX;
  late final num cropY;

  if (sourceRatio > targetRatio) {
    cropHeight = sourceHeight;
    cropWidth = sourceHeight * targetRatio;
    cropX = (sourceWidth - cropWidth) / 2;
    cropY = 0;
  } else {
    cropWidth = sourceWidth;
    cropHeight = sourceWidth / targetRatio;
    cropX = 0;
    cropY = (sourceHeight - cropHeight) / 2;
  }

  final canvas = html.CanvasElement(width: targetWidth, height: targetHeight);
  final context = canvas.context2D;
  context.drawImageScaledFromSource(
    image,
    cropX,
    cropY,
    cropWidth,
    cropHeight,
    0,
    0,
    targetWidth,
    targetHeight,
  );
  return canvas.toDataUrl('image/jpeg', 0.86);
}
