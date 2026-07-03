import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app/app_theme.dart';
import 'app/chart_painters.dart';
import 'app/common_widgets.dart';
import 'app/entry_sheets.dart';
import 'app/ledger_math.dart';
import 'app/models.dart';
import 'app/series_math.dart';
import 'app/platform_bridge.dart';
import 'app/veri_fin_controller.dart';
import 'app/veri_fin_scope.dart';
import 'local_storage/local_storage.dart';
import 'pages/assets_pages.dart';
import 'pages/budget_pages.dart';
import 'pages/entry_detail_page.dart';
import 'pages/profile_pages.dart';
import 'pages/reports_page.dart';
import 'pages/sheets.dart';
import 'pages/transactions_pages.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await LocalKeyValueStore.create();
  runApp(VeriFinApp(store: store));
}

class VeriFinApp extends StatefulWidget {
  const VeriFinApp({super.key, this.store});

  final LocalKeyValueStore? store;

  @override
  State<VeriFinApp> createState() => _VeriFinAppState();
}

class _VeriFinAppState extends State<VeriFinApp> {
  late final VeriFinController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VeriFinController(widget.store ?? LocalKeyValueStore());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return VeriFinScope(
      controller: _controller,
      child: ValueListenableBuilder<ThemePreference>(
        valueListenable: _controller.themePreferenceListenable,
        builder: (context, themePreference, _) {
          return MaterialApp(
            title: 'Veri Fin',
            debugShowCheckedModeBanner: false,
            locale: const Locale('zh', 'CN'),
            supportedLocales: const <Locale>[
              Locale('zh', 'CN'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
              GlobalMaterialLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
            ],
            themeMode: themePreference.themeMode,
            theme: buildVeriFinTheme(Brightness.light),
            darkTheme: buildVeriFinTheme(Brightness.dark),
            home: const VeriFinShell(),
          );
        },
      ),
    );
  }
}

class VeriFinShell extends StatefulWidget {
  const VeriFinShell({super.key});

  @override
  State<VeriFinShell> createState() => _VeriFinShellState();
}

class _VeriFinShellState extends State<VeriFinShell> {
  int _index = 0;
  DateTime? _lastBackPressedAt;

  @override
  void initState() {
    super.initState();
    AppPlatformBridge.setQuickEntryHandler(_openQuickEntryFromPlatform);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (await AppPlatformBridge.consumeInitialQuickEntryIntent() && mounted) {
        await _openQuickEntryFromPlatform();
      }
    });
  }

  @override
  void dispose() {
    AppPlatformBridge.clearQuickEntryHandler();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      const HomePage(),
      const AssetsPage(),
      const ReportsPage(),
      const ProfilePage(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) {
          return;
        }
        _handleRootBack();
      },
      child: Scaffold(
        body: SafeArea(child: pages[_index]),
        floatingActionButton: _index == 0
            ? FloatingActionButton(
                key: const Key('quick_entry_fab'),
                onPressed: () => _startQuickEntry(context),
                tooltip: '快速记账',
                child: const Icon(Icons.add),
              )
            : null,
        bottomNavigationBar: VeriBottomNav(
          currentIndex: _index,
          onTap: (value) => setState(() => _index = value),
        ),
      ),
    );
  }

  void _handleRootBack() {
    if (_index != 0) {
      setState(() => _index = 0);
      return;
    }
    final now = DateTime.now();
    final shouldExit =
        _lastBackPressedAt != null &&
        now.difference(_lastBackPressedAt!) < const Duration(seconds: 2);
    if (shouldExit) {
      SystemNavigator.pop();
      return;
    }
    _lastBackPressedAt = now;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('再次返回退出程序')));
  }

  Future<void> _startQuickEntry(BuildContext context) async {
    final amount = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => NumberPadSheet(
        title: '快速记账',
        hapticsEnabled: VeriFinScope.of(context).hapticsEnabled,
      ),
    );

    if (!context.mounted || amount == null || amount <= 0) {
      return;
    }

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => EntryDetailPage(initialAmount: amount),
      ),
    );
  }

  Future<void> _openQuickEntryFromPlatform() async {
    if (!mounted) {
      return;
    }
    if (_index != 0) {
      setState(() => _index = 0);
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
    if (!mounted) {
      return;
    }
    await _startQuickEntry(context);
  }
}

class VeriBottomNav extends StatelessWidget {
  const VeriBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = <_NavItem>[
    _NavItem(Icons.home_outlined, Icons.home, '首页'),
    _NavItem(
      Icons.account_balance_wallet_outlined,
      Icons.account_balance_wallet,
      '资产',
    ),
    _NavItem(Icons.bar_chart_outlined, Icons.bar_chart, '看板'),
    _NavItem(Icons.person_outline, Icons.person, '我的'),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      key: const Key('main_bottom_nav'),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D0F12) : Colors.white,
        border: Border(
          top: BorderSide(color: isDark ? Colors.white10 : veriLine),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: <Widget>[
              for (var index = 0; index < _items.length; index += 1)
                Expanded(
                  child: _BottomNavButton(
                    key: Key('main_tab_$index'),
                    item: _items[index],
                    selected: currentIndex == index,
                    onTap: () => onTap(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem(this.icon, this.activeIcon, this.label);

  final IconData icon;
  final IconData activeIcon;
  final String label;
}

class _BottomNavButton extends StatelessWidget {
  const _BottomNavButton({
    super.key,
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? veriRoyal
        : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45);
    return Tooltip(
      message: item.label,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        child: Semantics(
          label: item.label,
          selected: selected,
          button: true,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                width: selected ? 42 : 38,
                height: 32,
                decoration: BoxDecoration(
                  color: selected
                      ? veriRoyal.withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Icon(
                  selected ? item.activeIcon : item.icon,
                  color: color,
                  size: selected ? 22 : 21,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = VeriFinScope.of(context);
    final entries = controller.entries;
    final now = DateTime.now();
    final monthEntries = entries
        .where(
          (entry) =>
              entry.occurredAt.year == now.year &&
              entry.occurredAt.month == now.month,
        )
        .toList();
    final monthExpense = sumByType(monthEntries, EntryType.expense);
    final trendWindow = sevenDayWindowFor(now);
    final trendEntries = entriesInWindow(monthEntries, trendWindow);
    final trendExpense = sumByType(trendEntries, EntryType.expense);
    final trendIncome = sumByType(trendEntries, EntryType.income);
    final recentEntries = entries.take(5).toList();
    final monthlyBudget = controller.monthlyBudget(now);
    final categoryBudgetSnapshots = computeCategoryBudgetSnapshots(
      controller: controller,
      month: now,
      monthEntries: monthEntries,
    );
    final categoryBudgetRisk = topCategoryBudgetRisk(categoryBudgetSnapshots);

    return VeriPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 82),
        children: <Widget>[
          const PageHeader(title: '首页', subtitle: '日常账本'),
          const SizedBox(height: 10),
          HomeTrendPanel(
            window: trendWindow,
            expense: trendExpense,
            income: trendIncome,
            values: valuesForTypeInWindow(
              trendEntries,
              trendWindow,
              EntryType.expense,
            ),
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (context) => const IncomeExpenseStatsPage(),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          VeriCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SectionHeaderAction(
                  title: '最近交易',
                  trailing: recentEntries.isEmpty
                      ? '暂无'
                      : formatSignedAmount(
                          recentEntries.fold<double>(
                            0,
                            (sum, entry) => sum + signedAmount(entry),
                          ),
                        ),
                  onTap: () {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (context) => const TransactionsPage(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                if (recentEntries.isEmpty)
                  const EmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: '还没有交易',
                    description: '点击右下角加号开始第一笔记账。',
                  )
                else
                  for (final item in recentEntries.indexed) ...<Widget>[
                    TransactionTile(
                      item.$2,
                      accounts: controller.accounts,
                      categories: controller.categories,
                      onTap: () => openEntryDetail(context, item.$2),
                    ),
                    if (item.$1 != recentEntries.length - 1)
                      Divider(
                        indent: 19,
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.06),
                      ),
                  ],
              ],
            ),
          ),
          const SizedBox(height: 10),
          BudgetPanel(
            month: now,
            expense: monthExpense,
            budget: monthlyBudget,
            categoryRisk: categoryBudgetRisk,
            onTap: () {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (context) => BudgetSettingsPage(initialMonth: now),
                ),
              );
            },
          ),
          const SizedBox(height: 10),
          CalendarPreview(
            entries: entries,
            onDayTap: (date) {
              Navigator.of(context).push<void>(
                MaterialPageRoute<void>(
                  builder: (context) => TransactionsPage(initialDate: date),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class SectionHeaderAction extends StatelessWidget {
  const SectionHeaderAction({
    super.key,
    required this.title,
    required this.trailing,
    required this.onTap,
  });

  final String title;
  final String trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(veriRadiusSm),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            if (trailing.isNotEmpty) ...<Widget>[
              Text(
                trailing,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.52),
                ),
              ),
              const SizedBox(width: 6),
            ],
            const _CircleArrow(),
          ],
        ),
      ),
    );
  }
}

class HomeTrendPanel extends StatelessWidget {
  const HomeTrendPanel({
    super.key,
    required this.window,
    required this.expense,
    required this.income,
    required this.values,
    required this.onTap,
  });

  final DateWindow window;
  final double expense;
  final double income;
  final List<double> values;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = Theme.of(context).colorScheme.onSurface;
    final mutedColor = textColor.withValues(alpha: isDark ? 0.62 : 0.52);
    final net = income - expense;
    final daysWithExpense = values.where((value) => value > 0).length;
    final hasExpense = !isZeroAmount(expense);
    final netColor = isZeroAmount(net)
        ? mutedColor
        : (net > 0 ? veriIncome : veriExpense);

    return VeriCard(
      onTap: onTap,
      quietTap: true,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      child: RepaintBoundary(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        window.label,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: mutedColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '支出走势',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
                const _CircleArrow(),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  formatExpenseAmount(expense),
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: hasExpense ? veriExpense : mutedColor,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: netColor.withValues(alpha: isDark ? 0.16 : 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '结余 ${formatSignedAmount(net)}',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: netColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                Expanded(
                  child: _TrendMetric(
                    label: '收入',
                    value: formatAmount(income),
                    color: isZeroAmount(income) ? mutedColor : veriIncome,
                    dark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TrendMetric(
                    label: '记账日',
                    value: '$daysWithExpense天',
                    color: veriRoyal,
                    dark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _TrendMetric(
                    label: '日均支出',
                    value: formatAmount(
                      expense / window.days.length.clamp(1, 7),
                    ),
                    color: veriBlue,
                    dark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 138,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(2, 6, 2, 0),
                child: CustomPaint(
                  painter: TrendLinePainter(
                    color: hasExpense ? veriExpense : mutedColor,
                    values: values,
                    xLabels: labelsForWindow(window),
                    yLabels: reportAxisLabels(values.fold(0, math.max)),
                    labelColor: mutedColor,
                    glow: isDark,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendMetric extends StatelessWidget {
  const _TrendMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.dark,
  });

  final String label;
  final String value;
  final Color color;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: dark
            ? color.withValues(alpha: 0.14)
            : color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(veriRadiusSm),
        border: Border.all(
          color: dark
              ? color.withValues(alpha: 0.18)
              : color.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.50),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: dark ? Colors.white.withValues(alpha: 0.86) : color,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class BudgetPanel extends StatelessWidget {
  const BudgetPanel({
    super.key,
    required this.month,
    required this.expense,
    required this.budget,
    required this.categoryRisk,
    required this.onTap,
  });

  final DateTime month;
  final double expense;
  final double budget;
  final CategoryBudgetSnapshot? categoryRisk;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final remaining = (budget - expense).clamp(0, budget).toDouble();
    final daysInMonth = DateUtils.getDaysInMonth(
      DateTime.now().year,
      DateTime.now().month,
    );
    final remainingDays = (daysInMonth - DateTime.now().day + 1).clamp(
      1,
      daysInMonth,
    );
    final ratio = budget <= 0 ? 0.0 : (expense / budget).clamp(0, 1).toDouble();

    return VeriCard(
      onTap: onTap,
      quietTap: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${month.month}月预算',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const _CircleArrow(),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: <Widget>[
              Expanded(
                child: BudgetSideStat(
                  label: '支出',
                  value: formatExpenseAmount(expense),
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              SizedBox(
                width: 132,
                height: 132,
                child: Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    SizedBox(
                      width: 116,
                      height: 116,
                      child: CustomPaint(
                        painter: BudgetRingPainter(
                          value: ratio,
                          trackColor: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest
                              .withValues(alpha: 0.48),
                          progressColor: budgetProgressColor(
                            budget,
                            budget - expense,
                            ratio,
                          ),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Text(
                          '剩余',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.45),
                              ),
                        ),
                        Text(
                          formatAmount(remaining),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        Text(
                          '${(ratio * 100).toStringAsFixed(0)}%',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.45),
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: BudgetSideStat(
                  label: '剩余日均',
                  value: formatAmount(remaining / remainingDays),
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Center(
            child: Text(
              '预算 ${formatAmount(budget)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withValues(alpha: 0.44),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (categoryRisk != null) ...<Widget>[
            const SizedBox(height: 8),
            _HomeBudgetRiskBanner(snapshot: categoryRisk!),
          ],
        ],
      ),
    );
  }
}

class _CircleArrow extends StatelessWidget {
  const _CircleArrow();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: veriRoyal.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Icon(Icons.chevron_right, size: 17, color: veriRoyal),
    );
  }
}

class IncomeExpenseStatsPage extends StatefulWidget {
  const IncomeExpenseStatsPage({super.key});

  @override
  State<IncomeExpenseStatsPage> createState() => _IncomeExpenseStatsPageState();
}

class _IncomeExpenseStatsPageState extends State<IncomeExpenseStatsPage> {
  DateTime _focusDate = DateTime.now();
  EntryType _type = EntryType.expense;

  @override
  Widget build(BuildContext context) {
    final controller = VeriFinScope.of(context);
    final visibleMonth = DateTime(_focusDate.year, _focusDate.month);
    final window = sevenDayWindowFor(_focusDate);
    final scopedEntries = controller.entries
        .where(
          (entry) =>
              entry.occurredAt.year == visibleMonth.year &&
              entry.occurredAt.month == visibleMonth.month &&
              entry.type == _type,
        )
        .toList();
    final windowEntries = entriesInWindow(scopedEntries, window);
    final total = windowEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.amount,
    );
    final dayRows = _dailyStatRows(windowEntries, window.start, total);
    final windowValues = valuesForTypeInWindow(windowEntries, window, _type);
    final mutedColor = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.52);
    final totalColor = isZeroAmount(total) ? mutedColor : colorForType(_type);
    final totalText = switch (_type) {
      EntryType.expense => formatExpenseAmount(total),
      EntryType.income => formatIncomeAmount(total),
      EntryType.transfer => formatAmount(total),
    };

    return Scaffold(
      body: SafeArea(
        child: VeriPage(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
            children: <Widget>[
              const VeriHeader(title: '收支统计', showBack: true),
              const SizedBox(height: 8),
              Row(
                children: <Widget>[
                  MonthSwitcher(
                    month: visibleMonth,
                    onPrevious: () => setState(() {
                      _focusDate = DateTime(
                        _focusDate.year,
                        _focusDate.month - 1,
                      );
                    }),
                    onNext: () => setState(() {
                      _focusDate = DateTime(
                        _focusDate.year,
                        _focusDate.month + 1,
                      );
                    }),
                  ),
                  const Spacer(),
                  FilterPill(label: _type.label, onTap: _pickEntryType),
                ],
              ),
              const SizedBox(height: 10),
              VeriCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      '${window.label} ${_type.label}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalText,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: totalColor,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 180,
                      child: CustomPaint(
                        painter: TrendLinePainter(
                          color: totalColor,
                          values: windowValues,
                          xLabels: labelsForWindow(window),
                          yLabels: reportAxisLabels(
                            windowValues.fold(0, math.max),
                          ),
                          labelColor: Theme.of(
                            context,
                          ).colorScheme.onSurface.withValues(alpha: 0.50),
                        ),
                        child: const SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              VeriCard(
                child: Column(
                  children: <Widget>[
                    if (dayRows.isEmpty)
                      const EmptyState(
                        icon: Icons.bar_chart_outlined,
                        title: '暂无统计',
                        description: '当前月份没有对应记录。',
                      )
                    else
                      for (final row in dayRows.indexed) ...<Widget>[
                        _DailyStatTile(row: row.$2, type: _type),
                        if (row.$1 != dayRows.length - 1) const Divider(),
                      ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickEntryType() async {
    final selected = await showOptionSheet<EntryType>(
      context: context,
      title: '统计类型',
      values: EntryType.values,
      selected: _type,
      labelOf: (value) => value.label,
    );
    if (selected != null) {
      setState(() => _type = selected);
    }
  }
}

class _HomeBudgetRiskBanner extends StatelessWidget {
  const _HomeBudgetRiskBanner({required this.snapshot});

  final CategoryBudgetSnapshot snapshot;

  @override
  Widget build(BuildContext context) {
    final color = snapshot.overBudget ? veriExpense : veriWarning;
    final text = snapshot.overBudget
        ? '${snapshot.category.label}超出 ${formatAmount(snapshot.spent - snapshot.budget)}'
        : '${snapshot.category.label}已用 ${(snapshot.ratio * 100).toStringAsFixed(0)}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(veriRadiusSm),
        border: Border.all(color: color.withValues(alpha: 0.14)),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            snapshot.overBudget
                ? Icons.warning_amber_rounded
                : Icons.error_outline,
            color: color,
            size: 17,
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyStatRow {
  const _DailyStatRow({
    required this.date,
    required this.amount,
    required this.percent,
    required this.count,
  });

  final DateTime date;
  final double amount;
  final double percent;
  final int count;
}

class _DailyStatTile extends StatelessWidget {
  const _DailyStatTile({required this.row, required this.type});

  final _DailyStatRow row;
  final EntryType type;

  @override
  Widget build(BuildContext context) {
    final amountColor = colorForType(type);
    final amountText = switch (type) {
      EntryType.expense => formatExpenseAmount(row.amount),
      EntryType.income => '+${formatIncomeAmount(row.amount)}',
      EntryType.transfer => formatAmount(row.amount),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: <Widget>[
          VeriIconBox(
            icon: Icons.calendar_today_outlined,
            color: amountColor,
            size: 28,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${row.date.month.toString().padLeft(2, '0')}.${row.date.day.toString().padLeft(2, '0')}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${(row.percent * 100).toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.48),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                amountText,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: amountColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${row.count}笔',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.48),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

List<_DailyStatRow> _dailyStatRows(
  List<LedgerEntry> entries,
  DateTime month,
  double total,
) {
  final rows = <_DailyStatRow>[];
  final days = DateUtils.getDaysInMonth(month.year, month.month);
  for (var day = 1; day <= days; day += 1) {
    final dayEntries = entries
        .where((entry) => entry.occurredAt.day == day)
        .toList();
    if (dayEntries.isEmpty) {
      continue;
    }
    final amount = dayEntries.fold<double>(
      0,
      (sum, entry) => sum + entry.amount,
    );
    rows.add(
      _DailyStatRow(
        date: DateTime(month.year, month.month, day),
        amount: amount,
        percent: total <= 0 ? 0 : amount / total,
        count: dayEntries.length,
      ),
    );
  }
  return rows..sort((a, b) => b.date.compareTo(a.date));
}
