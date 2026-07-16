import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/chart_painters.dart';
import 'package:verifin/app/models.dart';
import 'package:verifin/app/veri_fin_scope.dart';
import 'package:verifin/local_storage/local_storage.dart';
import 'package:verifin/pages/budget_pages.dart';
import 'package:verifin/pages/home_page.dart';

import 'support/test_harness.dart';

void main() {
  useTestDatabases();

  testWidgets('home trend chart tap shows data instead of navigating', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    // 点击图表区域只选中数据点,不进入收支统计页。
    await tester.tap(find.byType(InteractiveTrendChart).first);
    await tester.pumpAndSettle();
    expect(find.text('收支统计'), findsNothing);
    // 默认标题为「概览」（可自定义，留空时回落此默认）。
    expect(find.text('概览'), findsOneWidget);

    // 点击卡片标题区域仍然进入收支统计页。
    await tester.tap(find.text('概览'));
    await tester.pumpAndSettle();
    expect(find.text('收支统计'), findsOneWidget);
  });

  testWidgets('edits monthly budget from the home budget card', (
    WidgetTester tester,
  ) async {
    await pumpApp(tester);

    await tester.scrollUntilVisible(
      find.byType(BudgetPanel),
      300,
      scrollable: firstVerticalScrollable(),
    );
    await tester.tap(find.byType(BudgetPanel));
    await tester.pumpAndSettle();

    expect(find.text('预算设置'), findsOneWidget);
    expect(find.text('本月支出'), findsAtLeastNWidgets(1));
    expect(find.text('剩余日均'), findsOneWidget);

    // 通过顶部“本月可用预算”旁的编辑图标设置本月预算（月度卡片在开屏即可见，
    // 每日预算卡片的编辑图标在其后，.first 命中的仍是月度卡片）
    await tester.tap(find.byIcon(Icons.edit_outlined).first);
    await tester.pumpAndSettle();
    expect(find.text('设置本月预算'), findsOneWidget);
    // 月度预算默认回退为 800，数字键盘会带入该值；先清空再输入 2400。
    await tester.tap(find.byKey(const Key('number_key_C')));
    for (final key in <String>['2', '4', '00']) {
      await tester.tap(find.byKey(Key('number_key_$key')));
    }
    await tester.tap(find.byKey(const Key('number_pad_ok')));
    await tester.pumpAndSettle();

    // 趋势卡片位于每日预算卡片之后，滚动到可见再断言
    await tester.scrollUntilVisible(
      find.text('近 6 月趋势'),
      200,
      scrollable: firstVerticalScrollable(),
    );
    expect(find.text('近 6 月趋势'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('餐饮'),
      200,
      scrollable: firstVerticalScrollable(),
    );
    expect(find.text('餐饮'), findsOneWidget);
    await tester.ensureVisible(find.text('餐饮'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('餐饮'));
    await tester.pumpAndSettle();
    expect(find.text('设置餐饮预算'), findsOneWidget);
    for (final key in <String>['6', '00']) {
      await tester.tap(find.byKey(Key('number_key_$key')));
    }
    await tester.tap(find.byKey(const Key('number_pad_ok')));
    await tester.pumpAndSettle();
    expect(find.text('600'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('预算设置'),
      -300,
      scrollable: firstVerticalScrollable(),
    );
    await tester.tap(find.byIcon(Icons.arrow_back).first);
    await tester.pumpAndSettle();

    expect(find.byType(BudgetPanel), findsOneWidget);
    expect(find.text('预算 2400'), findsOneWidget);
  });

  testWidgets('category budget list renders as a collapsible tree', (
    WidgetTester tester,
  ) async {
    final store = LocalKeyValueStore();
    final controller = await makeController(store);
    // 在种子分类「餐饮」下建一个子分类，形成父子层级。
    controller.addCategory(
      type: EntryType.expense,
      label: '午餐',
      iconCode: 'category',
      parentId: 'dining',
    );
    controller.dispose();

    await pumpApp(tester, store);
    await tester.scrollUntilVisible(
      find.byType(BudgetPanel),
      300,
      scrollable: firstVerticalScrollable(),
    );
    tester.widget<BudgetPanel>(find.byType(BudgetPanel)).onTap();
    await tester.pumpAndSettle();

    // 子分类默认展开可见。
    await tester.scrollUntilVisible(
      find.text('午餐'),
      200,
      scrollable: firstVerticalScrollable(),
    );
    expect(find.text('午餐'), findsOneWidget);

    // 收起父分类后子分类隐藏，父分类仍在。
    await tester.ensureVisible(find.byIcon(Icons.expand_more).first);
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.expand_more).first);
    await tester.pumpAndSettle();
    expect(find.text('午餐'), findsNothing);
    expect(find.text('餐饮'), findsOneWidget);
  });

  testWidgets('shows category budget risk on home and budget page', (
    WidgetTester tester,
  ) async {
    final store = LocalKeyValueStore();
    final controller = await makeController(store);
    final now = DateTime.now();
    final previousMonth = DateTime(now.year, now.month - 1, 12);
    controller
      ..addEntry(
        LedgerEntry(
          id: 'dining-risk',
          bookId: controller.activeBook.id,
          type: EntryType.expense,
          amount: 75,
          categoryId: 'dining',
          accountId: 'cash-test',
          note: '晚餐',
          occurredAt: now,
        ),
      )
      ..addEntry(
        LedgerEntry(
          id: 'dining-previous',
          bookId: controller.activeBook.id,
          type: EntryType.expense,
          amount: 40,
          categoryId: 'dining',
          accountId: 'cash-test',
          note: '上月晚餐',
          occurredAt: previousMonth,
        ),
      )
      ..setMonthlyBudget(now, 100)
      ..setCategoryBudget(now, 'dining', 50)
      ..dispose();

    await pumpApp(tester, store);
    await tester.scrollUntilVisible(
      find.byType(BudgetPanel),
      300,
      scrollable: firstVerticalScrollable(),
    );

    expect(find.text('餐饮超出 25'), findsOneWidget);
    tester.widget<BudgetPanel>(find.byType(BudgetPanel)).onTap();
    await tester.pumpAndSettle();

    expect(find.text('预算设置'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('近 6 月趋势'),
      200,
      scrollable: firstVerticalScrollable(),
    );
    expect(find.text('近 6 月趋势'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('历史对比'),
      200,
      scrollable: firstVerticalScrollable(),
    );
    expect(find.text('历史对比'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.history));
    await tester.pumpAndSettle();
    expect(find.text('预算历史'), findsOneWidget);
    expect(find.text('月份汇总'), findsOneWidget);
    Navigator.of(tester.element(find.text('预算历史'))).pop();
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('餐饮已超支'),
      200,
      scrollable: firstVerticalScrollable(),
    );
    expect(find.text('餐饮已超支'), findsOneWidget);
    expect(find.textContaining('已超出 25'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('上月 40'),
      200,
      scrollable: firstVerticalScrollable(),
    );
    expect(find.text('上月 40'), findsOneWidget);

    Navigator.of(tester.element(find.text('上月 40'))).pop();
    await tester.pumpAndSettle();
    await tapBottomTab(tester, 2);

    expect(find.text('预算执行'), findsOneWidget);
    expect(find.text('1 个超支'), findsOneWidget);
  });

  testWidgets('home budget card shows negative remaining when overspent', (
    WidgetTester tester,
  ) async {
    final store = LocalKeyValueStore();
    final controller = await makeController(store);
    final now = DateTime.now();
    controller
      ..addEntry(
        LedgerEntry(
          id: 'over-budget',
          bookId: controller.activeBook.id,
          type: EntryType.expense,
          amount: 150,
          categoryId: 'dining',
          accountId: 'cash-test',
          note: '大额支出',
          occurredAt: now,
        ),
      )
      ..setMonthlyBudget(now, 100)
      ..dispose();

    await pumpApp(tester, store);
    await tester.scrollUntilVisible(
      find.byType(BudgetPanel),
      300,
      scrollable: firstVerticalScrollable(),
    );

    // 支出 150、预算 100：剩余应显示 -50（负数），而不再夹到 0。
    expect(find.text('-50'), findsOneWidget);
  });

  test('category budget rolls up sub-category spending into parent', () async {
    final controller = await makeController();
    final month = DateTime(2026, 7);
    final diningId = controller.categories
        .firstWhere((c) => c.label == '餐饮')
        .id;
    controller.addCategory(
      type: EntryType.expense,
      label: '咖啡',
      iconCode: 'dining',
      parentId: diningId,
    );
    final coffeeId = controller.categories
        .firstWhere((c) => c.label == '咖啡')
        .id;

    final entries = <LedgerEntry>[
      LedgerEntry(
        id: 'e-dining',
        bookId: controller.activeBook.id,
        type: EntryType.expense,
        amount: 30,
        categoryId: diningId,
        accountId: 'cash',
        note: '',
        occurredAt: DateTime(2026, 7, 2),
      ),
      LedgerEntry(
        id: 'e-coffee',
        bookId: controller.activeBook.id,
        type: EntryType.expense,
        amount: 20,
        categoryId: coffeeId,
        accountId: 'cash',
        note: '',
        occurredAt: DateTime(2026, 7, 3),
      ),
    ];

    final snapshots = computeCategoryBudgetSnapshots(
      controller: controller,
      month: month,
      monthEntries: entries,
    );
    final dining = snapshots.firstWhere((s) => s.category.id == diningId);
    final coffee = snapshots.firstWhere((s) => s.category.id == coffeeId);
    // 父分类「餐饮」应包含自身 30 + 子分类「咖啡」20 = 50。
    expect(dining.spent, 50);
    // 子分类只计自身。
    expect(coffee.spent, 20);
    controller.dispose();
  });

  test('isolates budgets between ledger books', () async {
    final controller = await makeController();
    final month = DateTime(2026, 7);
    controller.setMonthlyBudget(month, 5000);
    controller.setCategoryBudget(month, 'dining', 600);

    controller.addLedgerBook('旅行账本');

    expect(controller.monthlyBudget(month), 800);
    expect(controller.categoryBudget(month, 'dining'), 0);

    controller.setMonthlyBudget(month, 1200);
    controller.switchLedgerBook('default');

    expect(controller.monthlyBudget(month), 5000);
    expect(controller.categoryBudget(month, 'dining'), 600);
    controller.dispose();
  });

  test('daily budget: set, clear, and isolate between books', () async {
    final controller = await makeController();
    expect(controller.dailyBudget(), 0);

    controller.setDailyBudget(80);
    expect(controller.dailyBudget(), 80);

    controller.addLedgerBook('旅行账本');
    // 新账本没有独立的每日预算。
    expect(controller.dailyBudget(), 0);
    controller.setDailyBudget(200);

    controller.switchLedgerBook('default');
    expect(controller.dailyBudget(), 80);

    // 设为 0 视为清除。
    controller.setDailyBudget(0);
    expect(controller.dailyBudget(), 0);
    controller.dispose();
  });

  test('daily budget persists across restart', () async {
    final store = LocalKeyValueStore();
    final controller = await makeController(store);
    controller.setDailyBudget(66);
    controller.dispose();

    // 复用同一存储的仓储即模拟重启后重新载入。
    final restarted = await makeController(store);
    expect(restarted.dailyBudget(), 66);
    restarted.dispose();
  });

  test('daily budget survives backup export/import roundtrip', () async {
    final controller = await makeController();
    controller.setDailyBudget(123);
    final json = controller.exportDataJson();

    final target = await makeController();
    expect(target.dailyBudget(), 0);
    target.importDataJson(json);
    expect(target.dailyBudget(), 123);
    controller.dispose();
    target.dispose();
  });

  group('预算周期起始日（issue #19）', () {
    test('默认自然月；设置/清除/账本隔离/钳位', () async {
      final controller = await makeController();
      expect(controller.budgetCycleStartDay, 1);
      expect(controller.budgetCycleIsCustom, isFalse);

      controller.setBudgetCycleStartDay(22);
      expect(controller.budgetCycleStartDay, 22);
      expect(controller.budgetCycleIsCustom, isTrue);

      // 账本隔离：新账本回落默认，各账本独立。
      controller.addLedgerBook('旅行账本');
      expect(controller.budgetCycleStartDay, 1);
      controller.setBudgetCycleStartDay(10);
      controller.switchLedgerBook('default');
      expect(controller.budgetCycleStartDay, 22);

      // 越界钳到 1–28；设回 1 即清除自定义。
      controller.setBudgetCycleStartDay(31);
      expect(controller.budgetCycleStartDay, 28);
      controller.setBudgetCycleStartDay(1);
      expect(controller.budgetCycleIsCustom, isFalse);
      controller.dispose();
    });

    test('周期窗口与键月：起始日 22 时 21/22 日分属两期', () async {
      final controller = await makeController();
      controller.setBudgetCycleStartDay(22);
      final window = controller.budgetWindow(DateTime(2026, 7));
      expect(window.start, DateTime(2026, 7, 22));
      expect(window.end, DateTime(2026, 8, 21));
      expect(
        controller.budgetKeyMonthFor(DateTime(2026, 7, 21)),
        DateTime(2026, 6),
      );
      expect(
        controller.budgetKeyMonthFor(DateTime(2026, 7, 22)),
        DateTime(2026, 7),
      );
      controller.dispose();
    });

    test('重启持久化 + 备份导出/导入 roundtrip', () async {
      final store = LocalKeyValueStore();
      final controller = await makeController(store);
      controller.setBudgetCycleStartDay(22);
      final json = controller.exportDataJson();
      controller.dispose();

      // 复用同一存储即模拟重启。
      final restarted = await makeController(store);
      expect(restarted.budgetCycleStartDay, 22);
      restarted.dispose();

      final target = await makeController();
      expect(target.budgetCycleStartDay, 1);
      target.importDataJson(json);
      expect(target.budgetCycleStartDay, 22);
      target.dispose();
    });

    test('初始化数据后回到自然月', () async {
      final controller = await makeController();
      controller.setBudgetCycleStartDay(22);
      controller.resetAllData();
      expect(controller.budgetCycleStartDay, 1);
      controller.dispose();
    });

    testWidgets('预算页按周期取数并用「本期」文案', (WidgetTester tester) async {
      final controller = await makeController();
      controller.setBudgetCycleStartDay(22);
      final bookId = controller.activeBook.id;
      controller
        ..addEntry(
          LedgerEntry(
            id: 'in-cycle',
            bookId: bookId,
            type: EntryType.expense,
            amount: 100,
            categoryId: 'dining',
            accountId: '',
            note: '周期内',
            occurredAt: DateTime(2026, 7, 23),
          ),
        )
        ..addEntry(
          LedgerEntry(
            id: 'prev-cycle',
            bookId: bookId,
            type: EntryType.expense,
            amount: 40,
            categoryId: 'dining',
            accountId: '',
            note: '上一期',
            occurredAt: DateTime(2026, 7, 21),
          ),
        );

      await tester.pumpWidget(
        VeriFinScope(
          controller: controller,
          child: zhMaterialApp(
            home: BudgetSettingsPage(initialMonth: DateTime(2026, 7)),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 周期标签展示日期范围而非「2026年7月」，文案用「本期」。
      expect(find.textContaining('7月22日'), findsWidgets);
      expect(find.text('本期支出'), findsAtLeastNWidgets(1));
      expect(find.text('本月支出'), findsNothing);
      // 键月 2026-07 的周期是 7/22~8/21：只计入 23 日那笔（默认预算 800，
      // 剩余 700，大字与「剩余额度」瓦片各一处）；若误按自然月聚合会把 21 日
      // 的 40 也算进来（剩余 660）。
      expect(find.text('700'), findsWidgets);
      expect(find.text('660'), findsNothing);
      controller.dispose();
    });
  });
}
