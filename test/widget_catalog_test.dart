import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/widgets/widget_catalog.dart';
import 'package:verifin/app/widgets/widget_projection.dart';

void main() {
  test('模板线上 key 与 Provider 映射稳定', () {
    expect(WidgetTemplate.values.map((t) => t.key).toList(), <String>[
      'quick_entry',
      'budget',
      'trend',
      'net_worth',
    ]);
    expect(
      WidgetTemplate.values.map((t) => t.providerComponent).toList(),
      <String>[
        'top.talyra42.verifin.QuickEntryWidgetProvider',
        'top.talyra42.verifin.BudgetWidgetProvider',
        'top.talyra42.verifin.TrendWidgetProvider',
        'top.talyra42.verifin.NetWorthWidgetProvider',
      ],
    );
    expect(WidgetTemplate.fromKey('net_worth'), WidgetTemplate.netWorth);
    expect(WidgetTemplate.fromKey('unknown'), isNull);
    expect(WidgetTemplate.fromKey(null), isNull);
  });

  test('外观默认跟随系统，未知值回退默认', () {
    expect(WidgetAppearance.fallback, WidgetAppearance.system);
    expect(WidgetAppearance.values.map((a) => a.key).toList(), <String>[
      'system',
      'light',
      'dark',
    ]);
    expect(WidgetAppearance.fromKey('dark'), WidgetAppearance.dark);
    expect(WidgetAppearance.fromKey('light'), WidgetAppearance.light);
    expect(WidgetAppearance.fromKey(null), WidgetAppearance.system);
    expect(WidgetAppearance.fromKey('sepia'), WidgetAppearance.system);
  });

  test('曲线窗口固定 30 个日历日', () {
    expect(widgetChartDays, 30);
  });

  test('投影快照版本与原生渲染层一致', () {
    final kotlin = File(
      'android/app/src/main/kotlin/top/talyra42/verifin/VeriFinWidget.kt',
    ).readAsStringSync();
    expect(
      kotlin,
      contains('const val SNAPSHOT_VERSION = $widgetSnapshotVersion'),
      reason: '快照结构改版时必须同时更新原生侧版本号',
    );
  });
}
