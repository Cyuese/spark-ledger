/// 全局金额小数位显示偏好（设备本地，不进 JSON 备份、初始化保留）。
///
/// 金额格式化入口 [formatAmount]（及委托它的 `formatExpense/Income/Signed`）是无
/// BuildContext 的纯函数，且在桌面小组件、本地通知、`series_math` 等拿不到 context
/// 的地方也被调用，无法经组件树（`VeriFinScope`）注入偏好，故此处用顶层可变量承载。
///
/// 由 [VeriFinController] 单向同步：启动时从 KV 载入、用户在设置页切换时写入。除此之外
/// 不应有其他写入方，读取方只读不写。
///
/// 为 `true` 时所有金额强制保留两位小数（`12` → `12.00`、`12.5` → `12.50`）；为
/// `false`（默认）时去掉多余的尾随零（`12.00` → `12`、`12.50` → `12.5`）。
bool amountForceTwoDecimals = false;
