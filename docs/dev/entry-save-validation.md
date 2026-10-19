# 交易聚合保存与退款金额精度

本文记录交易（含退款、附件）聚合保存的金额精度、校验错误码、日志与用户提示契约，以及部分退款场景下的当前缺陷和验收要求。执行规则以 [AGENTS.md](../../AGENTS.md) 为准；判断当前实现仍以源码、测试、Gradle 和工作流为准。

关联文档：[退款与报销](refund.md)、[多币种与汇率](multi-currency.md)、[技术决策](tech-decisions.md)、[短反馈系统](feedback-system.md)、[统一设计规范](../design/design-system.md)、[组件清单](../design/components.md)。

## 范围

覆盖 `VeriFinController.saveEntryAggregateDraftResult` 的以下链路：

- 原交易、关联退款和附件作为一次聚合草稿提交；
- 保存结果 `EntrySaveResult` 与校验错误码 `EntryValidationCode`；
- 校验失败写入 `AppLogger` 的方式；
- 交易编辑页、交易详情页和信用卡还款页对校验失败的提示；
- 退款草稿的“剩余可退”金额与币种精度。

不涉及：SQLite schema、备份格式、导入解析、退款会计口径本身，以及批量报销/批量退款（见「非目标」）。

## 金额精度契约

### 所有金额必须先按币种归一化

金额在进入比较、校验或持久化前，必须按 ISO 4217 minor unit 归一化：

- 入口：`normalizeCurrencyAmount(value, currencyCode)`（`lib/app/currency_math.dart`）；
- 校验安全网：`validateLedgerEntries(..., requireMinorUnitNormalization: true)` 会把未归一化的金额判为 `LedgerDataValidationCode.invalidAmount`；
- **不得放宽或删除该安全网**。它拦住的是生产者把浮点计算结果直接当金额的问题。

典型错误：

```text
250.89 - (50 + 50 + 51 + 51) = 48.889999999999986
```

`48.889999999999986` 不能直接作为 `LedgerEntry.amount`；它必须变成 `48.89`。

### 剩余可退金额

剩余可退金额的唯一口径：

```text
remaining = clamp(expense.amount - Σ(该支出下所有退款.amount), 0, expense.amount)
remaining = normalizeCurrencyAmount(remaining, expense.currencyCode)
```

约定：

- **计入待到账退款**：待到账退款已经占用可退额度，不能因为尚未到账就重复退；
- 编辑某笔已有退款时，计算上限要排除该笔自身；
- 结果按原支出币种归一化，再用于显示、数字键盘上限和草稿金额；
- 这个计算不允许在 UI 和 Controller 各写一份，统一使用纯函数 `remainingRefundableAmount`（实现要求见下文）。

### 三层金额

退款和支出的三层金额各自归一化：

- `amount` 按 `entry.currencyCode`；
- `accountAmount` 按到账账户币种；
- `baseAmount` 按账本本位币。

`refundedBaseAmount` 是原支出的派生缓存，只由已到账退款的 `baseAmount` 之和重算；保存草稿时不得信任调用方传入的旧缓存。该语义仍以 [refund.md](refund.md) 和 `_entriesWithSyncedRefundCache` 为准。

## 保存结果与校验错误码

`EntrySaveResult` 是 sealed class：

- `EntrySaveSuccess`：保存成功；
- `EntrySaveValidationFailure(code)`：校验失败，未写库；
- `EntrySavePersistenceFailure`：校验通过但 SQLite 写入失败。

`EntryValidationCode` 当前有 8 个值。UI 不应把枚举名直接展示给用户；应按“是否可操作”决定提示策略：

| code | 含义 | 用户可操作 | 提示策略 |
|---|---|---|---|
| `staleDraft` | 草稿已过期、交易已被删除或账本不一致 | 是 | 提示返回后重新打开 |
| `invalidAmounts` | 金额、币种或账户金额等聚合金额不合法 | 部分 | 保留通用兜底提示；优先在表单内提前拦截 |
| `invalidRefund` | 退款结构、账本、币种或引用不合法 | 是 | 提示检查退款金额和到账账户 |
| `refundExceedsExpense` | 退款总额超过原支出金额 | 是 | 提示不能超过原支出金额 |
| `invalidAttachments` | 附件 `entryId` 与交易不一致 | 是 | 提示重新添加附件 |
| `invalidRememberedRate` | 记住汇率的币种、数值或生效日不合法 | 是 | 提示检查汇率或取消记住汇率 |
| `categoryOutOfScope` | 引用了不属于该账本的分类 | 否 | 通用提示 + 日志 |
| `tagOutOfScope` | 引用了不属于该账本的标签 | 否 | 通用提示 + 日志 |

注意：`invalidAmounts` 是聚合后的兜底分类，底层可能是 `LedgerDataValidationCode.invalidAmount`、`invalidEntryShape` 或 `missingAccount`。日志应保留底层 code；用户提示不需要暴露这些内部术语。

## 日志契约

### 目标

校验失败时，用户可以通过「我的 → 数据与工具 → 软件日志」导出可诊断的日志；日志不能包含账目敏感信息。

### 格式

统一由 Controller 内的一个私有 helper 记录，不在每个 early return 复制日志代码：

```text
Entry save validation failed: <EntryValidationCode>[ (ledger: <LedgerDataValidationCode>)]
```

- level：`warning`；
- source：`entry_save`；
- 聚合校验失败时附带底层 `LedgerDataValidationCode`；
- 只记录错误码，不记录金额、备注、分类/账户/标签名称或 id、交易 id、附件 id；
- 成功保存不记录日志；不在字段编辑、每次击键或每次重建时记录。

### 实现约束

- helper 返回 `EntrySaveValidationFailure`，所有 early return 统一经它返回；
- `applyImportEntries` 已有 `Import validation failed: <code>` 的先例，交易保存沿用同一风格；
- 日志写入是设备本地行为，不进入备份；
- 200 条环形缓冲会自然淘汰旧日志；如后续发现重复重试造成噪声，再按 code 做短时间去重，当前不引入额外队列。

## 用户提示契约

### 先做字段级校验

能在表单内确定的错误，应在保存前拦截并显示在对应字段附近，不要等到 Controller 返回通用提示：

- 金额为空、为零或不是合法币种精度；
- 退款金额超过剩余可退；
- 转账缺少转入账户；
- 已选币种缺少必要汇率；
- 附件引用异常。

保存按钮的禁用态和字段提示沿用现有页面骨架与 `docs/design/ui-guidelines.md`，不新增自定义 Toast。

### 通用兜底与精确提示

- 三个调用点共用同一个映射 helper：
  - `EntryDetailPage`（快速记账）；
  - `TransactionDetailPage`（交易详情/退款聚合）；
  - `CreditRepaymentPage`（信用卡还款）。
- 对可操作 code 使用具体文案；`invalidAmounts` 和内部 scope code 保留现有 `entrySaveValidationFailed` 兜底；
- 新增文案同时写入 `lib/l10n/app_zh.arb` 与 `app_en.arb`，不手改生成文件；
- 提示仍使用根级 `VeriFeedbackHost`、`VeriFeedbackTone.warning`，不新增旧式 Material 横条或 Toast；
- 持久化失败（`EntrySavePersistenceFailure`）继续由 `onPersistError` 统一记录和反馈，提示“保存失败”并保留草稿，不并入校验提示。

映射 helper 放在 UI 层（例如 `lib/app/entry_save_feedback.dart`），不要把 `AppLocalizations` 依赖塞进 Controller。

## 当前缺陷：部分退款后默认金额无法保存

### 复现

一笔金额 `250.89` 的支出已有 4 笔已到账退款，合计 `202.00`：

1. 打开交易详情；
2. 点「添加退款」，不修改默认金额；
3. 保存退款弹层；
4. 保存交易详情。

结果：交易详情保存失败，界面显示通用提示“交易金额、币种或关联数据不完整，请检查后重试。”，退款没有落库。

用 Issue 39 附件数据在当前实现上可复现三笔支出，剩余金额分别是：

- `10.3 - 5.0 = 5.300000000000001`
- `84.99 - 30.9 = 54.089999999999996`
- `250.89 - 202.0 = 48.889999999999986`

### 根因

```text
_RefundSheetState._maxRefund 返回未归一化的浮点减法结果
  → 新建退款时 _amount 直接取 _maxRefund
  → _buildRefund 的 amount 只做 clamp，没有 normalize
  → baseAmount / accountAmount 已 normalize，只有 amount 带尾差
  → validateLedgerEntries(requireMinorUnitNormalization: true) 判 invalidAmount
  → saveEntryAggregateDraftResult 映射成 EntryValidationCode.invalidAmounts
  → 页面只显示通用 entrySaveValidationFailed
```

相关符号：

- `RefundSection._remaining`、`_RefundSheetState._maxRefund`、`_buildRefund`（`lib/pages/refund_editor.dart`）；
- `VeriFinController.remainingRefundable`、`updateRefund`（`lib/app/veri_fin_controller_ops.dart`）；
- `validateLedgerEntries` 的 minor-unit 校验（`lib/app/ledger_data_validation.dart`）；
- `saveEntryAggregateDraftResult` 的聚合校验映射（`lib/app/veri_fin_controller_ops.dart`）。

### 为什么现有测试没发现

现有“添加退款”测试使用 `200 - 50 = 150` 这类整数，不产生浮点尾差；没有覆盖“已有部分退款 + 非整数剩余金额”的组合。

### 临时绕过

手动点开退款金额，输入两位小数的剩余值（如 `48.89`）再保存；金额输入路径会归一化。该绕过只用于确认根因，不是修复方案。

## 统一口径与实现约束

### 1. 共享剩余可退金额纯函数

在 `lib/app/ledger_math.dart` 增加纯函数（若实现时该文件继续膨胀，再拆到 `refund_math.dart`，不得复制逻辑）：

```dart
double remainingRefundableAmount(
  LedgerEntry expense,
  Iterable<LedgerEntry> entries, {
  String? excludeRefundId,
});
```

行为：

- 只统计 `type == EntryType.refund`、`refundOf == expense.id`、`id != excludeRefundId` 的条目；
- 包含待到账退款；
- 先 clamp 到 `[0, expense.amount]`，再按 `expense.currencyCode` 归一化；
- `expense` 不是支出时返回 0；
- 由 `test/` 中的纯函数测试覆盖小数、待退款、排除自身、超额和零剩余。

调用点统一改为该函数：

- `RefundSection._remaining`；
- `_RefundSheetState._maxRefund`；
- `_RefundSheetState._buildRefund` 的 `amount`（归一化后再 clamp）；
- `VeriFinController.remainingRefundable`；
- `addRefund` 的上限计算；
- `updateRefund` 的上限计算（排除自身）。

### 2. Controller 防御

- UI 负责生成归一化草稿；Controller 不静默改写用户明确输入的不同金额；
- 保存前的 `validateLedgerEntries(requireMinorUnitNormalization: true)` 保持启用；
- 如后续出现其它生产者，优先修生产者，不靠 Controller 猜测并四舍五入；
- 保存失败时保持草稿和 dirty 状态，由页面继续处理；不要先退出再提示。

### 3. 校验失败日志

- 增加私有 helper，统一记录 outer code 和底层 ledger code；
- 替换 `saveEntryAggregateDraftResult` 中所有 early return；
- 补 `AppLogger` 测试：level、source、message、无敏感内容；
- 不改变 `EntrySaveResult` 的公开语义。

### 4. 用户提示

- 先补字段级校验；
- 增加可操作 code 的本地化映射和三个页面共用的 helper；
- 保留 `entrySaveValidationFailed` 作为兜底；
- 补中英文 ARB 和至少一个 widget 测试。

## 验收与测试

### 行为验收

- [ ] 已有部分退款的支出，使用默认剩余金额新增退款并保存成功；
- [ ] 默认金额显示、数字键盘上限和实际落库金额三者一致（按币种精度）；
- [ ] 手动输入合法的较小金额仍按用户输入保存；
- [ ] 退款总额超过原支出时被拦截，提示具体原因；
- [ ] 待到账退款计入剩余可退，不会重复退；
- [ ] 已有退款编辑时排除自身，不会把自己的旧值重复扣减；
- [ ] 保存成功后 `refundedBaseAmount` 等于已到账退款 `baseAmount` 之和；
- [ ] 冷启动/重载后金额和退款关系一致；
- [ ] SQLite 写入失败时停留在原页、保留草稿、记录日志并提示；
- [ ] 校验失败日志只含 code，不含金额、备注、名称或 id；
- [ ] 可操作 code 显示具体提示，通用 code 仍显示兜底提示；
- [ ] 全屏编辑页的返回/未保存拦截行为不变。

### 测试矩阵

| 层级 | 用例 |
|---|---|
| 纯函数 | `remainingRefundableAmount`：小数尾差、待退款、排除自身、超额 clamp、零剩余、非支出 |
| Controller | 部分退款后新增默认退款成功；缓存重算；跨账本/悬空分类/标签仍被拒绝；持久化失败保持内存 |
| Widget | 交易详情添加默认退款后保存；交易编辑页保存；信用卡还款页失败提示；已全额退款时按钮禁用 |
| SQLite/ffi | 聚合保存后重载，退款金额与 `refundedBaseAmount` 一致 |
| 日志 | 注入 `AppLogger`，断言 `warning`/`entry_save`/code，且不含敏感文本 |
| 布局 | 393×852、360dp、大字号下退款弹层和提示不溢出 |

### 门禁

提交前运行：

```bash
dart format .
flutter analyze
flutter test
```

只改文档时至少执行 `git diff --check`、检查相对链接和路径。

Android 真机/模拟器手动验收：用 `diagnostic` flavor 在 `emulator-5554` 上复现“已有部分退款 + 默认剩余金额”路径；不要并行执行 `input`。发布包验收仍以 CI 生成的 GitHub release APK 为准。

## 非目标

- **不实现批量报销/批量退款**。当前产品边界是逐笔在交易详情处理；后续如重新评估，另立功能 issue，不在本契约中预留半成品入口。
- 不改变退款会计口径（待到账/已到账、cash basis、`refundedBaseAmount` 派生缓存）。
- 不修改 SQLite schema、备份格式、导入解析或 AI 工具。
- 不为“提示更具体”而把内部校验码暴露到 UI，或放宽 `validateLedgerEntries`。

## 相关文档

- [退款与报销](refund.md)：退款模型、金额口径、界面和验收。
- [多币种与汇率](multi-currency.md)：三层金额、跨币种退款和缺率处理。
- [技术决策](tech-decisions.md)：退款模型、聚合保存和金额精度取舍。
- [短反馈系统](feedback-system.md)：校验失败的提示入口、级别和时长。
- [统一设计规范](../design/design-system.md) / [UI 规范](../design/ui-guidelines.md)：页面骨架、表单校验和反馈样式。
