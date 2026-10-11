import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// ARB 目录守卫：中英键集一致，且每个键都能在生产代码里找到引用。
///
/// 删除功能（页面、面板、旧设置）时最容易留下的垃圾就是没人再引用的文案键；
/// 这个测试让「文案单向堆积」在 CI 上立刻暴露，而不是等下一次全仓审查。
void main() {
  test('ARB 键中英一致且都被引用', () {
    Map<String, Object?> readArb(String path) =>
        jsonDecode(File(path).readAsStringSync()) as Map<String, Object?>;
    final zh = readArb('lib/l10n/app_zh.arb');
    final en = readArb('lib/l10n/app_en.arb');
    final zhKeys = zh.keys.where((key) => !key.startsWith('@')).toSet();
    final enKeys = en.keys.where((key) => !key.startsWith('@')).toSet();
    expect(zhKeys.difference(enKeys), isEmpty, reason: '英文 ARB 缺少这些键');
    expect(enKeys.difference(zhKeys), isEmpty, reason: '中文 ARB 缺少这些键');

    final body =
        [
              for (final dir in <String>['lib', 'android', 'test', 'scripts'])
                ...Directory(dir).listSync(recursive: true).whereType<File>(),
            ]
            .where((file) {
              final path = file.path.replaceAll(r'\', '/');
              return (path.endsWith('.dart') || path.endsWith('.kt')) &&
                  !path.contains('/l10n/app_localizations');
            })
            .map((file) => file.readAsStringSync())
            .join('\n');

    final unused =
        zhKeys
            .where(
              (key) => !RegExp('\\b${RegExp.escape(key)}\\b').hasMatch(body),
            )
            .toList()
          ..sort();
    expect(unused, isEmpty, reason: '这些 ARB 键已无任何引用：$unused');
  });
}
