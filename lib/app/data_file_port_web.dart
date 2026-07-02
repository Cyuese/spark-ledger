// ignore_for_file: avoid_web_libraries_in_flutter, deprecated_member_use

import 'dart:async';
import 'dart:html' as html;

Future<void> downloadTextFile({
  required String filename,
  required String content,
  String mimeType = 'application/json',
}) async {
  final blob = html.Blob(<String>[content], mimeType);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..download = filename
    ..click();
  html.Url.revokeObjectUrl(url);
}

Future<String?> pickTextFile() {
  final completer = Completer<String?>();
  final input = html.FileUploadInputElement()
    ..accept = '.json,application/json'
    ..multiple = false;

  input.onChange.first.then((_) {
    final file = input.files?.isEmpty ?? true ? null : input.files!.first;
    if (file == null) {
      completer.complete(null);
      return;
    }

    final reader = html.FileReader();
    reader.onError.first.then((_) {
      if (!completer.isCompleted) {
        completer.completeError(StateError('读取文件失败'));
      }
    });
    reader.onLoad.first.then((_) {
      if (!completer.isCompleted) {
        completer.complete(reader.result as String?);
      }
    });
    reader.readAsText(file);
  });

  input.click();
  return completer.future;
}
