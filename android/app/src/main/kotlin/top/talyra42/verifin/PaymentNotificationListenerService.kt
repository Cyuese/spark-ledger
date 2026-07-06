package top.talyra42.verifin

import android.app.Notification
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification

/**
 * 自动记账通知监听服务（NLS）。用户在系统「通知使用权」中授权后由系统绑定。
 *
 * 职责仅限：按白名单捕获支付/银行通知原文 → 前置过滤（含数字才算可能是交易）→ 入队，
 * 并把常驻通知切到「识别中」。真正的 AI 解析与落账在 Dart 侧完成（应用打开/回前台时
 * drain 队列）。此服务不做任何自动点击/界面抓取。
 *
 * 注：完全「应用被杀时也在后台自动落账」需后续引入无头 Flutter 引擎 / WorkManager 触发
 * Dart 解析（真机验证项）；当前实现为「后台捕获入队 + 应用回前台时解析落账」。
 */
class PaymentNotificationListenerService : NotificationListenerService() {

    override fun onListenerConnected() {
        super.onListenerConnected()
        if (AutoCaptureBridge.isEnabled(this)) {
            AutoCaptureBridge.showIdle(this)
        }
    }

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        sbn ?: return
        if (!AutoCaptureBridge.isEnabled(this)) return
        val pkg = sbn.packageName ?: return
        if (pkg == packageName) return // 忽略本应用自身（含常驻通知）
        if (!AutoCaptureBridge.isSourceAllowed(this, pkg)) return

        val body = extractText(sbn) ?: return
        if (!containsDigit(body)) return // 前置过滤：不含数字不像交易，不入队、省 Token

        AutoCaptureBridge.enqueue(this, pkg, body, sbn.postTime)
        AutoCaptureBridge.showDetecting(this)
    }

    private fun extractText(sbn: StatusBarNotification): String? {
        val extras = sbn.notification?.extras ?: return null
        val title = extras.getCharSequence(Notification.EXTRA_TITLE)?.toString()?.trim() ?: ""
        val big = extras.getCharSequence(Notification.EXTRA_BIG_TEXT)?.toString()?.trim() ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString()?.trim() ?: ""
        val main = if (big.isNotEmpty()) big else text
        val combined = listOf(title, main).filter { it.isNotEmpty() }.joinToString("\n")
        return combined.ifBlank { null }
    }

    private fun containsDigit(s: String): Boolean = s.any { it.isDigit() }
}
