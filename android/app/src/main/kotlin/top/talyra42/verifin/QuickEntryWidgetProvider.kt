package top.talyra42.verifin

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews

/// 桌面小组件：展示「今日支出」并提供快速记账入口。
/// 数据由 Flutter 侧经 MethodChannel（`updateTodayExpenseWidget`）写入本地 SharedPreferences，
/// 点「记一笔」复用 [MainActivity.ACTION_QUICK_ENTRY]，点主体打开应用。
class QuickEntryWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray,
    ) {
        appWidgetIds.forEach { renderWidget(context, appWidgetManager, it) }
    }

    companion object {
        private const val PREFS_NAME = "verifin_widget"
        private const val KEY_AMOUNT = "today_expense"
        private const val KEY_LABEL = "today_label"

        /// 由 [MainActivity] 调用：保存最新数据并刷新所有已放置的小组件实例。
        fun updateData(context: Context, amount: String, label: String) {
            context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                .edit()
                .putString(KEY_AMOUNT, amount)
                .putString(KEY_LABEL, label)
                .apply()
            val manager = AppWidgetManager.getInstance(context)
            val ids = manager.getAppWidgetIds(
                ComponentName(context, QuickEntryWidgetProvider::class.java),
            )
            ids.forEach { renderWidget(context, manager, it) }
        }

        private fun renderWidget(
            context: Context,
            manager: AppWidgetManager,
            widgetId: Int,
        ) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val amount = prefs.getString(KEY_AMOUNT, "0") ?: "0"
            val label = prefs.getString(KEY_LABEL, "今日支出") ?: "今日支出"

            val views = RemoteViews(context.packageName, R.layout.quick_entry_widget)
            views.setTextViewText(R.id.widget_amount, amount)
            views.setTextViewText(R.id.widget_label, label)

            val flags = PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE

            // 「记一笔」按钮：走快速记账 intent。
            val quickIntent = Intent(context, MainActivity::class.java).apply {
                action = MainActivity.ACTION_QUICK_ENTRY
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            views.setOnClickPendingIntent(
                R.id.widget_add_button,
                PendingIntent.getActivity(context, 1, quickIntent, flags),
            )

            // 主体点击：正常打开应用。
            val openIntent = context.packageManager
                .getLaunchIntentForPackage(context.packageName)
                ?.apply { addFlags(Intent.FLAG_ACTIVITY_NEW_TASK) }
            if (openIntent != null) {
                views.setOnClickPendingIntent(
                    R.id.widget_root,
                    PendingIntent.getActivity(context, 2, openIntent, flags),
                )
            }

            manager.updateAppWidget(widgetId, views)
        }
    }
}
