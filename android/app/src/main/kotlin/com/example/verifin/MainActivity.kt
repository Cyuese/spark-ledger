package com.example.verifin

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.Settings
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.io.File
import java.net.HttpURLConnection
import java.net.URL

class MainActivity : FlutterActivity() {
    private var channel: MethodChannel? = null
    private var pendingQuickEntryIntent = false

    override fun onCreate(savedInstanceState: Bundle?) {
        rememberQuickEntryIntent(intent)
        super.onCreate(savedInstanceState)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_NAME)
        channel?.setMethodCallHandler { call, result ->
            when (call.method) {
                "consumeQuickEntryIntent" -> {
                    val shouldOpen = pendingQuickEntryIntent
                    pendingQuickEntryIntent = false
                    result.success(shouldOpen)
                }
                "checkForUpdate" -> checkForUpdate(result)
                else -> result.notImplemented()
            }
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        if (intent.action == ACTION_QUICK_ENTRY) {
            if (channel == null) {
                pendingQuickEntryIntent = true
            } else {
                channel?.invokeMethod("openQuickEntry", null)
            }
        }
    }

    private fun rememberQuickEntryIntent(intent: Intent?) {
        if (intent?.action == ACTION_QUICK_ENTRY) {
            pendingQuickEntryIntent = true
        }
    }

    private fun checkForUpdate(result: MethodChannel.Result) {
        Thread {
            try {
                val response = checkLatestReleaseAndInstall()
                runOnUiThread { result.success(response) }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error(
                        "UPDATE_CHECK_FAILED",
                        error.message ?: "检查更新失败，请稍后再试。",
                        null,
                    )
                }
            }
        }.start()
    }

    private fun checkLatestReleaseAndInstall(): Map<String, Any> {
        val release = fetchLatestRelease()
        val latestTag = release.optString("tag_name")
        val latestVersion = latestTag.removePrefix("v")
        val currentVersion = BuildConfig.VERSION_NAME
        if (latestVersion.isBlank()) {
            return mapOf(
                "status" to "error",
                "message" to "没有读取到最新版本号。",
                "currentVersion" to currentVersion,
                "latestVersion" to latestTag,
            )
        }
        if (!isNewerVersion(latestVersion, currentVersion)) {
            return mapOf(
                "status" to "upToDate",
                "message" to "当前已经是最新版本：v$currentVersion。",
                "currentVersion" to currentVersion,
                "latestVersion" to latestTag,
            )
        }
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O &&
            !packageManager.canRequestPackageInstalls()
        ) {
            startActivity(
                Intent(
                    Settings.ACTION_MANAGE_UNKNOWN_APP_SOURCES,
                    Uri.parse("package:$packageName"),
                ).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK),
            )
            return mapOf(
                "status" to "error",
                "message" to "请先允许 VeriFin 安装未知应用，授权后再次点击检查更新。",
                "currentVersion" to currentVersion,
                "latestVersion" to latestTag,
            )
        }
        val apkUrl = findApkAssetUrl(release)
            ?: return mapOf(
                "status" to "noAsset",
                "message" to "发现 $latestTag，但 Release 中没有可安装的 APK。",
                "currentVersion" to currentVersion,
                "latestVersion" to latestTag,
            )
        val apkFile = downloadApk(apkUrl, latestTag)
        startApkInstall(apkFile)
        return mapOf(
            "status" to "installing",
            "message" to "发现 $latestTag，已下载并打开安装确认。",
            "currentVersion" to currentVersion,
            "latestVersion" to latestTag,
        )
    }

    private fun fetchLatestRelease(): JSONObject {
        val connection = URL(RELEASE_API_URL).openConnection() as HttpURLConnection
        connection.requestMethod = "GET"
        connection.setRequestProperty("Accept", "application/vnd.github+json")
        connection.setRequestProperty("User-Agent", "VeriFin/${BuildConfig.VERSION_NAME}")
        connection.connectTimeout = 15_000
        connection.readTimeout = 15_000
        val code = connection.responseCode
        val stream = if (code in 200..299) connection.inputStream else connection.errorStream
        val body = stream.bufferedReader().use { it.readText() }
        connection.disconnect()
        if (code !in 200..299) {
            throw IllegalStateException("GitHub Release 查询失败：HTTP $code")
        }
        return JSONObject(body)
    }

    private fun findApkAssetUrl(release: JSONObject): String? {
        val assets = release.optJSONArray("assets") ?: return null
        for (index in 0 until assets.length()) {
            val asset = assets.optJSONObject(index) ?: continue
            val name = asset.optString("name")
            val url = asset.optString("browser_download_url")
            if (name.endsWith(".apk", ignoreCase = true) && url.isNotBlank()) {
                return url
            }
        }
        return null
    }

    private fun downloadApk(downloadUrl: String, tag: String): File {
        val updatesDir = File(cacheDir, "updates").apply { mkdirs() }
        updatesDir.listFiles()?.forEach { it.delete() }
        val apkFile = File(updatesDir, "verifin-$tag.apk")
        val connection = URL(downloadUrl).openConnection() as HttpURLConnection
        connection.requestMethod = "GET"
        connection.setRequestProperty("User-Agent", "VeriFin/${BuildConfig.VERSION_NAME}")
        connection.connectTimeout = 15_000
        connection.readTimeout = 60_000
        val code = connection.responseCode
        if (code !in 200..299) {
            connection.disconnect()
            throw IllegalStateException("APK 下载失败：HTTP $code")
        }
        connection.inputStream.use { input ->
            apkFile.outputStream().use { output -> input.copyTo(output) }
        }
        connection.disconnect()
        return apkFile
    }

    private fun startApkInstall(apkFile: File) {
        val uri = FileProvider.getUriForFile(
            this,
            "$packageName.fileprovider",
            apkFile,
        )
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, "application/vnd.android.package-archive")
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        startActivity(intent)
    }

    private fun isNewerVersion(latest: String, current: String): Boolean {
        val latestParts = latest.split(".", "-").map { it.toIntOrNull() ?: 0 }
        val currentParts = current.split(".", "-").map { it.toIntOrNull() ?: 0 }
        val maxSize = maxOf(latestParts.size, currentParts.size, 3)
        for (index in 0 until maxSize) {
            val left = latestParts.getOrElse(index) { 0 }
            val right = currentParts.getOrElse(index) { 0 }
            if (left != right) {
                return left > right
            }
        }
        return false
    }

    companion object {
        const val ACTION_QUICK_ENTRY = "com.example.verifin.action.QUICK_ENTRY"
        private const val CHANNEL_NAME = "verifin/app"
        private const val RELEASE_API_URL =
            "https://api.github.com/repos/LumiDesk/verifin/releases/latest"
    }
}
