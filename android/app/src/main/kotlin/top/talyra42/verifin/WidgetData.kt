package top.talyra42.verifin

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent

/// 桌面小组件的共享数据与刷新工具。
///
/// 三个小组件（今日支出 / 本月预算 / 资产总额）都从同一份 SharedPreferences 读取各自
/// 的字段；Flutter 侧经 MethodChannel `updateWidgetData` 一次写入全部字段（见
/// [MainActivity]），随后广播刷新各 Provider。字段值均为已格式化好的字符串。
object WidgetData {
    const val PREFS_NAME = "verifin_widget"

    // 今日支出小组件（沿用旧键名，避免历史数据失效）。
    const val KEY_TODAY_AMOUNT = "today_expense"
    const val KEY_TODAY_LABEL = "today_label"

    // 本月预算小组件（展示本月可用/超支金额）。
    const val KEY_BUDGET_AMOUNT = "month_budget"
    const val KEY_BUDGET_LABEL = "month_budget_label"

    // 资产总额小组件。
    const val KEY_NET_WORTH_AMOUNT = "net_worth"
    const val KEY_NET_WORTH_LABEL = "net_worth_label"

    /// 批量写入字段（只写传入的键，缺省键保持原值）。
    fun write(context: Context, values: Map<String, String>) {
        val editor = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
        values.forEach { (key, value) -> editor.putString(key, value) }
        editor.apply()
    }

    fun read(context: Context, key: String, fallback: String): String {
        return context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            .getString(key, fallback) ?: fallback
    }

    /// 广播 APPWIDGET_UPDATE，触发指定 Provider 已放置实例的 onUpdate 重绘。
    fun refresh(context: Context, provider: Class<out android.appwidget.AppWidgetProvider>) {
        val manager = AppWidgetManager.getInstance(context)
        val ids = manager.getAppWidgetIds(ComponentName(context, provider))
        if (ids.isEmpty()) {
            return
        }
        val intent = Intent(context, provider).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        }
        context.sendBroadcast(intent)
    }
}
