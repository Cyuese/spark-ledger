import 'l10n_outside_context.dart';
import 'ledger_math.dart';
import 'models.dart';
import 'platform_bridge.dart';
import 'series_math.dart';
import 'veri_fin_controller.dart';

/// 把当前账本的桌面小组件数据（今日支出 / 本月可用预算 / 资产总额）推送到 Android。
/// 非 Android 平台由 [AppPlatformBridge] 静默忽略；在打开应用、回前台、记账后调用。
Future<void> pushWidgetData(VeriFinController controller) async {
  final l10n = l10nForPreference(controller.localePreference);
  final now = DateTime.now();
  final entries = controller.entries;

  final todayTotal = dayExpenseTotal(entries, dateOnly(now));

  final monthExpense = sumByType(
    entries.where((entry) => isInMonth(entry, now)),
    EntryType.expense,
  );
  final remaining = controller.monthlyBudget(now) - monthExpense;

  final netWorth = controller.accounts
      .where((account) => !account.hidden)
      .fold<double>(
        0,
        (sum, account) => sum + controller.accountBalance(account),
      );

  await AppPlatformBridge.updateWidgetData(
    todayAmount: formatAmount(todayTotal),
    todayLabel: l10n.widgetTodayExpense,
    budgetAmount: formatAmount(remaining.abs()),
    budgetLabel: remaining < 0
        ? l10n.widgetBudgetOverspent
        : l10n.widgetBudgetAvailable,
    netWorthAmount: formatAmount(netWorth),
    netWorthLabel: l10n.widgetNetWorth,
  );
}
