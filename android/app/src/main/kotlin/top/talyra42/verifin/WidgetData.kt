package top.talyra42.verifin

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import java.util.Calendar

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

    // ── 跨天/跨月自愈锚点（Flutter 每次推送时写入）──────────────────────
    // 今日支出所对应的日期（yyyy-MM-dd）；若与当前日期不同，说明已跨天，展示归零值。
    const val KEY_TODAY_DATE = "today_date"
    const val KEY_TODAY_ZERO = "today_zero"
    // 本月预算所对应的月份（yyyy-MM）；跨月后展示整月预算（新月尚无支出）。
    const val KEY_BUDGET_MONTH = "month_budget_month"
    const val KEY_BUDGET_FULL = "month_budget_full"
    const val KEY_BUDGET_FULL_LABEL = "month_budget_full_label"

    /// 当前本地日期 yyyy-MM-dd。
    fun currentDate(): String {
        val c = Calendar.getInstance()
        return "%04d-%02d-%02d".format(
            c.get(Calendar.YEAR),
            c.get(Calendar.MONTH) + 1,
            c.get(Calendar.DAY_OF_MONTH),
        )
    }

    /// 当前本地月份 yyyy-MM。
    fun currentMonth(): String {
        val c = Calendar.getInstance()
        return "%04d-%02d".format(c.get(Calendar.YEAR), c.get(Calendar.MONTH) + 1)
    }

    /// 今日支出的展示值：推送日期即当天则用原值，已跨天则用归零值（新的一天尚无支出）。
    fun todayAmountForToday(context: Context): String {
        val stamp = read(context, KEY_TODAY_DATE, "")
        val amount = read(context, KEY_TODAY_AMOUNT, "0")
        if (stamp.isEmpty() || stamp == currentDate()) {
            return amount
        }
        return read(context, KEY_TODAY_ZERO, "0")
    }

    /// 本月可用预算的展示值 / 标签：跨月后回到整月预算与「可用」文案。
    fun budgetForMonth(context: Context): Pair<String, String> {
        val stamp = read(context, KEY_BUDGET_MONTH, "")
        val amount = read(context, KEY_BUDGET_AMOUNT, "0")
        val label = read(context, KEY_BUDGET_LABEL, "本月可用预算")
        if (stamp.isEmpty() || stamp == currentMonth()) {
            return amount to label
        }
        return read(context, KEY_BUDGET_FULL, amount) to
            read(context, KEY_BUDGET_FULL_LABEL, label)
    }

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
