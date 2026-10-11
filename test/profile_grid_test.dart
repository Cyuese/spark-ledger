import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_harness.dart';

void main() {
  useTestDatabases();

  testWidgets('我的页宫格展示功能入口', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(393, 852);
    addTearDown(tester.view.reset);
    await pumpApp(tester);
    await tapBottomTab(tester, 3);

    // 宫格分组标题与主要入口。
    expect(find.text('记账管理'), findsOneWidget);
    expect(find.text('数据与工具'), findsOneWidget);
    expect(find.text('分类管理'), findsOneWidget);
    expect(find.text('周期记账'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('profile_feature_grid_bookkeeping')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('profile_feature_grid_tools')),
      findsOneWidget,
    );
    expect(find.textContaining('Web 开发预览'), findsNothing);

    // 「统计分析」已并入看板，入口不再出现在宫格里。
    final scrollable = firstVerticalScrollable();
    await tester.scrollUntilVisible(
      find.text('记账提醒'),
      200,
      scrollable: scrollable,
    );
    expect(find.text('统计分析'), findsNothing);
    expect(find.text('记账提醒'), findsOneWidget);
  });
}
