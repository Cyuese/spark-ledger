import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_harness.dart';

void main() {
  useTestDatabases();

  testWidgets('widget gallery lists all widgets and reaches add-to-home', (
    tester,
  ) async {
    await pumpApp(tester);
    // 入口在「我的 → 数据与工具」宫格里。
    await tapBottomTab(tester, 3);
    await tester.scrollUntilVisible(
      find.text('桌面小组件'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('桌面小组件'));
    await tester.pumpAndSettle();

    // 三个小组件都列出（卡片标题）+ 各自「添加到桌面」按钮（镂空样式）。
    expect(find.text('今日支出 + 记一笔'), findsOneWidget);
    expect(find.text('本月可用预算'), findsWidgets);
    expect(find.text('资产总额'), findsWidgets);
    expect(find.widgetWithText(OutlinedButton, '添加到桌面'), findsNWidgets(3));

    // 底部「如何手动添加」引导（懒加载列表，需滚动到位）。
    await tester.scrollUntilVisible(find.text('如何手动添加'), 200);
    expect(find.text('如何手动添加'), findsOneWidget);
  });
}
