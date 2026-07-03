import 'dart:convert';

import 'package:file_selector/file_selector.dart';

Future<void> downloadTextFile({
  required String filename,
  required String content,
  String mimeType = 'application/json',
}) async {
  final location = await getSaveLocation(suggestedName: filename);
  if (location == null) {
    return;
  }
  final file = XFile.fromData(
    utf8.encode(content),
    mimeType: mimeType,
    name: filename,
  );
  await file.saveTo(location.path);
}

Future<String?> pickTextFile() async {
  const jsonGroup = XTypeGroup(
    label: 'JSON',
    extensions: <String>['json'],
    mimeTypes: <String>['application/json'],
  );
  final file = await openFile(
    acceptedTypeGroups: const <XTypeGroup>[jsonGroup],
  );
  return file?.readAsString();
}
