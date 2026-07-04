import 'backup_settings.dart';

/// Web 端不提供持久化备份目录（无 SAF），备份走浏览器下载流。
class PickedBackupDirectory {
  const PickedBackupDirectory({required this.uri, required this.label});

  final String uri;
  final String label;
}

Future<PickedBackupDirectory?> pickBackupDirectory() async {
  throw UnsupportedError('Web 端不支持选择备份目录，请使用导出下载');
}

Future<String?> writeBackupFile({
  required String directoryUri,
  required String filename,
  required String content,
  String mimeType = 'application/json',
}) async {
  throw UnsupportedError('Web 端不支持写入备份目录');
}

Future<List<BackupFileInfo>> listBackupFiles(String directoryUri) async {
  return const <BackupFileInfo>[];
}

Future<String?> readBackupFile(String fileUri) async {
  throw UnsupportedError('Web 端不支持读取备份文件');
}

Future<bool> deleteBackupFile(String fileUri) async {
  return false;
}
