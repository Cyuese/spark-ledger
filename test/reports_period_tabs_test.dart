import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/local_storage/local_storage.dart';

import 'support/test_harness.dart';

// 看板顶部按统计口径分 Tab：日常 / 月统计 / 年统计 / 自定义。
//
// 当前阶段只有「月统计」有内容，其余 Tab 只画 Tab 本体、内容为空（不加任何
// 占位文案）。注意：最终默认 Tab 是「日常」，但在「日常」的面板落地前，
// 默认仍停在「月统计」，避免入口打开就是空白页——届时本测试要一起更新。
void main() {
  useTestDatabases();

  testWidgets('看板 Tab 切换：月统计保留内容，其余 Tab 为空', (tester) async {
    await pumpApp(tester, LocalKeyValueStore());
    await tapBottomTab(tester, 2); // 看板
    await tester.pumpAndSettle();

    final monthlyEntry = find.byKey(
      const Key('panel_settings_entry_reportsMonthly'),
    );
    Finder tabLabel(String label) => find.text(label).first;
    Finder selectedTab(String name) =>
        find.byKey(Key('reports_tab_selected_$name'));

    // 四个 Tab 都在。
    for (final label in <String>['日常', '月统计', '年统计', '自定义']) {
      expect(find.text(label), findsWidgets, reason: '缺少 Tab：$label');
    }
    // 默认选中月统计。
    expect(selectedTab('monthly'), findsOneWidget);

    // 年统计 / 自定义 / 日常都是空 Tab：没有面板，也没有面板管理入口。
    // 先切 Tab 再滚动——列表是懒加载的，滚到底部后顶部 Tab 条会被回收。
    await tester.tap(tabLabel('年统计'));
    await tester.pumpAndSettle();
    expect(selectedTab('yearly'), findsOneWidget);
    expect(monthlyEntry, findsNothing);

    await tester.tap(tabLabel('自定义'));
    await tester.pumpAndSettle();
    expect(selectedTab('custom'), findsOneWidget);
    expect(monthlyEntry, findsNothing);

    await tester.tap(tabLabel('日常'));
    await tester.pumpAndSettle();
    expect(selectedTab('daily'), findsOneWidget);
    expect(monthlyEntry, findsNothing);

    // 切回月统计：内容与改动前一致（摘要卡 + 六个面板 + 管理入口）。
    await tester.tap(tabLabel('月统计'));
    await tester.pumpAndSettle();
    expect(selectedTab('monthly'), findsOneWidget);
    await tester.scrollUntilVisible(
      monthlyEntry,
      200,
      scrollable: firstVerticalScrollable(),
    );
    expect(monthlyEntry, findsOneWidget);
    expect(find.text('6个月统计面板'), findsOneWidget);
  });
}
