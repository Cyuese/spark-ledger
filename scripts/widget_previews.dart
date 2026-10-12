import 'dart:io';

import 'src/widget_previews.dart';

/// 重导出选择器预览 PNG。
///
/// 预览图由**真机渲染器**产出（同一套 Glance 组合），因此改组件视觉后必须重跑：
/// 1. 构建 debug 包与仪器测试包（`github` flavor）；
/// 2. 安装到设备并运行 `WidgetGlanceInstrumentationTest`；
/// 3. 把 `sample-*.png` 拉回仓库并落到四个 drawable 变体目录，
///    状态确认图（未配置 / 无数据 / 正常）留在被忽略的 `build/widget-previews/`。
///
/// 用法：`dart run scripts/widget_previews.dart`（需要一台已授权设备或模拟器）。
Future<void> main(List<String> args) async {
  final root = Directory.current;
  final adb = _adbPath();
  final device = _onlyDevice(adb);
  stdout.writeln('设备：$device');

  final gradlew = Platform.isWindows ? 'gradlew.bat' : './gradlew';
  // 用绝对路径：cmd 在 workingDirectory 里解析相对路径会失败。
  final gradleExecutable = File('android/$gradlew').absolute.path;
  _run(gradleExecutable, <String>[
    ':app:assembleGithubDebug',
    ':app:assembleGithubDebugAndroidTest',
  ], workingDirectory: 'android');

  final apks = _findApks(root);
  // 主包先装、测试包后装：测试包的签名必须与已安装的主包一致才能被系统接受。
  for (final apk
      in apks..sort(
        (a, b) => (a.path.contains('androidTest') ? 1 : 0).compareTo(
          b.path.contains('androidTest') ? 1 : 0,
        ),
      )) {
    _run(adb, <String>['-s', device, 'install', '-r', '-t', apk.path]);
  }

  _run(adb, <String>[
    '-s',
    device,
    'shell',
    'am',
    'instrument',
    '-w',
    '-e',
    'class',
    'top.talyra42.verifin.WidgetGlanceInstrumentationTest',
    'top.talyra42.verifin.test/androidx.test.runner.AndroidJUnitRunner',
  ]);

  const remote =
      '/sdcard/Android/data/top.talyra42.verifin/files/widget-previews';
  final staging = Directory('build/widget-previews')
    ..createSync(recursive: true);
  _run(adb, <String>['-s', device, 'pull', remote, staging.path]);

  final source = Directory('${staging.path}/widget-previews');
  final exported = source.existsSync() ? source : staging;
  var written = 0;
  for (final file in exported.listSync().whereType<File>()) {
    final target = previewTargetFor(file.uri.pathSegments.last);
    if (target == null) continue;
    final destination = File(target)..parent.createSync(recursive: true);
    destination.writeAsBytesSync(file.readAsBytesSync());
    written++;
    stdout.writeln('写入 $target');
  }
  stdout.writeln('完成：更新 $written 张预览图；状态确认图见 ${exported.path}。');
  if (written == 0) {
    stderr.writeln('没有找到任何 sample-*.png，预览图未更新。');
    exitCode = 1;
  }
}

String _adbPath() {
  final fromEnv =
      Platform.environment['ANDROID_HOME'] ??
      Platform.environment['ANDROID_SDK_ROOT'];
  if (fromEnv != null && fromEnv.isNotEmpty) {
    final candidate = File(
      '$fromEnv${Platform.pathSeparator}platform-tools'
      '${Platform.pathSeparator}adb${Platform.isWindows ? '.exe' : ''}',
    );
    if (candidate.existsSync()) return candidate.path;
  }
  return 'adb';
}

String _onlyDevice(String adb) {
  final result = Process.runSync(adb, <String>['devices']);
  final devices = (result.stdout as String)
      .split('\n')
      .where((line) => line.contains('\tdevice'))
      .map((line) => line.split('\t').first.trim())
      .toList(growable: false);
  if (devices.isEmpty) {
    stderr.writeln('没有已授权的设备，请先启动模拟器或连接手机。');
    exit(1);
  }
  if (devices.length > 1) {
    stderr.writeln('检测到多台设备：${devices.join(', ')}；请只保留一台。');
    exit(1);
  }
  return devices.first;
}

List<File> _findApks(Directory root) {
  // Flutter 把 Android 的构建输出重定向到仓库根的 build/app。
  final outputs = Directory('${root.path}/build/app/outputs/apk');
  if (!outputs.existsSync()) {
    stderr.writeln('没有找到构建产物目录 ${outputs.path}');
    exit(1);
  }
  final apks = outputs
      .listSync(recursive: true)
      .whereType<File>()
      .where((file) => file.path.endsWith('.apk'))
      .toList(growable: false);
  final app = apks.where((file) => file.path.contains('github'));
  if (app.isEmpty) {
    stderr.writeln('没有找到 github flavor 的 APK。');
    exit(1);
  }
  return app.toList(growable: false);
}

void _run(String executable, List<String> args, {String? workingDirectory}) {
  stdout.writeln('> $executable ${args.join(' ')}');
  final result = Process.runSync(
    executable,
    args,
    workingDirectory: workingDirectory,
    runInShell: Platform.isWindows,
  );
  final output = '${result.stdout}${result.stderr}'.trim();
  if (output.isNotEmpty) {
    stdout.writeln(output);
  }
  if (result.exitCode != 0) {
    stderr.writeln(
      '命令失败（exit ${result.exitCode}）：$executable ${args.join(' ')}',
    );
    exit(result.exitCode);
  }
}
