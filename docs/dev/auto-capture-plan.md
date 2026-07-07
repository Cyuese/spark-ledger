# 自动记账完整方案（截图识别 + 通知监听 + 无障碍，分阶段）

> 状态：**方案定稿，未开工**。本文档是自动记账的第二轮完整设计，吸收第一轮（NLS 通知监听 + AI 解析，已完整实现后经 `0eb3ba5` revert 撤回，代码仍在 main 历史 `9f1ace8`…`6dca361` 可捡回）的真机失败教训，并补充业界成熟方案调研。
> 本文档为内部技术评估，正文保留中文（不进 ARB）。

## 一、第一轮为什么失败（真机反馈，逐条对应本方案的修法）

| # | 真机问题 | 根因 | 本方案对策 |
|---|----------|------|-----------|
| 1 | App 从最近任务划掉后通知监听就停 | NLS 随应用进程被杀且系统不主动 rebind | 阶段 2：前台服务 + 常驻通知保活 + `requestRebind`/toggle 重绑；同时把**不依赖常驻进程的「截图识别」做成阶段 1 主路线** |
| 2 | 银行「到账」漏识别 | 银行 App 不在默认白名单，用户不知道要手动加 | 阶段 2：默认改为「监听全部通知 + 本地预过滤 + AI 判交易」，白名单降级为可选的排除名单 |
| 3 | 识别偏慢 | 每条通知单独走一次云端 AI | 本地预过滤挡掉绝大多数非交易；批量解析；主推本地模型；截图路线是用户主动触发、可接受等待并有加载态 |
| 4 | 权限敏感、易失效、烦 | 常驻监听天然如此 | 承认这个天花板：**把「用户主动触发的截图识别」作为默认推荐路线**（零敏感权限、永不失效），常驻监听只给愿意折腾的用户 opt-in |

核心结论：第一轮把宝押在「常驻被动监听」上，而这条路的可靠性天花板由系统和 ROM 决定，我们无法根治。第二轮把方案倒过来——**先做可靠性 100% 的半自动截图识别，再把被动监听作为增强层叠加**，每一层独立可用、独立开关。

## 二、业界成熟方案调研

你的直觉（「一般是无障碍 + 识别通知，但不太稳」）与调研结论一致：这确实是主流做法，也确实都不稳，业界的应对是**多通道互补 + 半自动确认**。

| 方案 | 做法 | 借鉴 |
|------|------|------|
| **自动记账（AutoAccounting，开源标杆）** | 多通道采集：Xposed hook 微信/支付宝内部数据（需 Root/LSPatch）、通知、短信、**无障碍/Shizuku 截屏 + OCR 识别任意 App**；OCR 模式支持「翻转手机触发」「页面切换自动触发」；规则引擎初筛 + AI 智能解析补全；作为采集插件对接钱迹/一木等记账 App | 多通道可插拔架构、OCR 截屏路线的触发方式、规则初筛 + AI 兜底的分层解析 |
| **钱迹** | 官方长期拒做自动记账（认为监控屏幕太激进），只提供 **Tasker 意图接口**让用户自建自动化 | 「暴露意图接口给自动化工具」是零维护成本的扩展点（阶段 4） |
| **神奇账本等截图记账 App** | 用户支付后截图（或分享截图给 App）→ OCR 抽金额/商户/时间 → 确认落账 | 隐私友好、零敏感权限、任何 App 都能覆盖——这就是阶段 1 |
| **行业共识** | 全部是「自动抽取 → 用户确认」半自动，没人静默自动落账 | 与我们「绝不自动落账」红线一致（第一轮真机阶段也已改为确认后落账） |

参考来源：
- AutoAccounting 仓库与文档：https://github.com/AutoAccountingOrg/AutoAccounting 、 https://ez-book.org/pages/24b7f5/
- 钱迹为何不做自动记账 / Tasker 接口：https://docs.qianjiapp.com/question_answer.html 、 https://docs.qianjiapp.com/plugin/auto_tasker.html 、 https://sspai.com/post/61292
- OCR 截图记账（神奇账本）：https://zhuanlan.zhihu.com/p/30382584
- ML Kit 端上文字识别（含中文模型）：https://developers.google.com/ml-kit/vision/text-recognition/v2/android
- 无障碍截屏 API（API 30+）：https://developer.android.com/reference/android/accessibilityservice/AccessibilityService.TakeScreenshotCallback
- NLS 被杀与重绑：https://codingtechroom.com/question/-keeping-notificationlistener-service-alive-android 、 https://www.jianshu.com/p/981e7de2c7be

## 三、技术通道全景与取舍

Veri Fin 只经 GitHub Releases 分发、不上架 Google Play，所以「商店审核」不是约束；真正的约束是**可靠性、用户信任、维护成本**。

| 通道 | 覆盖 | 权限/门槛 | 可靠性 | 维护成本 | 结论 |
|------|------|-----------|--------|----------|------|
| 分享/选取截图识别 | 任何 App（含微信） | 无敏感权限 | **100%**（用户主动触发） | 低 | **阶段 1，主路线** |
| NLS 通知监听 | 支付宝、银行、云闪付（通知带金额） | 通知使用权 | 中（保活修复后可用，仍非 100%） | 低（AI 解析免正则维护） | **阶段 2，捡回旧实现修复** |
| 无障碍 + 自动截屏 OCR | 微信支付成功页等（通知不带金额的场景） | 无障碍权限（最重）+ 保活 | 中低（国产 ROM 杀后台） | 高（追各 App 版面） | **阶段 3，opt-in 增强** |
| 短信监听 | 银行卡刷卡/转账短信 | `RECEIVE_SMS`（敏感） | 高 | 低（复用 AI 解析） | 可选通道，架构预留，默认不做 |
| 外部自动化意图接口 | Tasker/MacroDroid 用户自建任意触发 | 无 | 取决于用户配置 | 极低 | **阶段 4，锦上添花** |
| Xposed hook 应用内数据 | 微信/支付宝原始账单 | Root/LSPatch | 高 | 极高 | **不做**（用户群与分发模式不符） |
| MediaProjection 常驻录屏 | 任意 | 每次会话授权，Android 14+ 更严 | 低 | 高 | **不做**（被无障碍 `takeScreenshot` 取代） |
| Shizuku | 截屏/前台应用 | adb 激活，重启失效 | 中 | 中 | **不做**（门槛与收益不匹配） |

## 四、总体架构：可插拔采集通道 + 统一解析管线

所有通道殊途同归，产出统一信号进同一条管线，新增通道只需实现采集端：

```
┌ 采集层（可插拔，各自独立开关）─────────────────────────┐
│ 阶段1: 分享截图 / App内选图·拍照                        │
│ 阶段2: NLS 通知监听（原生捕获 → SharedPreferences 队列） │
│ 阶段3: 无障碍页面事件 → takeScreenshot / 读节点文本      │
│ 阶段4: 外部意图接口（Tasker 等）                        │
│ 预留:  短信                                            │
└──────────────┬─────────────────────────────────────────┘
               ▼
   CapturedSignal { source, kind(text|image), payload,
                    packageName?, timestamp, dedupeKey }
               ▼
┌ 解析层（Dart，全通道共用）────────────────────────────┐
│ 1. 本地预过滤：文本含金额数字/关键词才继续（省 Token）    │
│ 2. kind=image → 本地 OCR（ML Kit 中文模型，离线）→ 文本  │
│    （可选增强：AI 端点支持视觉时直接发图给多模态模型）     │
│ 3. AI 解析：复用 AI 记账管线（isTransaction 过滤噪音 +   │
│    金额/方向/对方/日期抽取 + 分类账户校验到当前账本清单）  │
│ 4. AI 失败兜底：存「待解析」草稿（原文进备注），数据不丢   │
│ 5. 去重：dedupeKey（通知 key+postTime / 图片指纹 /       │
│    包名+金额+时间窗口）                                  │
└──────────────┬─────────────────────────────────────────┘
               ▼
   AiEntryDraft → pending_captures 表（SQLite）＋ 首页角标
               ▼
   用户逐条 EntryDetailPage(initialDraft:) 确认/修改 → 落账
   （绝不自动落账；可一键忽略）
```

设计要点：

- **解析统一走 AI，不写按银行/App 正则**（第一轮已定的关键取舍：正则每家一套、维护无底洞；AI 读原文泛化，还能判「是不是交易」）。可在 AI 前加一层**极轻量的通用初筛**（含数字、含「支付/收款/到账/退款」等词），只为省调用，不做结构化抽取。
- **AI 为硬门槛**：开启任一自动记账通道前须已配置 AI（`AiSettings`），未配置引导先去 AI 设置页；主推本地 Ollama/LM Studio（文本/图片不出设备，契合数据自主定位）。
- **图像解析默认「本地 OCR → 文本 → 现有 AI 文本管线」**，而不是直接发图：① 复用已有管线与提示词；② 文本 Token 远比图片便宜；③ 本地模型多数不带视觉能力，OCR 路线让纯本地部署也能用。AI 设置页可加「视觉模型直读图」开关作为增强（OCR 对复杂账单页效果差时）。
- **每层独立可用**：截图识别不依赖任何监听；NLS 不依赖无障碍；某层被系统杀死只影响该层。设置页按通道分区，各自开关、各自说明覆盖范围与代价。

## 五、分阶段落地

### 阶段 1：截图识别（主路线，先做）

用户支付完成 → 截图（或从任何 App 的账单页截图）→ 进入 Veri Fin 识别 → 确认落账。三个入口：

1. **系统分享**：Manifest 给 MainActivity 加 `ACTION_SEND`（`image/*`）intent-filter，微信/支付宝里长按截图「分享 → Veri Fin」直达识别流程。这是最顺手的入口（支付 → 截图 → 分享，三步不用切 App 找入口）。
2. **App 内选图/拍照**：记一笔入口扩展「截图识账」，复用现有 `attachment_picker_*`（`image_picker`）选相册图或拍照。
3. **快速记账磁贴扩展**（可选）：现有 `ACTION_QUICK_ENTRY` 磁贴旁加「识别最近截图」动作，读相册最新一张截图（需相册权限，Android 13+ 用 `READ_MEDIA_IMAGES` 或 Photo Picker 免权限）。

技术要点：

- OCR 用 `google_mlkit_text_recognition`（中文模型，端上离线，无网络依赖）。这是本阶段唯一新增依赖；模型随包体积增加约 +几 MB~20MB，需在 CHANGELOG/README 注明。若想零依赖起步，v1 可先做「图片直发视觉模型」路线（要求用户端点支持视觉），OCR 后补——但推荐直接上 OCR，覆盖纯本地部署。
- OCR 文本 → 复用 AI 记账的提示词框架，扩一个「账单截图」变体（输入是 OCR 噪声文本，须容忍换行/乱序/页面杂项，输出同样的草稿 JSON + isTransaction）。
- 识别中有明确加载态（第一轮真机反馈过「偏慢没反馈」）；识别结果进 `EntryDetailPage(initialDraft:)` 确认，AI 草稿模式关闭自动识别（现有行为）。
- 分享进来的图**不落库不留存**，识别完即弃；用户勾选「保存为附件」才随交易存 `attachments` 表。
- 条件导入两件套：`screenshot_recognizer_io.dart`（ML Kit）+ stub（测试宿主 `recognitionSupported=false`），与 `attachment_picker_*` 同模式。

验收标准：微信/支付宝/银行 App/云闪付真实账单截图各若干张，识别率达标（金额方向必须准，分类允许用户改）；分享入口在冷启动/已运行/锁屏后各状态可用。

### 阶段 2：捡回 NLS 通知监听，修四个真机问题

代码基础：`git revert 0eb3ba5`（或按文件 cherry-pick `9f1ace8`…`2fb92ef`）捡回 ~2000 行：`lib/app/auto_capture/*`（设置/预过滤/AI 通知解析/协调器/服务）、`AutoCaptureSettingsPage`、原生 `PaymentNotificationListenerService`/`AutoCaptureBridge`、i18n 与测试。捡回后按当前 main 适配（这中间 main 已有大量演进，注意 `ai_entry_parser.dart`、`platform_bridge.dart`、settings 页结构的冲突）。

在旧实现上必须修的四件事：

1. **保活**：NLS 进程被杀后系统经常不重绑。组合拳：① NLS `onListenerConnected` 里 `startForeground` 挂常驻通知（用户可在设置里关，关了就诚实提示存活率下降）；② 开屏/回前台检测 `isNotificationListenerAccessGranted` 且未连接时，用 `requestRebind()` + 组件 disable/enable 触发系统重绑；③ 设置页给「电池优化白名单/自启动」的分 ROM 引导文案。仍不承诺 100%，页内明示。
2. **银行漏识别**：默认从「白名单勾选」改为「**监听全部通知**，本地预过滤 + AI isTransaction 过滤噪音」；白名单反转为「排除名单」（用户嫌某 App 吵再排除）。担心 Token 消耗的用户可切回白名单模式（保留旧 UI，默认值改为全量）。
3. **慢**：预过滤挡非交易（含数字 + 关键词双条件）；回前台批量喂 AI（旧实现已有）；原生侧收到疑似交易时即发「N 笔待记账」轻通知，点击拉起 App 直达确认（缩短「发生 → 看到」的体感延迟）。
4. **被杀期间漏单**：旧实现是「后台入队 + 回前台解析」，进程死了连队都入不了。不追求无头引擎/WorkManager 后台跑 Dart（复杂度高、还是会被杀）；接受漏单，**用阶段 1 截图识别和已有账单导入作为漏单兜底**，设置页写明这个分工。

### 阶段 3：无障碍 + 自动截屏 OCR（opt-in 增强，最后做）

覆盖「通知不带金额」的场景（典型是微信支付）。借鉴 AutoAccounting 的 OCR 模式，但只做最小闭环：

- `AccessibilityService` 配置 `packageNames` 严格限定（微信/支付宝等，用户可调），监听 `TYPE_WINDOW_STATE_CHANGED`/`TYPE_WINDOW_CONTENT_CHANGED`，检测「支付成功」类页面（按 activity 类名/窗口标题粗匹配，匹配规则做成可下发的常量表以便追版面）。
- 命中后优先**读节点文本**（`canRetrieveWindowContent`，轻、无图片处理）；节点拿不到再 `takeScreenshot()`（API 30+；minSdk 23，低版本运行时降级为仅节点文本）→ 走阶段 1 的同一条 OCR→AI 管线。
- **只读不操作**：绝不 `performAction` 点击/输入；这是写进设置页的承诺。
- 保活与阶段 2 共用前台服务与引导；两通道去重（同一笔支付宝支付可能通知+页面各捕获一次，按「包名+金额+时间窗口」合并）。
- 可选补充触发器（AutoAccounting 验证过的交互）：悬浮球手动触发识别当前屏幕、翻转触发。列为 backlog，不进首版。

### 阶段 4：外部自动化意图接口（可选）

学钱迹：暴露一个显式导出的 intent（如 `top.talyra42.verifin.action.CAPTURE_TEXT`，extras 带原始文本），任何自动化工具（Tasker/MacroDroid/Buzzkill）都能把它们抓到的通知/短信/剪贴板文本丢进 Veri Fin 的解析管线。几十行代码，把「怎么触发」的无底洞外包给自动化生态，且给了不愿开任何监听权限的高级用户一条路。注意做输入长度限制与频率限制，进同一条待确认队列。

## 六、数据与持久化

- `pending_captures` 表（SQLite，`AppDatabase.schemaVersion` +1 并写 `_onUpgrade` 迁移）：待确认草稿队列，字段含来源通道、原始文本（截图不存原图，只存 OCR 文本）、解析出的草稿 JSON、时间、去重键。属「未成账目的临时数据」：**不进 JSON/zip 备份**，初始化与删账本时清理。
- 设置 `AutoCaptureSettings` 存 KV（`verifin.auto_capture.v1`，旧实现已有，扩展字段：通道开关按通道分开、排除/白名单模式、常驻通知开关、视觉模型直读开关）。设备本地偏好，**不进备份、初始化保留**（与 AI 设置同策略，须同步 `docs/dev/` 与 README 的偏好范围清单——备份偏好范围用户已定，不得擅自扩大）。
- 原生侧队列沿用旧实现的 SharedPreferences JSON（Flutter 引擎可能没在运行），drain 后清空。

## 七、隐私与合规红线（全部沿用第一轮定案）

- **绝不自动落账**：一切通道只产草稿进待确认队列。
- **默认全关、纯 opt-in、按通道独立开关**；普通用户完全无感。
- **持续被动上送须显著告知**：NLS/无障碍开启后，支付通知/屏幕文本会持续发往用户自配 AI 端点（与手动 AI 记账「主动打字才发」不同），开关处明写；主推本地模型（文本不出设备）；云端按量计费须提示。**截图原图任何情况下不上传**（本地 OCR 后只发文本；「视觉模型直读」开关单独告知会发图）。
- **无障碍只读**：`canRetrieveWindowContent` 读文本 + `takeScreenshot`，绝不自动点击/输入；`packageNames` 严格限定。
- 读微信/支付宝界面属 ToS 灰色地带，页内明示风险由用户自行承担。

## 八、工程注意事项

- 平台差异全部走仓库既有的条件导入两件套模式（io + stub），测试宿主一律 `supported=false`。
- 文案 zh+en 双 ARB，无 context 场景（常驻通知文案）走 `l10nForPreference`。
- 新增依赖仅 `google_mlkit_text_recognition`（阶段 1）；阶段 2/3 纯原生 + 现有插件，不引新库。
- 每阶段独立提交、独立可发版；用户可见改动记 CHANGELOG `[Unreleased]`；架构变化同步 CLAUDE.md/AGENTS.md/README/docs。
- 测试：提示词构造、OCR 文本→草稿映射、预过滤、去重、drain、失败兜底均为纯函数/可注入，进 `test/`；OCR 与原生监听本身依赖真机，走真机验收清单。
- 数据兼容：`pending_captures` 是新增表，对 1.5.0+ 老用户只有 `_onUpgrade` 加表，无既有数据迁移风险。

## 九、真机验收清单（对着第一轮的失败点验）

1. 阶段 1：微信内截图 → 分享 → Veri Fin 冷启动，草稿正确弹出；识别中有加载态；识别失败有兜底草稿。
2. 阶段 2：App 从最近任务划掉后，支付宝支付通知仍被捕获（常驻通知在时）；常驻通知被用户关掉后，回前台能 drain 到期间的通知（若进程存活）或明确提示可能漏单。
3. 阶段 2：任一银行 App 的「到账」通知（不预配白名单）能被识别为收入。
4. 阶段 3：微信支付成功页在小米/华为任一国产 ROM 真机上能触发捕获；同一笔不重复产草稿。
5. 全阶段:未配置 AI 时所有开关不可开且引导清晰；关闭全部通道后无任何后台行为残留。
