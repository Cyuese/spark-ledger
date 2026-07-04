import 'dart:convert';

import 'package:file_selector/file_selector.dart';

import 'platform_bridge.dart';

/// 返回是否真正保存了文件;用户在保存对话框中取消时返回 false。
Future<bool> downloadTextFile({
  required String filename,
  required String content,
  String mimeType = 'application/json',
}) async {
  final savedToDownloads = await AppPlatformBridge.saveTextToDownloads(
    filename: filename,
    content: content,
    mimeType: mimeType,
  );
  if (savedToDownloads) {
    return true;
  }

  final location = await getSaveLocation(suggestedName: filename);
  if (location == null) {
    return false;
  }
  final file = XFile.fromData(
    utf8.encode(content),
    mimeType: mimeType,
    name: filename,
  );
  await file.saveTo(location.path);
  return true;
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
  return _readAsUtf8(file);
}

Future<String?> pickCsvFile() async {
  const csvGroup = XTypeGroup(
    label: 'CSV',
    extensions: <String>['csv', 'txt'],
    mimeTypes: <String>['text/csv', 'text/plain'],
  );
  final file = await openFile(acceptedTypeGroups: const <XTypeGroup>[csvGroup]);
  return _readAsUtf8(file);
}

/// 显式按 UTF-8 解码，不用 `XFile.readAsString()`：后者在 Android 上对
/// `content://` 选中的文件可能按平台默认编码解码，导致中文变乱码。与备份恢复
/// 路径（`backup_storage_io.dart`）保持一致。
Future<String?> _readAsUtf8(XFile? file) async {
  if (file == null) {
    return null;
  }
  return utf8.decode(await file.readAsBytes());
}
