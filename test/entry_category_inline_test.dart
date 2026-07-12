import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/models.dart';
import 'package:verifin/app/veri_fin_controller.dart';
import 'package:verifin/app/veri_fin_scope.dart';
import 'package:verifin/pages/entry_detail_page.dart';

import 'support/test_harness.dart';

/// 覆盖记账页分类快捷区的「内联展开」交互（方案 A）：
/// 顶级分类点一下就地展开子分类、直接点选，全程不弹窗。
void main() {
  useTestDatabases();

  String idOfLabel(VeriFinController controller, String label) {
    return controller.categories.firstWhere((c) => c.label == label).id;
  }

  /// 造一个带「餐饮 → 早餐/午餐」层级的控制器。
  Future<VeriFinController> controllerWithSubcategories() async {
    final controller = await makeController();
    final diningId = idOfLabel(controller, '餐饮');
    controller
      ..addCategory(
        type: EntryType.expense,
        label: '早餐',
        iconCode: 'dining',
        parentId: diningId,
      )
      ..addCategory(
        type: EntryType.expense,
        label: '午餐',
        iconCode: 'dining',
        parentId: diningId,
      );
    return controller;
  }

  Future<void> pumpPage(
    WidgetTester tester,
    VeriFinController controller,
    Widget page,
  ) async {
    await tester.pumpWidget(
      VeriFinScope(
        controller: controller,
        child: zhMaterialApp(home: page),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('顶级分类默认折叠，点一下就地展开子分类', (tester) async {
    final controller = await controllerWithSubcategories();
    await pumpPage(
      tester,
      controller,
      const EntryDetailPage(initialAmount: 30),
    );

    // 默认选中顶级，子分类面板折叠：午餐、早餐都不可见。
    expect(find.text('午餐'), findsNothing);
    expect(find.text('早餐'), findsNothing);
    // 「餐饮」有子分类，chip 尾部是折叠箭头。
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);

    await tester.tap(find.text('餐饮'));
    await tester.pumpAndSettle();

    // 展开后子分类出现、箭头变为展开态。
    expect(find.text('午餐'), findsOneWidget);
    expect(find.text('早餐'), findsOneWidget);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
  });

  testWidgets('点子分类即选中它（无需进「全部」弹窗）', (tester) async {
    final controller = await controllerWithSubcategories();
    await pumpPage(
      tester,
      controller,
      const EntryDetailPage(initialAmount: 30),
    );

    await tester.tap(find.text('餐饮'));
    await tester.pumpAndSettle();
    final lunchFinder = find.widgetWithText(ChoiceChip, '午餐');
    await tester.ensureVisible(lunchFinder);
    await tester.pumpAndSettle();
    await tester.tap(lunchFinder);
    await tester.pumpAndSettle();

    expect(tester.widget<ChoiceChip>(lunchFinder).selected, isTrue);
  });

  testWidgets('编辑分类为子分类的交易时，面板自动展开并选中该子分类', (tester) async {
    final controller = await controllerWithSubcategories();
    final lunchId = idOfLabel(controller, '午餐');
    final entry = LedgerEntry(
      id: 'e1',
      bookId: controller.activeBook.id,
      type: EntryType.expense,
      amount: 30,
      categoryId: lunchId,
      accountId: '',
      note: '',
      occurredAt: DateTime(2026, 7, 12, 12, 0),
    );

    await pumpPage(tester, controller, EntryDetailPage.draft(entry: entry));

    // 打开即自动展开（选中的是子分类），午餐可见且选中。
    expect(find.text('午餐'), findsOneWidget);
    final lunchChip = tester.widget<ChoiceChip>(
      find.widgetWithText(ChoiceChip, '午餐'),
    );
    expect(lunchChip.selected, isTrue);
  });
}
