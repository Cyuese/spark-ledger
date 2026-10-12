import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/models.dart';
import 'package:verifin/app/veri_fin_controller.dart';

import 'support/test_harness.dart';

/// 桌面投影的失效信号护栏。
///
/// 投影读取的是交易、账户、账本、汇率与预算（以及语言）。这些数据**不只有
/// `_persistX` 一条写入路径**：显式命令（保存汇率草稿、账户草稿、删除账本…）会自己
/// 调仓储。这个用例逐条走过这些入口，避免以后新增写入点漏通知——那种漏法表现为
/// 「桌面组件一直显示旧数字」，线上很难定位。
void main() {
  useTestDatabases();

  LedgerEntry expense(VeriFinController controller) => LedgerEntry(
    id: 'entry-signal',
    bookId: controller.activeBook.id,
    type: EntryType.expense,
    amount: 12,
    categoryId: 'dining',
    accountId: 'cash',
    note: '',
    occurredAt: DateTime(2026, 9, 12),
  );

  Account cash(VeriFinController controller, {String id = 'cash'}) => Account(
    id: id,
    bookId: controller.activeBook.id,
    name: '现金',
    type: AccountType.cash,
    groupId: null,
    initialBalance: 100,
    iconCode: 'wallet',
    note: '',
    includeInAssets: true,
    hidden: false,
  );

  test('影响投影的每个写入入口都会通知一次', () async {
    final controller = await makeController();
    addTearDown(controller.dispose);
    var changes = 0;
    controller.onWidgetDataChanged = () => changes++;

    Future<void> signals(String label, Future<void> Function() run) async {
      final before = changes;
      await run();
      expect(changes, greaterThan(before), reason: '$label 没有让投影失效');
    }

    await signals('记一笔', () async => controller.addEntry(expense(controller)));
    await signals('删除交易', () async => controller.deleteEntry('entry-signal'));
    await signals('新增账户', () async => controller.addAccount(cash(controller)));
    await signals(
      '账户草稿',
      () => controller.addAccountDraft(cash(controller, id: 'cash-draft')),
    );
    await signals(
      '编辑账户草稿',
      () => controller.saveAccountDraft(
        cash(controller, id: 'cash-draft').copyWith(name: '现金 2'),
      ),
    );
    await signals('删除账户', () async => controller.deleteAccount('cash-draft'));
    await signals('新增账本', () async => controller.addLedgerBook('旅行'));
    final travelBookId = controller.ledgerBooks.last.id;
    await signals(
      '删除账本',
      () async => controller.deleteLedgerBook(travelBookId),
    );
    await signals('默认月预算', () async => controller.setDefaultMonthlyBudget(500));
    await signals('预算周期', () async => controller.setBudgetCycleStartDay(5));
    await signals(
      '新增汇率',
      () => controller.saveExchangeRateDraft(
        currencyCode: 'USD',
        effectiveDate: DateTime(2026, 9, 1),
        rateToBase: 7.1,
      ),
    );
    final rateId = controller.exchangeRates.first.id;
    await signals('删除汇率', () => controller.deleteExchangeRate(rateId));
  });

  test('不参与投影的变化不通知', () async {
    final controller = await makeController();
    addTearDown(controller.dispose);
    var changes = 0;
    controller.onWidgetDataChanged = () => changes++;

    // 外观/界面偏好：组件外观是实例级设置，与账本数据无关。
    controller.setThemePreference(ThemePreference.dark);
    controller.setDefaultMonthlyBudget(300);
    final baseline = changes;

    controller.setThemePreference(ThemePreference.light);
    controller.toggleAssetSectionCollapsed(
      mode: AssetAccountViewMode.type,
      sectionId: 'cash',
    );
    controller.addCategory(
      label: '新分类',
      type: EntryType.expense,
      iconCode: 'dining',
    );
    controller.addTag('新标签');
    expect(changes, baseline);
  });
}
