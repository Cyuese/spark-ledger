import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/models.dart';
import 'package:verifin/local_storage/local_storage.dart';

import 'support/test_harness.dart';

void main() {
  useTestDatabases();

  testWidgets('看板可进入统计分析页并切换维度与范围', (WidgetTester tester) async {
    final store = LocalKeyValueStore();
    final controller = await makeController(store);
    final now = DateTime.now();
    controller
      ..addEntry(
        LedgerEntry(
          id: 'exp-1',
          bookId: controller.activeBook.id,
          type: EntryType.expense,
          amount: 120,
          categoryId: 'dining',
          accountId: 'cash-report',
          note: '',
          occurredAt: now,
        ),
      )
      ..addEntry(
        LedgerEntry(
          id: 'inc-1',
          bookId: controller.activeBook.id,
          type: EntryType.income,
          amount: 5000,
          categoryId: 'salary',
          accountId: 'cash-report',
          note: '',
          occurredAt: now,
        ),
      )
      ..dispose();

    await pumpApp(tester, store);
    await tapBottomTab(tester, 2);
    await tester.pumpAndSettle();

    // 打开统计分析页。
    await tester.tap(find.byTooltip('统计分析'));
    await tester.pumpAndSettle();

    expect(find.text('统计分析'), findsOneWidget);
    expect(find.text('收支概览'), findsOneWidget);
    // 本月范围显示同比/环比对比卡。
    expect(find.text('同比 · 环比'), findsOneWidget);

    final scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('分类排行'),
      250,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    // 默认支出维度显示餐饮分类。
    expect(find.text('餐饮'), findsWidgets);

    // 切换到收入维度，分类排行显示工资。（「收入」同时出现在概览标签与维度切换，取切换段）
    await tester.tap(find.text('收入').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('工资'),
      250,
      scrollable: scrollable,
    );
    expect(find.text('工资'), findsWidgets);

    // 切换到本年范围（不显示同比/环比卡）。
    await tester.scrollUntilVisible(
      find.text('本年'),
      -250,
      scrollable: scrollable,
    );
    await tester.tap(find.text('本年'));
    await tester.pumpAndSettle();
    // 回到顶部（头部标题带出副标题）确认范围标签更新为年份，且同比/环比卡消失。
    await tester.scrollUntilVisible(
      find.text('统计分析'),
      -250,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('${now.year}年'), findsWidgets);
    expect(find.text('同比 · 环比'), findsNothing);
  });
}
