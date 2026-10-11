import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/local_storage/local_storage.dart';

import 'support/test_harness.dart';

// 看板顶部按统计口径分 Tab：日常 / 月统计 / 年统计 / 自定义。
//
// 默认落在「日常」，每个 Tab 各自持有一份面板清单；尚未实现的 Tab 只画 Tab
// 本体、内容为空（不加任何占位文案）。当前 Tab 不做持久化。
void main() {
  useTestDatabases();

  testWidgets('看板 Tab 切换：默认日常，月统计保留原内容，年统计/自定义为空', (tester) async {
    await pumpApp(tester, LocalKeyValueStore());
    await tapBottomTab(tester, 2); // 看板
    await tester.pumpAndSettle();

    final dailyEntry = find.byKey(
      const Key('panel_settings_entry_reportsDaily'),
    );
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
    // 默认选中日常，且日常已有面板（先不滚动：滚到底部会回收顶部 Tab 条）。
    expect(selectedTab('daily'), findsOneWidget);
    expect(find.text('近7日统计'), findsOneWidget);
    expect(monthlyEntry, findsNothing);

    // 年统计 / 自定义是空 Tab：没有面板，也没有面板管理入口。
    await tester.tap(tabLabel('年统计'));
    await tester.pumpAndSettle();
    expect(selectedTab('yearly'), findsOneWidget);
    expect(find.text('近7日统计'), findsNothing);
    expect(dailyEntry, findsNothing);
    expect(monthlyEntry, findsNothing);

    await tester.tap(tabLabel('自定义'));
    await tester.pumpAndSettle();
    expect(selectedTab('custom'), findsOneWidget);
    expect(dailyEntry, findsNothing);
    expect(monthlyEntry, findsNothing);

    // 月统计：内容与改动前一致（摘要面板 + 其余面板 + 管理入口）。
    // 列表是懒加载的，滚到底部后顶部 Tab 条会被回收，所以先切 Tab 再滚动。
    await tester.tap(tabLabel('月统计'));
    await tester.pumpAndSettle();
    expect(selectedTab('monthly'), findsOneWidget);
    expect(dailyEntry, findsNothing);
    await tester.scrollUntilVisible(
      monthlyEntry,
      200,
      scrollable: firstVerticalScrollable(),
    );
    expect(monthlyEntry, findsOneWidget);
    expect(find.text('5个月统计面板'), findsOneWidget);
  });

  testWidgets('日常面板：时间范围与收支口径可切换', (tester) async {
    await pumpApp(tester, LocalKeyValueStore());
    await tapBottomTab(tester, 2); // 看板
    await tester.pumpAndSettle();

    expect(find.text('近7日统计'), findsOneWidget);
    expect(
      find.byKey(const Key('recent_daily_range_last7Days')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('dimension_toggle_expense')), findsOneWidget);
    // 底部始终同时给出支出与收入的总计 / 日均。
    expect(find.textContaining('总支出：'), findsOneWidget);
    expect(find.textContaining('总收入：'), findsOneWidget);

    // Key 只挂选中项，所以用文字点未选中的那一项。
    await tester.tap(find.text('本周').first);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('recent_daily_range_thisWeek')),
      findsOneWidget,
    );

    await tester.tap(find.text('收入').first);
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('dimension_toggle_income')), findsOneWidget);
  });

  testWidgets('资产汇总面板：正/负资产可切换，中心可切换口径', (tester) async {
    await pumpApp(tester, LocalKeyValueStore());
    await tapBottomTab(tester, 2); // 看板 · 日常
    await tester.pumpAndSettle();

    expect(find.text('资产汇总'), findsOneWidget);
    expect(
      find.byKey(const Key('asset_summary_side_positive')),
      findsOneWidget,
    );
    // 新账本账户余额为 0：正资产侧没有可展示的账户，给出空态而不是空环。
    expect(find.textContaining('暂无'), findsWidgets);

    await tester.tap(find.text('负资产').first);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const Key('asset_summary_side_negative')),
      findsOneWidget,
    );
  });
}
