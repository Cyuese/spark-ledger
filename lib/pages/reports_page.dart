import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../app/category_tree.dart';
import '../app/chart_painters.dart';
import '../app/common_widgets.dart';
import '../app/currency_math.dart';
import '../app/model_lookup.dart';
import '../app/ledger_math.dart';
import '../app/models.dart';
import '../app/root_navigation.dart';
import '../app/series_math.dart';
import '../app/veri_fin_scope.dart';
import 'ai_chat_page.dart';
import 'budget_pages.dart';
import 'currency_rates_page.dart';
import 'panel_settings_page.dart';
import 'report_analysis_page.dart';
import '../l10n/app_localizations.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  /// 看板顶部统计口径 Tab。默认落在「日常」；不做持久化，每次进入都回到它。
  ReportPeriodTab _tab = ReportPeriodTab.daily;

  @override
  Widget build(BuildContext context) {
    final controller = VeriFinScope.of(context);
    final l10n = AppLocalizations.of(context);
    final entries = controller.entries;
    final now = DateTime.now();
    final monthEntries = entries
        .where((entry) => isInMonth(entry, now))
        .toList(growable: false);
    final monthExpense = sumByType(monthEntries, EntryType.expense);
    final monthIncome = sumByType(monthEntries, EntryType.income);
    final monthNet = monthIncome - monthExpense;
    final monthIncomeCount = monthEntries
        .where((entry) => entry.type == EntryType.income)
        .length;
    final monthExpenseCount = monthEntries
        .where((entry) => entry.type == EntryType.expense)
        .length;
    // 预算执行卡按预算周期取数（键月 + 周期窗口）；看板其余统计仍按自然月。
    final budgetKeyMonth = controller.budgetKeyMonthFor(now);
    final budgetEntries = entriesInWindow(
      entries,
      controller.budgetWindow(budgetKeyMonth),
    );
    // 预算执行卡按预算口径取数：排除标记「不计入预算」的交易，看板其余统计
    // 仍按自然月、按实际发生（标记不影响收支统计）。
    final budgetExpense = budgetExpenseTotal(budgetEntries);
    final monthlyBudget = controller.monthlyBudget(budgetKeyMonth);
    final categoryBudgetSnapshots = computeCategoryBudgetSnapshots(
      controller: controller,
      month: budgetKeyMonth,
      monthEntries: budgetEntries,
    );
    final expenseEntries = monthEntries
        .where((entry) => entry.type == EntryType.expense)
        .toList(growable: false);
    final categoryStats = _categoryStats(expenseEntries, controller.categories);
    final tagStats = _tagStats(expenseEntries, controller.tags, monthExpense);
    final trendWindow = cumulativeWeekWindowFor(DateTime.now());
    final trendValues = valuesForTypeInWindow(
      entries,
      trendWindow,
      EntryType.expense,
    );
    final trendExpense = trendValues.fold<double>(
      0,
      (sum, value) => sum + value,
    );
    final trendMax = trendValues.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    final monthlyValues = monthlyExpenseValues(entries);
    final monthlyMax = monthlyValues.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    final panelIds = controller.enabledPanelIds(_tab.panelPageKind);

    // 面板 id 对应的卡片,渲染顺序与开关由面板管理页配置。
    Widget panelFor(String id) {
      switch (id) {
        case 'recent_daily':
          return const _RecentDailyStatsPanel();
        case 'asset_summary':
          return const _AssetSummaryPanel();
        case 'summary':
          return _MonthSummaryPanel(
            income: monthIncome,
            expense: monthExpense,
            net: monthNet,
            incomeCount: monthIncomeCount,
            expenseCount: monthExpenseCount,
          );
        case 'budget_execution':
          return _BudgetExecutionCard(
            budget: monthlyBudget,
            expense: budgetExpense,
            keyMonth: budgetKeyMonth,
            snapshots: categoryBudgetSnapshots,
          );
        case 'category_ring':
          return VeriCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SectionTitle(
                  title: AppLocalizations.of(context).panelCategoryRingLabel,
                  trailing:
                      '${formatExpenseAmount(monthExpense)} · ${AppLocalizations.of(context).monthNumber(DateTime.now().month)} · ${AppLocalizations.of(context).entryTypeExpense}',
                ),
                const SizedBox(height: 12),
                // 与同页其它面板同口径：净额为 0（如支出被全额退款）也视为无数据，
                // 否则只剩一个空轨道和「0」。
                if (categoryStats.isEmpty || isZeroAmount(monthExpense))
                  EmptyState(
                    icon: Icons.donut_small_outlined,
                    title: AppLocalizations.of(context).noCategoryData,
                    description: AppLocalizations.of(context).noCategoryDesc,
                  )
                else
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 360;
                      return _CategoryRingChart(
                        stats: categoryStats,
                        total: monthExpense,
                        ringSize: compact ? 126 : 156,
                      );
                    },
                  ),
              ],
            ),
          );
        case 'category_rank':
          return VeriCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SectionTitle(
                  title: AppLocalizations.of(context).panelCategoryRankLabel,
                  trailing: AppLocalizations.of(context).entryTypeExpense,
                ),
                const SizedBox(height: 8),
                if (categoryStats.isEmpty)
                  EmptyState(
                    icon: Icons.donut_small_outlined,
                    title: AppLocalizations.of(context).noCategoryData,
                    description: AppLocalizations.of(context).noCategoryDesc,
                  )
                else
                  ...categoryStats
                      .take(6)
                      .map((stat) => _CategoryStatTile(stat: stat)),
              ],
            ),
          );
        case 'daily_trend':
          return VeriCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SectionTitle(
                  title: AppLocalizations.of(context).panelDailyTrendLabel,
                  trailing: formatExpenseAmount(trendExpense),
                ),
                const SizedBox(height: 16),
                if (isZeroAmount(trendExpense))
                  EmptyState(
                    icon: Icons.show_chart,
                    title: l10n.noDimData(l10n.entryTypeExpense),
                    description: l10n.noDimDesc(l10n.entryTypeExpense),
                  )
                else
                  SizedBox(
                    height: 138,
                    child: InteractiveTrendChart(
                      color: veriSemantic(context, veriExpense),
                      values: trendValues,
                      xLabels: sparseLabelsForWindow(trendWindow),
                      yLabels: reportAxisLabels(trendMax),
                      labelColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.50),
                      tooltipOf: (index) {
                        final day = trendWindow.days[index];
                        return ChartTooltip(
                          title: AppLocalizations.of(context).dateMonthDay(day),
                          lines: <ChartTooltipLine>[
                            ChartTooltipLine(
                              text: AppLocalizations.of(context)
                                  .expenseAmountLabel(
                                    formatExpenseAmount(trendValues[index]),
                                  ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
              ],
            ),
          );
        case 'monthly_structure':
          return VeriCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SectionTitle(
                  // 面板只有支出序列（monthlyExpenseValues），不能沿用面板管理页
                  // 里的「月度收支」名称；标题口径与描述「今年每月支出结构柱状图」一致。
                  title: AppLocalizations.of(context).monthlyTrendTitle,
                  trailing: AppLocalizations.of(context).thisYearLabel,
                ),
                const SizedBox(height: 16),
                if (monthlyMax <= 0)
                  EmptyState(
                    icon: Icons.bar_chart_outlined,
                    title: l10n.noDimData(l10n.entryTypeExpense),
                    description: l10n.noDimDesc(l10n.entryTypeExpense),
                  )
                else
                  SizedBox(
                    height: 146,
                    child: InteractiveBarChart(
                      values: monthlyValues,
                      xLabels: const <String>[
                        '1',
                        '2',
                        '3',
                        '4',
                        '5',
                        '6',
                        '7',
                        '8',
                        '9',
                        '10',
                        '11',
                        '12',
                      ],
                      yLabels: reportAxisLabels(monthlyMax),
                      labelColor: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.50),
                      tooltipOf: (index) => ChartTooltip(
                        title: AppLocalizations.of(
                          context,
                        ).monthNumber(index + 1),
                        lines: <ChartTooltipLine>[
                          ChartTooltipLine(
                            text: AppLocalizations.of(context)
                                .expenseAmountLabel(
                                  formatExpenseAmount(monthlyValues[index]),
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        case 'tag_stats':
          return VeriCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SectionTitle(
                  title: AppLocalizations.of(context).panelTagStatsLabel,
                  trailing: AppLocalizations.of(context).budgetMonthExpense,
                ),
                const SizedBox(height: 8),
                if (tagStats.isEmpty)
                  EmptyState(
                    icon: Icons.label_outline,
                    title: AppLocalizations.of(context).noTagData,
                    description: AppLocalizations.of(context).noTagDesc,
                  )
                else
                  ...tagStats.take(8).map((stat) => _TagStatTile(stat: stat)),
              ],
            ),
          );
        default:
          return const SizedBox.shrink();
      }
    }

    return VeriPage(
      child: ListView(
        padding: veriRootPageListPadding(context),
        children: <Widget>[
          PageHeader(
            title: AppLocalizations.of(context).tabReports,
            subtitle: currencyUnitSubtitle(
              AppLocalizations.of(context),
              AppLocalizations.of(context).reportsSubtitle,
              controller.activeBook.baseCurrencyCode,
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                HeaderAction(
                  icon: Icons.smart_toy_outlined,
                  tooltip: AppLocalizations.of(context).aiChatTitle,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => const AiChatPage()),
                  ),
                ),
                HeaderAction(
                  icon: Icons.insights_outlined,
                  tooltip: AppLocalizations.of(context).statAnalysisTitle,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ReportAnalysisPage(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          VeriSegmentedControl<ReportPeriodTab>(
            values: ReportPeriodTab.values,
            selected: _tab,
            semanticLabel: l10n.statRangeLabel,
            labelOf: (tab) => tab.label(l10n),
            // 与记账页 `entry_type_selected_*` 同一契约：Key 只挂在选中项上
            // （分段控件会把选中项多渲染一份用于滑动动画）。
            keyOf: (tab) =>
                tab == _tab ? Key('reports_tab_selected_${tab.name}') : null,
            onChanged: (tab) => setState(() => _tab = tab),
          ),
          // 各 Tab 的面板清单互相独立。「日常 / 年统计 / 自定义」的内容尚未
          // 全部实现前，没有面板的 Tab 只画 Tab 本体，不渲染占位文案。
          for (final id in panelIds) ...<Widget>[
            const SizedBox(height: 10),
            panelFor(id),
          ],
          if (panelIds.isNotEmpty) ...<Widget>[
            const SizedBox(height: 8),
            PanelSettingsEntry(kind: _tab.panelPageKind),
          ],
        ],
      ),
    );
  }
}

/// 资产汇总的口径：只统计余额为正的账户，或只统计余额为负的账户。
enum _AssetSide { positive, negative }

/// 日常 Tab 的资产汇总面板：环形图 + 图例，点中心在金额 / 占比之间切换。
///
/// 只统计**计入资产**且**未隐藏**的账户（与资产页净资产口径一致），否则环里
/// 各段加不出中心数字。任一账户缺汇率时整卡退化为缺率空态，不展示部分和。
class _AssetSummaryPanel extends StatefulWidget {
  const _AssetSummaryPanel();

  @override
  State<_AssetSummaryPanel> createState() => _AssetSummaryPanelState();
}

class _AssetSummaryPanelState extends State<_AssetSummaryPanel> {
  _AssetSide _side = _AssetSide.positive;
  bool _showShare = false;

  @override
  Widget build(BuildContext context) {
    final controller = VeriFinScope.of(context);
    final l10n = AppLocalizations.of(context);
    final baseCurrency = controller.activeBook.baseCurrencyCode;
    final accounts = controller.accounts
        .where((account) => account.includeInAssets && !account.hidden)
        .toList(growable: false);
    final valuation = controller.accountBalancesInBase(accounts: accounts);
    final sign = _side == _AssetSide.positive ? 1.0 : -1.0;
    final holdings = <({Account account, double amount})>[
      for (final account in accounts)
        if ((valuation.amountsByAccountId[account.id] ?? 0) * sign > 0)
          (
            account: account,
            amount: (valuation.amountsByAccountId[account.id] ?? 0).abs(),
          ),
    ]..sort((a, b) => b.amount.compareTo(a.amount));
    final total = normalizeAmount(
      holdings.fold<double>(0, (sum, holding) => sum + holding.amount),
    );

    return VeriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionTitle(
            title: l10n.panelAssetSummaryLabel,
            trailingWidget: VeriSegmentedControl<_AssetSide>(
              compact: true,
              values: const <_AssetSide>[
                _AssetSide.positive,
                _AssetSide.negative,
              ],
              selected: _side,
              semanticLabel: l10n.panelAssetSummaryLabel,
              labelOf: (side) => side == _AssetSide.positive
                  ? l10n.assetPositive
                  : l10n.assetNegative,
              keyOf: (side) =>
                  side == _side ? Key('asset_summary_side_${side.name}') : null,
              onChanged: (side) => setState(() {
                _side = side;
              }),
            ),
          ),
          const SizedBox(height: 12),
          if (!valuation.isComplete)
            _AssetMissingRateState(
              affectedCount: valuation.affectedAccountIds.length,
              currencyCodes: valuation.missingCurrencyCodes,
            )
          else if (holdings.isEmpty)
            EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: l10n.noDimData(
                _side == _AssetSide.positive
                    ? l10n.assetPositive
                    : l10n.assetNegative,
              ),
              description: l10n.panelAssetSummaryDesc,
            )
          else
            _AssetSummaryChart(
              holdings: holdings,
              total: total,
              baseCurrency: baseCurrency,
              showShare: _showShare,
              onToggleMode: () => setState(() => _showShare = !_showShare),
            ),
        ],
      ),
    );
  }
}

/// 缺汇率：不给部分和，只说明缺哪些币种并给一个去维护汇率的入口。
class _AssetMissingRateState extends StatelessWidget {
  const _AssetMissingRateState({
    required this.affectedCount,
    required this.currencyCodes,
  });

  final int affectedCount;
  final Set<String> currencyCodes;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final codes = (currencyCodes.toList()..sort()).join(', ');
    return InkWell(
      borderRadius: BorderRadius.circular(veriRadiusMd),
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const CurrencyRatesPage()),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Icon(
              Icons.currency_exchange,
              color: veriSemantic(context, veriWarning),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    l10n.assetValuationMissing(affectedCount),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l10n.assetValuationMissingDesc(codes),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.62),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 环形图 + 图例；中心可点，用于在金额 / 占比之间切换。
class _AssetSummaryChart extends StatefulWidget {
  const _AssetSummaryChart({
    required this.holdings,
    required this.total,
    required this.baseCurrency,
    required this.showShare,
    required this.onToggleMode,
  });

  final List<({Account account, double amount})> holdings;
  final double total;
  final String baseCurrency;
  final bool showShare;
  final VoidCallback onToggleMode;

  @override
  State<_AssetSummaryChart> createState() => _AssetSummaryChartState();
}

class _AssetSummaryChartState extends State<_AssetSummaryChart> {
  int? _selectedIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brightness = Theme.of(context).brightness;
    final neutral = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.45);
    final colors = <Color>[
      Theme.of(context).colorScheme.primary,
      veriSemanticFor(brightness, veriBlue),
      veriCyan,
      veriMint,
      veriSemanticFor(brightness, veriWarning),
      neutral,
    ];
    final visible = widget.holdings.take(5).toList();
    final hidden = widget.holdings.skip(5).toList();
    final otherAmount = hidden.fold<double>(
      0,
      (sum, holding) => sum + holding.amount,
    );
    final legend = <({String label, double amount, Color color})>[
      for (final item in visible.indexed)
        (
          label: item.$2.account.name,
          amount: item.$2.amount,
          color: colors[item.$1 % colors.length],
        ),
      if (otherAmount > 0)
        (label: l10n.othersLabel, amount: otherAmount, color: neutral),
    ];
    final segments = <VeriDonutSegment>[
      for (final item in legend)
        VeriDonutSegment(
          label: item.label,
          value: item.amount,
          color: item.color,
        ),
    ];
    final selected = _selectedIndex != null && _selectedIndex! < legend.length
        ? _selectedIndex
        : null;
    final total = widget.total;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Center(
          child: SizedBox(
            width: 156,
            height: 156,
            child: VeriDonutChart(
              segments: segments,
              selectedIndex: selected,
              onSelected: (index) => setState(() => _selectedIndex = index),
              ringWidth: 30,
              showPercentTitles: true,
              onCenterTap: widget.onToggleMode,
              semanticsLabel: l10n.panelAssetSummaryLabel,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        widget.showShare
                            ? l10n.assetSummaryShare
                            : l10n.assetSummaryAmount,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.56),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Icon(
                        Icons.swap_horiz,
                        size: 13,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.56),
                      ),
                    ],
                  ),
                  Text(
                    formatUserMoney(total, widget.baseCurrency),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        for (final item in legend)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: <Widget>[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.showShare || total <= 0
                      ? '${(item.amount / (total <= 0 ? 1 : total) * 100).toStringAsFixed(1)}%'
                      : formatUserMoney(item.amount, widget.baseCurrency),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// 近 7 日统计的时间范围：滚动 7 天，或自然周（周一至周日，含今天）。
enum _RecentDailyRange { last7Days, thisWeek }

/// 日常 Tab 的收支统计面板：柱状图 + 总额 / 日均（支出与收入同时给出）。
class _RecentDailyStatsPanel extends StatefulWidget {
  const _RecentDailyStatsPanel();

  @override
  State<_RecentDailyStatsPanel> createState() => _RecentDailyStatsPanelState();
}

class _RecentDailyStatsPanelState extends State<_RecentDailyStatsPanel> {
  _RecentDailyRange _range = _RecentDailyRange.last7Days;
  EntryType _type = EntryType.expense;

  @override
  Widget build(BuildContext context) {
    final controller = VeriFinScope.of(context);
    final l10n = AppLocalizations.of(context);
    final today = dateOnly(DateTime.now());
    final window = _range == _RecentDailyRange.thisWeek
        ? weekWindowFor(today)
        : DateWindow(start: addCalendarDays(today, -6), end: today);
    final expenseValues = valuesForTypeInWindow(
      controller.entries,
      window,
      EntryType.expense,
    );
    final incomeValues = valuesForTypeInWindow(
      controller.entries,
      window,
      EntryType.income,
    );
    final expenseTotal = _sumValues(expenseValues);
    final incomeTotal = _sumValues(incomeValues);
    final expense = _type == EntryType.expense;
    final chartValues = expense ? expenseValues : incomeValues;
    final chartTotal = expense ? expenseTotal : incomeTotal;
    final maxValue = chartValues.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    final dimLabel = _type.label(l10n);

    return VeriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionTitle(
            title: l10n.panelRecentDailyLabel,
            trailingWidget: VeriSegmentedControl<_RecentDailyRange>(
              compact: true,
              values: const <_RecentDailyRange>[
                _RecentDailyRange.last7Days,
                _RecentDailyRange.thisWeek,
              ],
              selected: _range,
              semanticLabel: l10n.statRangeLabel,
              labelOf: (range) => range == _RecentDailyRange.last7Days
                  ? l10n.recent7Days
                  : l10n.timeWeek,
              // Key 只挂选中项：分段控件会把选中项多渲染一份用于滑动动画。
              keyOf: (range) => range == _range
                  ? Key('recent_daily_range_${range.name}')
                  : null,
              onChanged: (range) => setState(() => _range = range),
            ),
          ),
          const SizedBox(height: 10),
          VeriEntryTypeToggle(
            dimension: _type,
            onChanged: (type) => setState(() => _type = type),
          ),
          const SizedBox(height: 16),
          if (isZeroAmount(chartTotal))
            EmptyState(
              icon: Icons.bar_chart_outlined,
              title: l10n.noDimData(dimLabel),
              description: l10n.noDimDesc(dimLabel),
            )
          else
            SizedBox(
              height: 138,
              child: InteractiveBarChart(
                values: chartValues,
                xLabels: _range == _RecentDailyRange.thisWeek
                    ? window.days
                          .map((day) => _weekdayLabel(l10n, day))
                          .toList(growable: false)
                    : labelsForWindow(window),
                yLabels: reportAxisLabels(maxValue),
                labelColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.50),
                tooltipOf: (index) => ChartTooltip(
                  title: l10n.dateMonthDay(window.days[index]),
                  lines: <ChartTooltipLine>[
                    ChartTooltipLine(
                      text: expense
                          ? l10n.expenseAmountLabel(
                              formatExpenseAmount(chartValues[index]),
                            )
                          : l10n.incomeAmountLabel(
                              formatIncomeAmount(chartValues[index]),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 14),
          Row(
            children: <Widget>[
              Expanded(
                child: _RecentStatLine(
                  label: l10n.recentTotalExpense,
                  value: formatExpenseAmount(expenseTotal),
                ),
              ),
              Expanded(
                child: _RecentStatLine(
                  label: l10n.recentDailyAvgExpense,
                  value: formatExpenseAmount(_dailyAverage(expenseTotal)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: <Widget>[
              Expanded(
                child: _RecentStatLine(
                  label: l10n.recentTotalIncome,
                  value: formatAmount(incomeTotal),
                ),
              ),
              Expanded(
                child: _RecentStatLine(
                  label: l10n.recentDailyAvgIncome,
                  value: formatAmount(_dailyAverage(incomeTotal)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 面板内的合计：规整到最小货币单位，避免浮点残差。
double _sumValues(List<double> values) =>
    normalizeAmount(values.fold<double>(0, (sum, value) => sum + value));

/// 日均固定按 7 天折算（滚动 7 日与自然周两种窗口都对齐）。
double _dailyAverage(double total) => normalizeAmount(total / 7);

String _weekdayLabel(AppLocalizations l10n, DateTime day) {
  switch (day.weekday) {
    case DateTime.monday:
      return l10n.weekdayMon;
    case DateTime.tuesday:
      return l10n.weekdayTue;
    case DateTime.wednesday:
      return l10n.weekdayWed;
    case DateTime.thursday:
      return l10n.weekdayThu;
    case DateTime.friday:
      return l10n.weekdayFri;
    case DateTime.saturday:
      return l10n.weekdaySat;
    default:
      return l10n.weekdaySun;
  }
}

/// 「标签：金额」一行的紧凑排布（近 7 日面板底部两列两行）。
class _RecentStatLine extends StatelessWidget {
  const _RecentStatLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      AppLocalizations.of(context).recentStatLine(label, value),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurface,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

/// 月统计的本月收支摘要面板：本月收入 / 支出 / 结余（各带笔数）。
/// 原先是页面顶部无法关闭的固定条，现在与其它面板一样可开关、可排序。
class _MonthSummaryPanel extends StatelessWidget {
  const _MonthSummaryPanel({
    required this.income,
    required this.expense,
    required this.net,
    required this.incomeCount,
    required this.expenseCount,
  });

  final double income;
  final double expense;
  final double net;
  final int incomeCount;
  final int expenseCount;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final zeroColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.48);
    return VeriCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SectionTitle(
            title: l10n.panelSummaryLabel,
            trailing: l10n.monthNumber(DateTime.now().month),
          ),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              SummaryMetric(
                label: l10n.metricMonthIncome,
                value: formatAmount(income),
                color: isZeroAmount(income)
                    ? zeroColor
                    : veriSemantic(context, veriIncome),
                detail: l10n.entriesCount(incomeCount),
              ),
              SummaryMetric(
                label: l10n.metricMonthExpense,
                value: formatExpenseAmount(expense),
                color: isZeroAmount(expense)
                    ? zeroColor
                    : veriSemantic(context, veriExpense),
                detail: l10n.entriesCount(expenseCount),
              ),
              SummaryMetric(
                label: l10n.metricMonthNet,
                value: formatSignedAmount(net),
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetExecutionCard extends StatelessWidget {
  const _BudgetExecutionCard({
    required this.budget,
    required this.expense,
    required this.keyMonth,
    required this.snapshots,
  });

  final double budget;
  final double expense;

  /// 当期预算周期的键月（预算存储键）。角标据此展示所属周期。
  final DateTime keyMonth;

  final List<CategoryBudgetSnapshot> snapshots;

  @override
  Widget build(BuildContext context) {
    final controller = VeriFinScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    // 自定义预算周期时角标展示周期日期范围，自然月展示「N月」。
    final periodBadge = controller.budgetCycleIsCustom
        ? AppLocalizations.of(context).budgetCycleRange(
            controller.budgetWindow(keyMonth).start,
            controller.budgetWindow(keyMonth).end,
          )
        : AppLocalizations.of(context).monthNumber(keyMonth.month);
    final ratio = budget <= 0 ? 0.0 : expense / budget;
    final remaining = budget - expense;
    final budgetedCount = snapshots
        .where((snapshot) => snapshot.hasBudget)
        .length;
    final overBudgetCount = snapshots
        .where((snapshot) => snapshot.overBudget)
        .length;
    final color = budget <= 0
        ? veriLine
        : remaining < 0
        ? veriSemantic(context, veriExpense)
        : ratio >= 0.85
        ? veriSemantic(context, veriWarning)
        : Theme.of(context).colorScheme.primary;

    return VeriCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      // 首页预算面板可被用户在面板管理里关闭，此卡是关掉后进入预算总览的唯一入口。
      onTap: () => Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => BudgetOverviewPage(initialMonth: keyMonth),
        ),
      ),
      quietTap: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // 与其他面板共用 SectionTitle，保证「预算执行」标题与同页其它卡片同级。
          SectionTitle(
            title: AppLocalizations.of(context).panelBudgetExecutionLabel,
            trailing: periodBadge,
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      budget <= 0
                          ? AppLocalizations.of(context).notSetBudget
                          : remaining < 0
                          ? AppLocalizations.of(context).overBudgetLabel
                          : AppLocalizations.of(context).remainingBudgetLabel,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.50),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      budget <= 0
                          ? formatExpenseAmount(expense)
                          : remaining < 0
                          ? formatExpenseAmount(remaining.abs())
                          : formatAmount(remaining),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            // 无预算时这里展示实际支出，不能继承进度条的浅分隔线色。
                            color: veriUnifiedDesignPreview && budget <= 0
                                ? (isZeroAmount(expense)
                                      ? Theme.of(context).colorScheme.onSurface
                                      : colorForType(
                                          context,
                                          EntryType.expense,
                                        ))
                                : color,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                  ],
                ),
              ),
              Text(
                budget <= 0
                    ? AppLocalizations.of(context).expenseOnlyNote
                    : AppLocalizations.of(
                        context,
                      ).usedPercent((ratio * 100).toStringAsFixed(0)),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.48),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: budget <= 0 ? 0 : ratio.clamp(0, 1).toDouble(),
              minHeight: 6,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.56),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 12),
          // 与本页顶部的收支摘要卡共用 SummaryMetric，保证三块指标的标签/数值字号
          // 与同页其它卡片一致。
          Row(
            children: <Widget>[
              SummaryMetric(
                label: AppLocalizations.of(context).monthBudgetLabel,
                value: formatAmount(budget),
                color: scheme.onSurface,
              ),
              SummaryMetric(
                label: AppLocalizations.of(context).budgetMonthExpense,
                value: formatExpenseAmount(expense),
                color: veriSemantic(context, veriExpense),
              ),
              SummaryMetric(
                label: AppLocalizations.of(context).categoryBudgetTitle,
                value: AppLocalizations.of(context).countItems(budgetedCount),
                color: scheme.onSurface,
                // 未设分类预算时没有「执行情况」可判断，绿色「正常」会被误读为
                // 已设预算且执行良好。
                detail: overBudgetCount > 0
                    ? AppLocalizations.of(
                        context,
                      ).overCountLabel(overBudgetCount)
                    : budgetedCount == 0
                    ? AppLocalizations.of(context).notSet
                    : AppLocalizations.of(context).normalLabel,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryRingChart extends StatefulWidget {
  const _CategoryRingChart({
    required this.stats,
    required this.total,
    required this.ringSize,
  });

  final List<_CategoryStat> stats;
  final double total;
  final double ringSize;

  @override
  State<_CategoryRingChart> createState() => _CategoryRingChartState();
}

class _CategoryRingChartState extends State<_CategoryRingChart> {
  int? _selectedIndex;

  @override
  void didUpdateWidget(covariant _CategoryRingChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stats != widget.stats) {
      _selectedIndex = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final brightness = Theme.of(context).brightness;
    final primary = Theme.of(context).colorScheme.primary;
    final mutedColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.56);
    final neutral = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.45);
    final segments = _categoryRingSegments(
      l10n,
      widget.stats,
      brightness,
      primary,
      neutral,
    );
    final selected =
        _selectedIndex != null &&
            _selectedIndex! >= 0 &&
            _selectedIndex! < segments.length
        ? segments[_selectedIndex!]
        : null;
    final selectedPercent = selected == null || widget.total <= 0
        ? 0.0
        : selected.value / widget.total;

    return SizedBox(
      width: double.infinity,
      height: widget.ringSize + 26,
      child: Center(
        child: SizedBox(
          width: widget.ringSize,
          height: widget.ringSize,
          child: VeriDonutChart(
            segments: segments,
            selectedIndex: _selectedIndex,
            onSelected: (index) => setState(() => _selectedIndex = index),
            ringWidth: math.max(14.0, widget.ringSize * 0.14),
            semanticsLabel: l10n.panelCategoryRingLabel,
            center: selected == null
                ? Text(
                    formatExpenseAmount(widget.total),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        selected.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: mutedColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        formatExpenseAmount(selected.value),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${(selectedPercent * 100).toStringAsFixed(1)}%',
                        maxLines: 1,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: selected.color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

List<VeriDonutSegment> _categoryRingSegments(
  AppLocalizations l10n,
  List<_CategoryStat> stats,
  Brightness brightness,
  Color primary,
  Color neutral,
) {
  if (stats.isEmpty) {
    return const <VeriDonutSegment>[];
  }
  final colors = <Color>[
    primary,
    veriSemanticFor(brightness, veriBlue),
    veriCyan,
    veriMint,
    veriSemanticFor(brightness, veriWarning),
    neutral,
  ];
  final total = stats.fold<double>(0, (sum, stat) => sum + stat.amount);
  if (total <= 0) {
    return const <VeriDonutSegment>[];
  }
  final visible = stats.take(5).toList();
  final hidden = stats.skip(5).toList();
  final segments = <VeriDonutSegment>[
    for (final item in visible.indexed)
      VeriDonutSegment(
        label: item.$2.category.label,
        value: item.$2.amount,
        color: colors[item.$1 % colors.length],
      ),
  ];
  final otherAmount = hidden.fold<double>(0, (sum, stat) => sum + stat.amount);
  if (otherAmount > 0) {
    segments.add(
      VeriDonutSegment(
        label: l10n.othersLabel,
        value: otherAmount,
        color: neutral,
      ),
    );
  }
  return segments;
}

class _CategoryStat {
  const _CategoryStat({
    required this.category,
    required this.amount,
    required this.percent,
    required this.count,
  });

  final Category category;
  final double amount;
  final double percent;
  final int count;
}

class _CategoryStatTile extends StatelessWidget {
  const _CategoryStatTile({required this.stat});

  final _CategoryStat stat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          CategoryIconBox(
            iconCode: stat.category.iconCode,
            color: veriSemantic(context, veriExpense),
            size: 30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        stat.category.label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      formatExpenseAmount(stat.amount),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: veriSemantic(context, veriExpense),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: stat.percent.clamp(0, 1).toDouble(),
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(999),
                  color: veriSemantic(context, veriExpense),
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 4),
                Text(
                  '${(stat.percent * 100).toStringAsFixed(1)}% · ${AppLocalizations.of(context).entriesCount(stat.count)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.46),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TagStatTile extends StatelessWidget {
  const _TagStatTile({required this.stat});

  final _TagStat stat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: <Widget>[
          VeriIconBox(
            icon: Icons.label,
            color: Theme.of(context).colorScheme.primary,
            size: 30,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        stat.tag.label,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Text(
                      formatExpenseAmount(stat.amount),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: veriSemantic(context, veriExpense),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                LinearProgressIndicator(
                  value: stat.percent.clamp(0, 1).toDouble(),
                  minHeight: 5,
                  borderRadius: BorderRadius.circular(999),
                  color: Theme.of(context).colorScheme.primary,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                ),
                const SizedBox(height: 4),
                Text(
                  '${AppLocalizations.of(context).tagShareOfExpense((stat.percent * 100).toStringAsFixed(1))} · ${AppLocalizations.of(context).entriesCount(stat.count)}',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.46),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 分类统计：多级分类按层级聚合，即每笔交易的金额归总到其**顶级祖先**分类，
/// 子分类的支出滚动计入所属顶级分类。
List<_CategoryStat> _categoryStats(
  List<LedgerEntry> entries,
  List<Category> categories,
) {
  final totals = <String, double>{};
  final counts = <String, int>{};
  for (final entry in entries) {
    final rootId = rootIdOf(categories, entry.categoryId);
    // 退款/报销回款按净额计入分类统计。
    totals.update(
      rootId,
      (value) => value + entry.netAmount,
      ifAbsent: () => entry.netAmount,
    );
    counts.update(rootId, (value) => value + 1, ifAbsent: () => 1);
  }

  final total = totals.values.fold<double>(0, (sum, value) => sum + value);
  final stats =
      totals.entries
          .map(
            (entry) => _CategoryStat(
              category: categoryById(entry.key, categories),
              amount: entry.value,
              percent: total <= 0 ? 0 : entry.value / total,
              count: counts[entry.key] ?? 0,
            ),
          )
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));
  return stats;
}

class _TagStat {
  const _TagStat({
    required this.tag,
    required this.amount,
    required this.percent,
    required this.count,
  });

  final Tag tag;
  final double amount;

  /// 该标签支出占本月总支出的比例（多标签交易会分别计入各标签，故各项之和可能 >1）。
  final double percent;
  final int count;
}

/// 标签统计：每笔支出计入其携带的**每个**标签；[totalExpense] 为本月总支出，
/// 用作占比分母（表示该标签覆盖了本月多少支出）。
List<_TagStat> _tagStats(
  List<LedgerEntry> entries,
  List<Tag> tags,
  double totalExpense,
) {
  final labelById = <String, Tag>{for (final tag in tags) tag.id: tag};
  final totals = <String, double>{};
  final counts = <String, int>{};
  for (final entry in entries) {
    for (final tagId in entry.tagIds) {
      if (!labelById.containsKey(tagId)) {
        continue;
      }
      totals.update(
        tagId,
        (value) => value + entry.netAmount,
        ifAbsent: () => entry.netAmount,
      );
      counts.update(tagId, (value) => value + 1, ifAbsent: () => 1);
    }
  }
  final stats =
      totals.entries
          .map(
            (entry) => _TagStat(
              tag: labelById[entry.key]!,
              amount: entry.value,
              percent: totalExpense <= 0 ? 0 : entry.value / totalExpense,
              count: counts[entry.key] ?? 0,
            ),
          )
          .toList()
        ..sort((a, b) => b.amount.compareTo(a.amount));
  return stats;
}
