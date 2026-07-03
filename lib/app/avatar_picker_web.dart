// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:math' as math;
import 'dart:html' as html;

Future<String?> pickRawImageDataUrl() {
  final completer = Completer<String?>();
  final input = html.FileUploadInputElement()..accept = 'image/*';

  input.onChange.first.then((_) {
    final file = input.files?.isEmpty ?? true ? null : input.files!.first;
    if (file == null) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
      return;
    }
    final reader = html.FileReader();
    reader.onLoad.first.then((_) {
      if (!completer.isCompleted) {
        completer.complete(reader.result as String?);
      }
    });
    reader.onError.first.then((_) {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });
    reader.readAsDataUrl(file);
  });
  // 用户取消对话框时不会触发 change,监听 cancel 以完成 Future。
  input.on['cancel'].first.then((_) {
    if (!completer.isCompleted) {
      completer.complete(null);
    }
  });
  input.click();

  return completer.future;
}

Future<String?> cropImageDataUrl({
  required String sourceDataUrl,
  required int targetWidth,
  required int targetHeight,
  required double zoom,
  required double offsetX,
  required double offsetY,
}) async {
  final image = html.ImageElement(src: sourceDataUrl);
  // onError 不会让 onLoad 抛异常,必须显式竞争两个事件,
  // 否则加载失败时 Future 永久挂起。
  final loaded = await Future.any(<Future<bool>>[
    image.onLoad.first.then((_) => true),
    image.onError.first.then((_) => false),
  ]);
  if (!loaded) {
    return null;
  }

  final sourceWidth = image.naturalWidth;
  final sourceHeight = image.naturalHeight;
  if (sourceWidth == 0 || sourceHeight == 0) {
    return sourceDataUrl;
  }

  final targetRatio = targetWidth / targetHeight;
  final sourceRatio = sourceWidth / sourceHeight;
  late final double baseCropWidth;
  late final double baseCropHeight;

  if (sourceRatio > targetRatio) {
    baseCropHeight = sourceHeight.toDouble();
    baseCropWidth = baseCropHeight * targetRatio;
  } else {
    baseCropWidth = sourceWidth.toDouble();
    baseCropHeight = baseCropWidth / targetRatio;
  }

  final effectiveZoom = zoom.clamp(1.0, 3.0);
  final cropWidth = baseCropWidth / effectiveZoom;
  final cropHeight = baseCropHeight / effectiveZoom;
  final maxOffsetX = math.max(0, sourceWidth - cropWidth) / 2;
  final maxOffsetY = math.max(0, sourceHeight - cropHeight) / 2;
  // 预览把图片向 offset 方向平移,取景框内露出的是相反一侧,
  // 因此裁剪中心要向 offset 的反方向移动。
  final centerX = sourceWidth / 2 - offsetX.clamp(-1.0, 1.0) * maxOffsetX;
  final centerY = sourceHeight / 2 - offsetY.clamp(-1.0, 1.0) * maxOffsetY;
  final cropX = (centerX - cropWidth / 2).clamp(0, sourceWidth - cropWidth);
  final cropY = (centerY - cropHeight / 2).clamp(0, sourceHeight - cropHeight);

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
