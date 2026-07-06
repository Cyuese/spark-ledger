package top.talyra42.verifin

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import androidx.core.app.NotificationCompat
import org.json.JSONArray
import org.json.JSONObject

/**
 * 自动记账（NLS 通知）原生侧共享状态：配置、捕获队列、常驻通知。
 *
 * 配置与队列都存本地 SharedPreferences（`verifin_auto_capture`），由 Dart 侧经
 * MethodChannel 写入配置、读取（drain）队列。解析与落账全部发生在 Dart 侧，原生只
 * 负责「按白名单捕获通知原文 + 入队 + 维护常驻通知状态」，保持原生薄、规则可测。
 */
object AutoCaptureBridge {
    private const val PREFS = "verifin_auto_capture"
    private const val KEY_ENABLED = "enabled"
    private const val KEY_LISTEN_ALL = "listenAll"
    private const val KEY_PACKAGES = "packages" // CSV
    private const val KEY_IDLE = "idleText"
    private const val KEY_DETECTING = "detectingText"
    private const val KEY_DONE = "doneText"
    private const val KEY_QUEUE = "queue" // JSON array

    private const val CHANNEL_ID = "verifin_auto_capture"
    const val ONGOING_ID = 4310

    private fun prefs(context: Context) =
        context.getSharedPreferences(PREFS, Context.MODE_PRIVATE)

    // ---- 配置（Dart → 原生）----

    fun writeConfig(
        context: Context,
        enabled: Boolean,
        listenAll: Boolean,
        packagesCsv: String,
        idleText: String,
        detectingText: String,
        doneText: String,
    ) {
        prefs(context).edit()
            .putBoolean(KEY_ENABLED, enabled)
            .putBoolean(KEY_LISTEN_ALL, listenAll)
            .putString(KEY_PACKAGES, packagesCsv)
            .putString(KEY_IDLE, idleText)
            .putString(KEY_DETECTING, detectingText)
            .putString(KEY_DONE, doneText)
            .apply()
        if (enabled) {
            showIdle(context)
        } else {
            cancelOngoing(context)
        }
    }

    fun isEnabled(context: Context): Boolean =
        prefs(context).getBoolean(KEY_ENABLED, false)

    /** 该来源是否在监听范围内（监听全部时恒真；否则匹配白名单 CSV）。 */
    fun isSourceAllowed(context: Context, packageName: String): Boolean {
        val p = prefs(context)
        if (p.getBoolean(KEY_LISTEN_ALL, false)) return true
        val csv = p.getString(KEY_PACKAGES, "") ?: ""
        return csv.split(',').any { it.trim() == packageName }
    }

    private fun text(context: Context, key: String, fallback: String): String {
        val v = prefs(context).getString(key, "") ?: ""
        return if (v.isBlank()) fallback else v
    }

    // ---- 捕获队列（原生入队；Dart drain）----

    fun enqueue(context: Context, packageName: String, body: String, postedAt: Long) {
        val p = prefs(context)
        val arr = try {
            JSONArray(p.getString(KEY_QUEUE, "[]"))
        } catch (_: Exception) {
            JSONArray()
        }
        // 简单去重：同包名 + 同文本 + 60 秒内视为重复。
        for (i in 0 until arr.length()) {
            val o = arr.optJSONObject(i) ?: continue
            if (o.optString("packageName") == packageName &&
                o.optString("text") == body &&
                kotlin.math.abs(o.optLong("postedAt") - postedAt) < 60_000L
            ) {
                return
            }
        }
        arr.put(
            JSONObject()
                .put("packageName", packageName)
                .put("text", body)
                .put("postedAt", postedAt),
        )
        // 上限保护：最多保留最近 50 条，避免长期不打开时无限膨胀。
        while (arr.length() > 50) {
            arr.remove(0)
        }
        p.edit().putString(KEY_QUEUE, arr.toString()).apply()
    }

    /** 取出并清空队列（供 Dart 解析落账）。 */
    fun drain(context: Context): String {
        val p = prefs(context)
        val json = p.getString(KEY_QUEUE, "[]") ?: "[]"
        p.edit().putString(KEY_QUEUE, "[]").apply()
        return json
    }

    // ---- 常驻通知（状态机：等待 / 识别中 / 已记账）----

    fun showIdle(context: Context) {
        post(context, text(context, KEY_IDLE, "等待记账中"))
    }

    fun showDetecting(context: Context) {
        post(context, text(context, KEY_DETECTING, "识别到一笔支付，记录中…"))
    }

    /** 展示「已记账」，可带上金额（替换文案里的 {amount} 占位）。 */
    fun showDone(context: Context, amount: String?) {
        var body = text(context, KEY_DONE, "已完成自动记账")
        if (amount != null) {
            body = body.replace("{amount}", amount)
        }
        post(context, body)
    }

    private fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val manager =
                context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            if (manager.getNotificationChannel(CHANNEL_ID) == null) {
                val channel = NotificationChannel(
                    CHANNEL_ID,
                    "自动记账",
                    NotificationManager.IMPORTANCE_LOW,
                ).apply {
                    description = "自动记账运行状态的常驻通知"
                    setShowBadge(false)
                }
                manager.createNotificationChannel(channel)
            }
        }
    }

    private fun post(context: Context, body: String) {
        if (!isEnabled(context)) return
        ensureChannel(context)
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        val builder = NotificationCompat.Builder(context, CHANNEL_ID)
            .setSmallIcon(R.drawable.ic_quick_entry_tile)
            .setContentTitle("自动记账")
            .setContentText(body)
            .setPriority(NotificationCompat.PRIORITY_LOW)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
        manager.notify(ONGOING_ID, builder.build())
    }

    fun cancelOngoing(context: Context) {
        val manager =
            context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
        manager.cancel(ONGOING_ID)
    }
}
