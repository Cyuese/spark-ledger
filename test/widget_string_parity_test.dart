import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// 桌面上显示的文字只维护在 Android `strings.xml`（应用内文案在 ARB），唯一重叠的是
/// **模板规范名**——选择器要用原生资源、应用内宫格与说明要用 ARB。这里强制两者一致，
/// 并保证原生资源里没有死文案，避免再出现「同一个组件几套名字」。
const Map<String, String> _templateNames = <String, String>{
  'widget_template_quick_entry': 'widgetTemplateQuickEntry',
  'widget_template_budget': 'widgetTemplateBudget',
  'widget_template_trend': 'widgetTemplateTrend',
  'widget_template_net_worth': 'widgetTemplateNetWorth',
};

String _resource(String xml, String name) {
  final match = RegExp(
    '<string name="${RegExp.escape(name)}">(.*?)</string>',
    dotAll: true,
  ).firstMatch(xml);
  expect(match, isNotNull, reason: 'Android 资源缺少 $name');
  return match!.group(1)!;
}

void main() {
  final zhStrings = File(
    'android/app/src/main/res/values/strings.xml',
  ).readAsStringSync();
  final enStrings = File(
    'android/app/src/main/res/values-en/strings.xml',
  ).readAsStringSync();
  final zhArb =
      jsonDecode(File('lib/l10n/app_zh.arb').readAsStringSync())
          as Map<String, dynamic>;
  final enArb =
      jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync())
          as Map<String, dynamic>;

  test('模板规范名在 Android 资源与应用内 l10n 完全一致', () {
    _templateNames.forEach((resourceName, arbKey) {
      expect(
        _resource(zhStrings, resourceName),
        zhArb[arbKey],
        reason: '$arbKey 的中文名与 $resourceName 不一致',
      );
      expect(
        _resource(enStrings, resourceName),
        enArb[arbKey],
        reason: '$arbKey 的英文名与 $resourceName 不一致',
      );
    });
  });

  test('Android 小组件文案没有一处是死资源', () {
    final names = RegExp(
      r'<string name="([^"]+)"',
    ).allMatches(zhStrings).map((m) => m.group(1)!).toList(growable: false);
    expect(names, isNotEmpty);
    final sources = <String>[
      File('android/app/src/main/AndroidManifest.xml').readAsStringSync(),
      for (final entity in Directory(
        'android/app/src/main',
      ).listSync(recursive: true))
        if (entity is File &&
            (entity.path.endsWith('.kt') || entity.path.endsWith('.xml')) &&
            !entity.path.endsWith('values/strings.xml') &&
            !entity.path.endsWith('values-en/strings.xml'))
          entity.readAsStringSync(),
    ].join('\n');
    for (final name in names) {
      expect(
        sources.contains('R.string.$name') || sources.contains('@string/$name'),
        isTrue,
        reason: '$name 在原生代码与清单里都没有引用',
      );
    }
  });

  test('已废弃的「用户小组件」文案与资源不再存在', () {
    for (final name in <String>[
      'user_widget_description',
      'user_widget_picker_label',
      'user_widget_choose_design',
      'user_widget_add',
      'user_widget_default_name',
      'user_widget_empty',
      'widget_instance_config_title',
      'widget_instance_secondary',
      'widget_instance_hide_amounts',
      'widget_refresh_required',
      'widget_quick_entry_title',
      'widget_chart_content_description',
      'widget_budget_ring_content_description',
    ]) {
      expect(
        zhStrings.contains('name="$name"'),
        isFalse,
        reason: '仍存在死文案 $name',
      );
      expect(enStrings.contains('name="$name"'), isFalse, reason: name);
    }
    for (final path in <String>[
      'android/app/src/main/res/drawable/user_widget_preview.xml',
      'android/app/src/main/res/drawable/widget_background.xml',
      'android/app/src/main/res/drawable/widget_background_white.xml',
      'android/app/src/main/res/drawable/widget_background_teal.xml',
      'android/app/src/main/res/drawable/widget_background_navy.xml',
      'android/app/src/main/res/drawable/widget_background_ink.xml',
      'android/app/src/main/res/drawable/widget_background_indigo.xml',
      'android/app/src/main/res/drawable/widget_button_background.xml',
      'android/app/src/main/res/values/colors.xml',
      'android/app/src/main/res/values-night/colors.xml',
    ]) {
      expect(File(path).existsSync(), isFalse, reason: '仍存在死资源 $path');
    }
  });
}
