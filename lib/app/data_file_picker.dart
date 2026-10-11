import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;

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

/// 选择账单文件并读原始字节（编码/格式由调用方按平台判别）。[extensions] 过滤
/// 可选文件类型（如支付宝/薄荷 csv、微信 xlsx）。用户取消返回 null。
Future<Uint8List?> pickImportBytes({
  required List<String> extensions,
  String label = '账单文件',
}) async {
  final group = XTypeGroup(label: label, extensions: extensions);
  final file = await openFile(acceptedTypeGroups: <XTypeGroup>[group]);
  if (file == null) {
    return null;
  }
  final bytes = await file.readAsBytes();
  await _discardPickerCopy(file);
  return bytes;
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
  final text = utf8.decode(await file.readAsBytes());
  await _discardPickerCopy(file);
  return text;
}

/// `file_selector` 在 Android 上会把选中的文档整份复制到
/// `{cacheDir}/{uuid}/{原文件名}` 再返回该路径，读完即删，否则每次选文件都会在缓存里
/// 留下一份副本（账单可以反复导入，缓存会一直涨）。
///
/// 只删「父目录名是 UUID」的那份插件副本：桌面拿到的是用户原文件，不会命中；插件将来
/// 改了目录布局最多只是留下一份副本，绝不误删用户文件。
Future<void> _discardPickerCopy(XFile file) async {
  try {
    if (!isPickerCacheCopyPath(file.path)) {
      return;
    }
    final copy = File(file.path);
    if (await copy.exists()) {
      await copy.delete();
    }
  } catch (_) {
    // 清理失败只会在缓存里留下一份副本，不影响本次导入；缓存本身由系统回收。
  }
}

/// 是否为 `file_selector` 在 Android 上生成的缓存副本路径
/// （`{cacheDir}/{uuid}/{原文件名}`）。桌面路径与用户自己的文件不会命中。
bool isPickerCacheCopyPath(String path) =>
    _pickerCopyDirectory.hasMatch(p.basename(p.dirname(path)));

final RegExp _pickerCopyDirectory = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
);
