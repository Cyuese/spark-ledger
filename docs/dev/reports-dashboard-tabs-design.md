# 看板分 Tab、新增面板与统计能力整合设计

> 状态：**已实施完成**（阶段 1–6 全部落地，每阶段一个提交）。原独立统计分析页已按维护者授权删除，能力并入看板。
> 分支：`talyra42/reports-dashboard-tabs`
> 日期：2026-10-11

需求来源：维护者 2026-10-11 口述 + 两张一木记账截图 + 13 条批注。

## 1. 最终决策（已确认，不再讨论）

| 议题 | 决策 |
| --- | --- |
| Tab 结构 | 看板顶部加 4 个 Tab：**日常 / 月统计 / 年统计 / 自定义**（沿用维护者命名，命名影响不大） |
| 默认 Tab | **日常**；**不记住**上次选择，每次进看板都落在日常 |
| 年统计 / 自定义 | **只放空 Tab，内容为空**；不加「即将推出」、不加空态插画、不加任何占位文案 |
| 统计分析页 | **彻底移除页面**，能力整合进看板；「我的 → 数据与工具 → 统计分析」入口一并删除 |
| 摘要卡（本月收入/支出/结余） | **不复用、不跟随周期**；只在**月统计**出现，且重做成一张正经的月度数据卡（备选：直接删除，见 §14） |
| 近 7 日 / 本周 | 本周 = 自然周（周一至周日，含今天，未来日为 0）；日均 = 总额 ÷ 7（固定 7） |
| 摘要卡与近 7 日联动 | **不联动**（摘要卡只在月统计；周期切换只属于近 7 日面板） |
| 资产汇总标注 | **不做引线、不做自绘**；用 `fl_chart` 自带分段标题（百分比）+ 图例，以稳定性为准 |
| 资产汇总交互 | 点分段 = 高亮该账户；点中心 = 金额 / 占比切换；点中心空区 = 取消选中 |
| 资产汇总范围 | **排除**隐藏账户与「不计入资产」账户 |
| 「过滤占比小于 1%」开关 | **不做** |
| 同比 / 环比 | **删除，不再迁移**（原统计分析页的对比卡直接去掉；底层纯函数因 AI 工具在用而保留） |
| 摘要卡 | 确认即看板最上方那三个数（本月收入/支出/结余）：**保留并重做，作为月视图里的一个面板** |
| 提交方式 | 每个阶段完成并通过验证后**立即提交**，不堆积到最后 |

## 2. 结论速览

- **Tab 的本质是周期切换**，用既有 `VeriSegmentedControl` 实现，不新造 Tab 控件。
- **本次范围比初稿大**：不只是「加两个面板」，还要**拆掉统计分析页并把能力搬进看板**。因此阶段划分里，删除动作放在能力迁移完成之后（§3.3）。
- **新增面板 2 个**：近 7 日统计、资产汇总；资产汇总复用 `fl_chart` 自带能力，**不需要新的自绘代码**。
- **面板配置升级为「一 Tab 一清单」**，涉及 KV 与备份迁移（§8）。

## 3. 统计分析页：移除与能力迁移

### 3.1 背景（为什么移除）

现状两页功能重叠，维护者判定该页「食之无味、弃之可惜」，决定不保留独立页面：

| 能力 | 看板 `ReportsPage` | 统计分析 `ReportAnalysisPage` |
| --- | --- | --- |
| 时间范围 | 固定自然月（预算卡走预算周期） | 本月 / 本年 / 自定义区间 |
| 收支维度 | 只支出（顶部摘要含收入/结余） | 支出 / 收入可切 |
| 汇总指标 | 本月收入/支出/结余 | 收入/支出/结余 + 笔数 |
| 趋势图 | 日趋势、今年每月支出 | 按范围的趋势曲线 |
| 分类/标签排行 | 分类统计（环）、分类明细、标签统计 | 顶级分类 / 子分类 / 标签排行 + 下钻 |
| 同比 / 环比 | 无 | 月模式下有 |

### 3.2 能力迁移映射

| 原统计分析页能力 | 迁入位置 |
| --- | --- |
| 范围切换（本月 / 本年 / 自定义） | 看板的「月统计 / 年统计 / 自定义」Tab |
| 概览汇总（收入 / 支出 / 结余 + 笔数） | 月统计 Tab 的摘要数据卡（吸收 `_SummaryCard` 的笔数信息） |
| 维度切换（支出 / 收入） | 抽共享件，供近 7 日面板与月/年/自定义 Tab 共用 |
| 趋势卡（按范围） | 各 Tab 的趋势面板 |
| 分类 / 标签排行（含 3 路切换与点行下钻） | 月统计 Tab 的排行面板，见 §3.4 的口语说明 |

**直接删除、不迁移**：

- 同比 / 环比对比卡（`_ComparisonCard`、`_ComparisonRow`）及其文案键（`yoyMomTitle` / `yoyMomDesc` / `momLabel` / `yoyLabel`，已核实仅该页使用）。
- 底层纯函数 `reportMonthlyComparison` / `formatChangeRatio` 及其测试**保留**：AI 账目查询工具（`ai/ai_query_tool.dart`）仍在调用，不属于可删范围。

**保留不动**：`lib/app/report_analysis.dart` 的纯函数（`reportSummary` / `reportTrend` / `reportCategoryStats` / `reportCategoryStatsByOwn` / `reportCategoryChildStats` / `reportTagStats` / `reportMonthlyComparison` / `formatChangeRatio` / `ReportRange`…）。AI 账目查询工具（`ai/ai_query_tool.dart`）与新的看板面板都依赖它们，**只删页面，不删领域函数**。

### 3.3 删除清单与顺序约束

删除对象：

1. `lib/pages/report_analysis_page.dart`（页面本体与其私有 widget）。
2. `lib/pages/reports_page.dart` 页头的「统计分析」`HeaderAction`（`Icons.insights_outlined`）——移除该入口，保留 AI 入口。
3. `lib/pages/profile_pages.dart` 中「数据与工具 → 统计分析」入口（约 230 行）。
4. `test/report_analysis_page_test.dart`（整页测试）。
5. `test/single_currency_unit_test.dart:152` 中 `pumpPage(... ReportAnalysisPage())` 的用例——改挂到看板对应卡片，或删除（该用例验证的是单位隐藏，迁移后应改到新卡片上，不丢覆盖）。
6. 仅该页使用的 l10n 键在确认无其它引用后清理：`statAnalysisTitle`、`yoyMomTitle`、`yoyMomDesc`、`momLabel`、`yoyLabel`（已核实这几条只被该页使用）。
7. `docs/ui-guidelines.md:70` 把 `report_analysis_page.dart` 列为「参照实现」——改为指向新的看板页面。

**顺序约束**：只有当月/年/自定义 Tab 已经承载原统计分析的能力后，才执行删除，避免中间态丢功能。因此删除放在**阶段 6**（§13）。在此之前，页头与「我的」的入口**暂时保留**。

### 3.4 口语说明：「分组排行 + 下钻」指什么

不是新概念，就是统计分析页现在那张**排行卡**，说清楚它是两件事：

**分组排行**：一张卡，顶部有三选一的切换——「顶级分类 / 子分类 / 标签」。

- 选「顶级分类」：列表按**顶级分类**排名（餐饮、交通……），每行是「图标 + 名称 + 金额 + 占比进度条 + 笔数」，子分类的钱并入其顶级分类。
- 选「子分类」：列表按**实际记账所选的分类**排名（早餐、午餐……），不向上合并。
- 选「标签」：列表按标签排名（一笔交易有多个标签就分别计入，所以各行占比之和可能超过 100%）。

**下钻**：点列表里的一行会发生什么。

- 顶级分类模式下点一行 → 弹出底部弹层，列出该分类下的**子分类拆分**（餐饮 → 早餐 / 午餐 / 晚餐），弹层里点某一行、或点弹层底部的「查看交易」→ 跳到**按该分类筛选的交易列表**（`TransactionsPage(initialCategoryId:)`）。
- 子分类模式下点一行 → 直接跳到该分类的筛选交易列表。
- 标签模式可同理跳到按标签筛选的列表。

用途是「看排行发现问题 → 一路点到具体那几笔交易去改」。

## 4. 现状技术盘点（已核实，勿凭历史规划）

| 事项 | 事实（源码位置） |
| --- | --- |
| 看板页 | `lib/pages/reports_page.dart`：`PageHeader` + 固定 `_MonthSummaryCard` + 按 `enabledPanelIds(PanelPageKind.reports)` 渲染的 6 个面板 + 底部 `PanelSettingsEntry` |
| 面板目录 | `lib/app/models/preferences.dart`：`PanelPageKind{home,reports}`、`PagePanelSpec`、`homePanelSpecs`、`reportPanelSpecs`（6 项） |
| 面板持久化 | KV `verifin.home_panels.v1` / `verifin.report_panels.v1`；备份字段 `homePanels` / `reportPanels` |
| 面板归一化 | `_normalizePanelSettings`（`veri_fin_controller.dart:431`）：丢弃目录外 id、去重、**目录新增项追加到末尾并默认开启**，全关时强制开第一个 |
| 面板管理页 | `lib/pages/panel_settings_page.dart`：开关 + 排序草稿 + 软碟保存；至少保留 1 个开启 |
| 图表适配层 | `lib/app/chart_painters.dart`：`InteractiveTrendChart`、`InteractiveBarChart`（含 `VeriBarSeries`）、`VeriDonutChart`（`showTitle` 恒为 false、中心 `IgnorePointer`）、`VeriBudgetRing` |
| 分段控件 | `VeriSegmentedControl<T>`（`common_widgets.dart`），统计分析页三处切换都在用 |
| 范围模型 | `report_analysis.dart`：`ReportRangeMode{month,year,custom}`、`ReportRange.window`、`entriesInWindow` 等 |
| 周期窗口 | `ledger_math.dart`：`weekWindowFor`（周一至周日）、`monthWindowFor`、`cumulativeWeekWindowFor`、`quarterWindowFor`、`valuesForTypeInWindow`、`DateWindow.days` |
| 星期文案 | ARB 已有 `weekdayMon..weekdaySun`（值 `一..日`，日历表头用）；**没有**「周一」形态的键 |
| 资产折算 | `controller.accountBalancesInBase()` → `ConvertedAccountBalances.amountsByAccountId`（按账户、已折本位币）；缺率时 `isComplete=false`、`completeTotal=null` |
| 缺率空态 | 资产页已有「缺汇率」卡，可跳 `CurrencyRatesPage` |
| 摘要指标组件 | 已有 `SummaryMetric`；统计分析页另有私有 `_SummaryMetric`（带笔数），删除该页时一并处理 |
| fl_chart 环图能力 | 已核实 `PieChartSectionData` 支持 `title` / `titleStyle`（环内文字）与逐段 `radius`，官方 `pie_chart_sample2.dart` 正是「环内百分比 + 图例列表」的写法，**无需引线、无需自绘** |

## 5. 方案设计

### 5.1 顶部 Tab

```text
VeriPage > ListView(
  PageHeader(title: 看板, subtitle: 单位…, actions: [AI]),   // 统计分析入口在阶段 6 移除
  VeriSegmentedControl<看板Tab>(日常 / 月统计 / 年统计 / 自定义),
  <当前 Tab 的内容，按该 Tab 的面板配置渲染>,
  PanelSettingsEntry(当前 Tab),                              // 空 Tab 不渲染
)
```

- 用 `VeriSegmentedControl`（≤4 项、短文案、无需分区）。
- **默认「日常」，不持久化**（不进 KV、不进备份）。
- `PageHeader` 与切换条固定，不随 Tab 内容滚动（当前看板已是整页 `ListView`，Tab 条作为第一个 child 即可）。
- 无障碍：分段控件自带语义；切换后不强制移动焦点。

### 5.2 面板系统多 Tab 化（关键改动）

扩展 `PanelPageKind` 为「每个 Tab 一个 kind」，复用它已有的 specs / KV / 归一化 / 备份 / 管理页：

```dart
enum PanelPageKind { home, reportsDaily, reportsMonthly, reportsYearly, reportsCustom }
```

1. `PanelPageKind.values` 的既有遍历（state 初始化/载入、ops 重置 / 导入导出 / 初始化）会自动覆盖新 kind，不会漏路径。
2. **KV 键**：保留 `verifin.home_panels.v1`；看板按 Tab 分键（`verifin.report_daily_panels.v1` 等）。旧 kind `reports` 改名 `reportsMonthly` 后，**旧键 `verifin.report_panels.v1` 作为月统计的读取来源做一次性兼容**。
3. **备份字段**：`reportPanels` 继续表示月统计清单（旧备份可读、语义不突变）；新 Tab 用新字段；旧备份缺新字段 → 按新 kind 默认（全开）归一化。
4. **新增面板落位**：`_normalizePanelSettings` 现在把新项追加到**末尾**。摘要卡从固定区变成面板后，存量用户会看到它跑到最后——**建议改为「按 specs 声明位置插入」**（只影响缺失项，不动存量顺序）。该改动对 `home` 页也生效，需补测试。
5. `PanelSettingsEntry` / `PanelSettingsPage` 传当前 Tab 对应 kind；文案按 Tab 区分（「N 个日常面板」等）。空 Tab（年统计/自定义）**不渲染入口**。
6. `PanelPageKind.label()` 为 4 个看板 Tab 各补名称。

### 5.3 摘要卡 → 月统计专属数据卡

- 新增面板 spec（id 固定 `summary`），**只属于月统计 Tab**；不复用、不跟随周期。
- 从「页面顶部固定条」改为**正经的数据卡**：`SectionTitle`（如「本月收支」）+ 三块 `SummaryMetric`（收入 / 支出 / 结余），并吸收原统计分析页概览卡的**笔数**信息；配色与零值规则沿用现状。
- 默认位置：月统计 specs **首位**（配合 5.2 第 4 点）；默认开启；受「至少保留一个面板」兜底。
- 删除 `reports_page.dart` 的 `_MonthSummaryCard`。

### 5.4 日常 Tab · 近 7 日统计面板

```text
SectionTitle(近7日统计) + trailing(切换「近7日 / 本周」)
VeriSegmentedControl<EntryType>(支出 / 收入)     ← 与看板其它口径切换同款共享件
InteractiveBarChart(7 根柱, xLabels = 周一..周日 或 M.D)
文字统计（两列两行）: 总支出 / 日均支出 | 总收入 / 日均收入
```

- 数据：`entriesInWindow(controller.entries, window)` → `valuesForTypeInWindow(..., type)`（复用纯函数）。
- 窗口：近 7 日 = `[今天-6, 今天]`；本周 = `weekWindowFor(now)`（周一至周日，未来日为 0）。
- 横轴：本周用「周一…周日」（新增 ARB 键）；近 7 日用「M.D」。
- 日均 = 总额 ÷ 7（固定 7，与一木一致）。
- 图例与文字统计配色走 `veriSemantic`，为 0 用中性色。
- 净额口径（退款冲减支出），与看板其它面板一致。

### 5.5 日常 Tab · 资产汇总面板

```text
SectionTitle(资产汇总, trailing: 锚点菜单「正资产 / 负资产」)
环形图（环内百分比标题）+ 图例（色块 + 账户简称 + 金额 / 占比）
中心: 总额（默认）→ 点击切换为占比
```

- **不引线、不自绘**：用 `fl_chart` `PieChartSectionData.title` / `titleStyle` 画环内百分比（参照官方 `pie_chart_sample2.dart`），账户名与金额放进图例列表。
- 环内文字需要环足够厚；若 `ringWidth ≈ size*0.14`（≈20dp）放不下，则**只保留图例列表**、环内不放文字，实现时以真机观感为准（稳定性优先）。
- 需要给 `VeriDonutChart` 增加：可选的环内标题、可选图例、以及**可点击的中心**（现状中心是 `IgnorePointer`）。
- 数据：`accountBalancesInBase().amountsByAccountId`。
  - 缺率：**不显示部分总额**，卡片内用缺率空态并可跳 `CurrencyRatesPage`。
  - 正 / 负资产：按折算后余额符号分组求和；负资产取绝对值展示。
  - **范围**：排除隐藏账户与「不计入资产」账户（与净资产口径一致）。
- 交互：点分段 = 高亮该账户（其余弱化）；点中心 = 金额 / 占比切换；点中心空区 = 取消选中。
- 不做「过滤占比小于 1%」。

### 5.6 年统计 / 自定义 Tab

- 只渲染 Tab 与 **空内容**；不渲染面板、不渲染面板管理入口、不加任何占位文案或插画。
- 二者不进 `PanelPageKind` 的实际使用（kind 已预留，等有内容时再填 specs）。

### 5.7 图表高度 token（建议顺手做）

设计文档 §7.4 的 `chartHeightInline / Card / Detail / Cover` 至今未落地。本次新增 2 个图表面板，建议**最小化**引入 `chartHeightCard` 与 `chartHeightInline`，新代码用 token，旧代码不动。

## 6. 数据口径（新增部分）

| 面板 | 窗口 | 类型 | 取数 | 备注 |
| --- | --- | --- | --- | --- |
| 近 7 日统计 | `[today-6, today]` | 支出 / 收入 可切 | `valuesForTypeInWindow` | 净额；日均 = 总额 ÷ 7 |
| 近 7 日统计（本周） | `weekWindowFor(now)` | 同上 | 同上 | 未来日为 0 |
| 资产汇总 | 时点快照 | 正 / 负资产 | `accountBalancesInBase().amountsByAccountId` | 缺率不显示部分和；排除隐藏与不计入资产 |
| 月统计摘要卡 | 本月 | 收入 / 支出 / 结余 | 同现状 + 笔数 | 结余 = 收入 − 支出 |

**不改变**既有口径：预算取数仍走 `budgetExpenseTotal` / `countsTowardBudget`；看板原 6 个面板口径不动；预算执行卡仍走预算周期键月。

## 7. 组件复用与新增清单

复用：`VeriCard` / `SectionTitle` / `PageHeader` / `VeriPage` / `SummaryMetric` / `EmptyState` / `VeriSegmentedControl<T>` / `VeriAnchoredChoice<T>` / `FilterPill` / `InteractiveBarChart` / `InteractiveTrendChart` / `VeriBudgetRing` / `entriesInWindow` / `valuesForTypeInWindow` / `weekWindowFor` / `dateMonthDay` / `formatAmount` 族 / `accountBalancesInBase`。

新增或扩展（写完登记 `docs/dev/components.md`）：

| 名称 | 类型 | 位置 | 用途 |
| --- | --- | --- | --- |
| 支出/收入切换共享件（暂名 `VeriEntryTypeToggle`） | Widget | `common_widgets*.dart` | 原统计分析页 `_DimensionToggle` 泛化；近 7 日面板与各 Tab 共用 |
| `VeriDonutChart` 扩展 | Widget 能力 | `chart_painters.dart` | 环内标题、图例、可点中心 |
| 月统计摘要数据卡 | 页面局部 Widget | `reports_page.dart` | 替代 `_MonthSummaryCard` |
| 近 7 日统计卡 | 页面局部 Widget | `reports_page.dart` | 日常 Tab |
| 资产汇总卡 | 页面局部 Widget | `reports_page.dart` | 日常 Tab |

## 8. 持久化与备份兼容

| 数据 | 归属 | 处理 |
| --- | --- | --- |
| 各 Tab 面板开关 / 顺序 | KV + **进备份** | 新增键；旧 `reportPanels` 继续作为月统计来源；旧备份缺新字段按默认（全开）补齐 |
| 看板当前 Tab | **不持久化** | 每次进入都是日常 |

同步更新 `docs/dev/tech-decisions.md` 的「备份数据范围」表。

## 9. i18n 清单（中英同步，zh 为模板）

新增：周期 Tab 文案（日常/月统计/年统计/自定义）、面板名与描述（摘要/近 7 日统计/资产汇总）、近 7 日面板文案（近 7 日、本周、总支出、日均支出、总收入、日均收入）、星期「周X」形态、资产汇总文案（资产汇总、正资产、负资产、资产金额、资产占比）。

删除（阶段 6）：仅统计分析页使用的键（如 `statAnalysisTitle`），确认无其它引用后清理。

**不要**新增「即将推出」类文案（决策见 §1）。

## 10. 测试与验收

- 面板归一化：新增 spec 按声明位置插入、旧清单不被打乱、全关时强制开第一个（含 `home` 回归）。
- 备份往返：只有 `reportPanels` 的旧备份导入后，月统计清单不丢。
- Tab：默认日常、切到空 Tab 无内容且不报错、空 Tab 无面板管理入口。
- 近 7 日面板：窗口边界（今天/跨月/跨年）、支出/收入切换、7 根柱、日均 = 总额 ÷ 7、全 0 空态。
- 资产汇总：正/负切换求和、缺率不显示部分和、中心金额/占比切换、点分段高亮、排除隐藏与不计入资产账户。
- 摘要卡：仅在月统计出现、可开关、可排序、带笔数。
- 布局：393×852 与 360dp、浅/深色、1.3/1.5 倍字号。
- 阶段 6 之后：全仓无 `ReportAnalysisPage` 残留引用；`single_currency_unit_test` 的单位覆盖仍在。

回归：`dart format .`、`flutter analyze`、`flutter test`。真机：Tab 切换流畅度、图表横向滑动不误切根导航、环图观感、深浅色。

## 11. 需同步的文档

> 同步时机：`design-system.md` / `ui-guidelines.md` 属于**永久规范**，在阶段 6 一次性同步，
> 避免把中间态（空 Tab、临时默认「月统计」）写进规范。阶段 1–5 只维护本设计文档
> 与 `tech-decisions.md` 的备份范围表。

- `docs/design-system.md`：看板 Tab、面板编排、资产汇总。
- `docs/ui-guidelines.md`：看板骨架（Tab 位置 + 空 Tab 语义）、图表交互、正/负资产口径、**参照实现去掉 `report_analysis_page.dart`**。
- `docs/dev/components.md`：新增/抽取组件、`VeriDonutChart` 扩展、统计分析页条目改为「页面已移除，纯函数保留」。
- `docs/dev/data-card-and-chart-system-design.md`：§14 进度。
- `docs/dev/tech-decisions.md`：备份范围表（面板字段）。
- `CHANGELOG.md`：用户可见变化（新 Tab、新面板、统计分析页并入看板）。
- `README.md`：功能列表。

## 12. 风险

1. **删除统计分析页的时机**：能力未迁移完就删会丢功能 → 严格按阶段 6 顺序。
2. **面板配置爆炸**：4 个 Tab × 各自清单；靠「年/自定义暂时空」控制。
3. **环图观感**：环内百分比在窄环上放不下 → 退化为「环 + 图例列表」，以稳定性优先。
4. **存量用户观感**：摘要卡从固定区变面板（可被关掉）→ 默认开启 + 至少保留一个面板兜底。
5. **备份兼容**：新增面板字段若不按 §8 处理，老用户升级后清单会被重置。
6. **硬规则**：不得新增自绘数据图表；本次方案不触碰该边界（用库自带能力）。

## 13. 阶段划分与提交（每阶段单独 commit）

| 阶段 | 内容 | 提交信息 |
| --- | --- | --- |
| 1 | `PanelPageKind` 扩展 + 归一化落位 + KV 迁移 + 备份兼容 + 测试（无视觉变化） | `refactor: generalize page panels for multiple report tabs` |
| 2 | 顶部 Tab（默认日常、不持久化）+ 年/自定义空 Tab + 月统计沿用现有内容 | `feat: add report dashboard period tabs` |
| 3 | 摘要卡做成月统计专属数据卡面板 | `refactor: turn the report summary into a monthly panel` |
| 4 | 近 7 日统计面板 + 抽取支出/收入切换共享件 | `feat: add recent daily stats panel` |
| 5 | 资产汇总面板（含 `VeriDonutChart` 环内标题/图例/可点中心） | `feat: add asset summary donut panel` |
| 6 | 统计能力迁入看板后的收尾：删除统计分析页与其两个入口、清理 l10n/测试/文档 | `refactor: fold analytics into the dashboard tabs` |

每阶段：`dart format .` → `flutter analyze` → `flutter test` → `git commit`。不推送、不发版。

> 说明：阶段 6 内部若一次做完风险过大，可按「月统计能力迁移 / 年统计能力迁移 / 自定义能力迁移 / 删除页面」再拆成 4 个提交。

## 14. 已确认 / 实施结果

**实施结果（2026-10-11）**：6 个阶段全部落地并各自提交——`refactor: generalize page panels for multiple report tabs`（面板多 Tab 化 + 归一化落位 + 备份兼容）、`feat: add report dashboard period tabs`（顶部 Tab，默认日常）、`refactor: turn the report summary into a monthly panel`、`feat: add recent daily stats panel`（含共享 `VeriEntryTypeToggle`）、`feat: add asset summary donut panel`（含 `VeriDonutChart` 环内百分比与可点中心）、`refactor: merge the dashboard category and tag cards into one ranking card`、`refactor: fold analytics into the dashboard tabs`（删除页面与入口、清理文案与测试）。年统计 / 自定义仍为空 Tab，待后续单独实现。

已确认（无需再答）：Tab 结构与命名、默认日常且不记忆、年/自定义空 Tab、移除统计分析页及其入口、**摘要卡 = 看板顶部那三个数，保留并重做、作为月视图里的一个面板**、近 7 日两个口径、不联动、不引线改用库自带百分比与图例、资产汇总交互、排除隐藏与不计入资产、不做 <1% 过滤、**删除同比 / 环比**、每阶段提交。

仍待确认（阶段 6 之前给答复即可）：

1. **月统计 Tab 里的三张分类 / 标签卡要不要合并**。现状：月统计已有三张卡——「分类统计」（环形占比图）、「分类明细」（顶级分类 Top6 列表）、「标签统计」（标签 Top8 列表）；而统计分析页迁入的能力是一张带「顶级分类 / 子分类 / 标签」切换 + 点行下钻的排行卡（§3.4）。
   - 选项 A（我的建议）：**三张卡都不动**，只给「分类明细」补上点行下钻（点顶级分类 → 子分类弹层 → 跳筛选后的交易列表），标签行同理。理由：三张卡的拆分经过评审；环形图是占比视角、明细是排行视角，合并后「分类占比」和「标签占比」两种不同分母挤在一张卡里容易误读；下钻是按行补的能力，不依赖合并。
   - 选项 B：把「分类明细 + 标签统计」合并成一张排行卡（带 3 路切换 + 下钻），月统计面板从 6 个变 5 个。
