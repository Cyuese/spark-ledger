import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/backup/backup_storage.dart';

/// 恢复入口的契约测试（Issue 45 回归）。
///
/// 背景：`file_selector` 在 Android 上**不会**返回 `content://`，而是把整份文件读进
/// `byte[]`、再复制一份到 `cache/<uuid>/<name>` 后返回这个**普通路径**。旧代码把它当
/// `content://` 交给 `ContentResolver`，于是任何恢复都报
/// `No content provider: /data/user/0/.../cache/<uuid>/verifin-backup-*.zip`。
///
/// 这里守住三件事：Dart 侧调用的原生方法都存在、原生侧兼容普通路径、临时文件归属明确。
void main() {
  final mainActivity = File(
    'android/app/src/main/kotlin/top/talyra42/verifin/MainActivity.kt',
  ).readAsStringSync();

  List<String> channelMethodsCalledFromDart() {
    final sources = Directory('lib/app')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where(
          (file) => file.uri.pathSegments.last.startsWith('platform_bridge'),
        )
        .map((file) => file.readAsStringSync())
        .join('\n');
    final pattern = RegExp(
      r"invoke(?:Method|MapMethod|ListMethod)<[^()]*>\(\s*'([A-Za-z]+)'",
    );
    return pattern
        .allMatches(sources)
        .map((match) => match.group(1)!)
        .toSet()
        .toList()
      ..sort();
  }

  test('Dart 侧调用的每个原生方法都在 MainActivity 分发', () {
    final methods = channelMethodsCalledFromDart();
    expect(methods, isNotEmpty);
    for (final method in methods) {
      expect(
        mainActivity,
        contains('"$method" ->'),
        reason: 'MainActivity 的 MethodChannel 分发缺少 $method',
      );
    }
  });

  test('备份文件选择走自带 SAF 选择器，不经过 file_selector', () {
    expect(mainActivity, contains('"pickBackupFile" ->'));
    expect(mainActivity, contains('REQUEST_PICK_BACKUP_FILE'));
    expect(mainActivity, contains('Intent.ACTION_OPEN_DOCUMENT'));
    final storage = File(
      'lib/app/backup/backup_storage_io.dart',
    ).readAsStringSync();
    final picker = File(
      'lib/app/platform_bridge_storage.dart',
    ).readAsStringSync();
    // Android 分支必须用原生选择器（插件会把整份文件读进内存）。
    expect(picker, contains("'pickBackupFile'"));
    expect(storage, contains('AppStorageBridge.pickBackupFile()'));
    // 旧入口（把 file_selector 的返回值当 content:// 用）必须已经删除。
    expect(
      File('lib/app/data_file_picker.dart').readAsStringSync(),
      isNot(contains('pickBackupFileUri')),
    );
  });

  test('原生阶段读文件兼容普通路径，并声明临时文件归属', () {
    // `content://` 之外的输入（普通路径 / file://）不得再交给 ContentResolver。
    expect(mainActivity, contains('scheme == null -> File(fileUri)'));
    expect(mainActivity, contains('"owned" to false'));
    expect(mainActivity, contains('"owned" to true'));
    // 清理缓存允许 cacheDir 树下的子目录（插件副本住在 cache/<uuid>/）。
    expect(mainActivity, contains('startsWith(cachePrefix)'));
  });

  test('只删除本应用新建的临时副本', () {
    expect(
      File('lib/app/platform_bridge_storage.dart').readAsStringSync(),
      contains('this.owned = true'),
    );
    expect(
      File('lib/pages/data_management_page.dart').readAsStringSync(),
      contains('if (staged.owned)'),
    );
  });

  test('本地路径进入暂存不会声明归属（调用方不得删除用户文件）', () async {
    final dir = await Directory.systemTemp.createTemp('verifin_stage_contract');
    addTearDown(() async {
      if (await dir.exists()) {
        await dir.delete(recursive: true);
      }
    });
    final file = File('${dir.path}/verifin-backup-20260101-000000.zip');
    await file.writeAsBytes(const <int>[1, 2, 3, 4, 5]);

    // 测试宿主不是 Android，走本地分支：原样返回且不声明归属。
    final fromPlainPath = await stageBackupFileToCache(file.path);
    expect(fromPlainPath, isNotNull);
    expect(fromPlainPath!.path, file.path);
    expect(fromPlainPath.byteSize, 5);
    expect(fromPlainPath.owned, isFalse);

    final fromFileUri = await stageBackupFileToCache(file.uri.toString());
    expect(fromFileUri, isNotNull);
    expect(await File(fromFileUri!.path).readAsBytes(), <int>[1, 2, 3, 4, 5]);
    expect(fromFileUri.byteSize, 5);
    expect(fromFileUri.owned, isFalse);

    // 非本地 scheme 在本地分支无法读取，返回 null 而不是抛错。
    expect(await stageBackupFileToCache('content://fake/backup.zip'), isNull);
  });

  test('StagedCacheFile 默认声明归属，避免误删用户文件', () {
    const staged = StagedCacheFile(path: '/tmp/a', byteSize: 1);
    expect(staged.owned, isTrue);
  });

  test('MethodChannel 名与 MainActivity 一致', () {
    expect(mainActivity, contains('"verifin/app"'));
  });
}
