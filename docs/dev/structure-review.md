# 代码结构健康评估（阶段 5.6）

> 只评估、未改代码。以下重构候选按你的「只改明确的，其余记录待回来」原则**全部留待你决定**——原因见文末。等你点头我再逐项做。

## 文件体量 Top 10

| 行数 | 文件 | 性质 |
|---|---|---|
| 2897 | `lib/pages/profile_pages.dart` | 装了 6+ 个独立页面 |
| 2145 | `lib/app/veri_fin_controller.dart` | 核心状态（单类，全领域） |
| 2098 | `lib/pages/assets_pages.dart` | 页面 |
| 1720 | `lib/pages/budget_pages.dart` | 页面 |
| 1707 | `lib/app/common_widgets.dart` | 共用组件（27 个类） |
| 1704 | `lib/pages/transactions_pages.dart` | 页面 |
| 1037 | `lib/pages/reports_page.dart` | 页面 |
| 914 | `lib/pages/home_page.dart` | 页面 |
| 878 | `lib/app/models.dart` | 模型 |
| 872 | `lib/pages/app_lock_page.dart` | 页面 |

`veri_fin_controller.dart` 2145 行单类承担全部领域（交易/账户/分组/账本/多级分类/标签/附件/周期/预算/资产排序/面板/主题/资料/隐私/引导/应用锁/备份/提醒 + KV & SQLite 两套持久化）。臃肿但内部按领域分块清晰，纯函数已下沉到文件底部。

## 重构候选（均待你决定）

### A1. 用 `part`/`part of` 物理拆分 controller — 低风险
把持久化块（`_persistX` / `_loadX`，约 270 行）和底部纯 helper（约 140 行）拆成 `part` 文件，主文件降到约 1700 行。同库、私有可见性不变、符号不变、**无需改测试**。
**为何仍留待你定**：本项目当前 `part` 用量为 0，引入这个机制是一个**新约定**，属风格决策，应由你拍板是否采用。

### A2. 抽通用确认弹窗 `showConfirmDialog` — 低风险、改动面中
全仓有 **15 处** `showDialog<bool>` + `AlertDialog`（取消/确定）几乎逐字重复（`profile_pages` 10、`transactions_pages` 2、`assets`/`sheets`/`panel_settings` 各 1）。抽到 `common_widgets.dart`，各点省约 15 行、共约 200 行，并统一破坏性操作样式。
**为何留待你定**：触及 15 个调用点，虽行为可保持一致，但面广，建议你确认后我分批做并逐一核对文案。

### A3. 拆分 `profile_pages.dart`（2897 行装 6 个页面）— 低风险、改动面大
按页面拆到 `category_management_page.dart` / `tag_management_page.dart` / `ledger_books_page.dart` / `data_management_page.dart`（其中 `DataManagementPage` 单类就约 1100 行）。纯文件搬移 + import 调整，不改逻辑，但要同步更新测试 import 路径，改动面广。

### B（中/高风险，建议先讨论，不顺手改）
- 把 controller 领域拆成独立 Repository/Service：需重设计公开接口 + 改所有调用方与测试，违反「不改外部行为/公开 API」，属独立重构立项。
- `importDataJson`（约 180 行）、`reorderAssetAccounts`（约 75 行）超长方法：数据正确性敏感（尤其导入关系备份兼容），可抽 helper 但需配合 `verifin-sample-backup.json` 真实导入测试单独提交。
- `common_widgets.dart`（27 类）按用途再分文件：性质单一、被广泛 import，收益中、优先级低。

### C（仅观察，不动）
- 目录划分总体清晰：`lib/app/` = 逻辑/模型/共用组件/平台适配；`lib/pages/` = 页面；纯函数与页面成对分离得当。
- 底部弹窗分两处（`app/entry_sheets.dart` 记账输入类 vs `pages/sheets.dart` 通用类）：划分说得通，不算放错。
- `setState` 用量偏高（transactions 29、profile 19、app_lock 16）：符合「单 Controller + 局部 StatefulWidget」既定架构，非滥用。
- 空安全良好：getter 一律返回不可变副本，多账本按 `_activeBookId` 过滤。

## 我的建议
如果你想推进，性价比排序：**A1（若你接受引入 part）→ A2 → A3**；B/C 暂不动。每项一个独立提交，改后强制跑 `flutter analyze` + `flutter test`（尤其 A2/A3 跑相关 widget 测试）。
