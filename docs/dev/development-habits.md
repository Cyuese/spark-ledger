# 开发习惯

## 预览方式
本地预览和测试只能在 Android 模拟器或真机上进行；对外交付物是 GitHub CI 构建的 Android APK，用户实际下载该 APK 在手机上验收。

日常开发使用 Android 模拟器或真机预览：

```bash
flutter run -d <android-device-id>
```

需要给用户稳定验收版本时，通过打标签触发 GitHub CI 构建 release APK，让用户下载安装测试。

做 UI 调整后，在 Android 模拟器或真机上检查移动端视口，重点确认首页、资产、看板、我的、交易列表和交易详情是否有白屏、重叠、底部导航异常或元素过大的问题。

## 提交节奏
不要把所有改动混到最后一次提交。每完成一个相对独立的模块就提交一次，例如数据模型、页面结构、样式优化、文档同步分别提交。提交信息保持 `type: summary` 格式，不包含 AI 或 Codex 署名。

## CI 与发布
Android 安装包只通过 GitHub Actions 生成，不在本机作为交付依据。`.github/workflows/flutter.yml` 只监听 `v*.*.*` 标签；普通 `main` 推送不触发 Actions，避免每次提交都创建构建。

需要发布版本时使用脚本：

```bash
scripts/publish.sh patch
```

脚本支持 `patch`、`minor`、`major` 或显式版本号，例如 `scripts/publish.sh 1.1.0`。它会更新 `pubspec.yaml` 和 `lib/app/app_version.dart` 中的 `appVersionLabel`、提交版本号、创建 `vX.Y.Z` 标签并推送。标签触发后，CI 会运行分析、测试、Android release APK 构建，并创建 GitHub Release。APK 文件名使用 `verifin-v1.0.0-短提交号.apk` 形式。发版前仍应确认 README、产品文档、UI 规范和验收清单已经同步。

Release APK 必须使用稳定签名。当前项目使用 `android/app/verifin-release.jks`，不要再使用 CI runner 临时 debug keystore，否则手机会因为签名变化而无法覆盖安装。

## 移动端持久化与权限
账目类核心数据（交易、账户、分组、账本、分类、预算）只存 SQLite，由 `lib/data/` 的 `AppDatabase` + `LedgerRepository`（接口，生产实现 `SqliteLedgerRepository`）承载，`VeriFinController` 内存列表仍是读取源、写入时落库。全新数据库首启动播种默认账本/分类；没有 KV↔SQLite 迁移，也没有 KV 回退。偏好类小数据仍走 `LocalKeyValueStore`（`SharedPreferences`），真实平台不能使用内存版实现，真实 Android 启动必须先 `LocalKeyValueStore.create()` 并 `AppDatabase.open()`。新增账目类数据项时，要同步 schema/仓储读写、导出/导入、初始化和进程重启后读取；新增偏好类数据项仍按 KV 流程覆盖导出/导入与重启读取。修改 `lib/data/` 的表结构须提升 `AppDatabase.schemaVersion` 并在 `_onUpgrade` 写迁移。测试注入 `InMemoryLedgerRepository`（`test/support/`）跑控制器与 widget，真实 SQLite 覆盖在 `test/repository_test.dart` 与 `test/controller_persistence_test.dart`。

平台相关能力必须有 Android 真实实现或明确提示不可用。本地图片选择使用系统图片选择器，JSON 导入使用系统文件选择器，Android JSON 导出默认写入系统 Downloads。新增文件、图片、相册、安装包等能力时，要同步检查 Android Manifest 权限、MediaStore/分区存储和 Android 13+ 行为。data URL 图片预览应使用内存图片渲染，避免 `Image.network`/`NetworkImage` 在真机上黑屏。

测试导入数据放在 `docs/dev/verifin-sample-backup.json`。修改本地数据结构、导入导出字段、资产排序、预算或分类模型后，要同步更新该样例文件，并确保测试能真实导入它。

## 文档同步
每次修改功能、开发流程、数据结构或预览方式，都要同步检查 `README.md`、`AGENTS.md`、`docs/product.md` 和 `docs/dev/`。如果行为或流程变化已经影响用户测试或后续开发，需要在同一次变更里更新文档。
