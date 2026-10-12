package top.talyra42.verifin

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Paint
import android.graphics.Path
import android.net.Uri
import android.os.Build
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.*
import androidx.glance.action.Action
import androidx.glance.action.clickable
import androidx.glance.appwidget.*
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.layout.*
import androidx.glance.text.*
import androidx.glance.unit.ColorProvider
import es.antonborri.home_widget.*
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * 投影快照的结构版本。**必须与 Dart 侧的 `widgetSnapshotVersion` 成对修改**，
 * 否则升级后原生会把旧形状当成「没有数据」，直到用户重新打开应用推送一次。
 * 由 `test/widget_catalog_test.dart` 强制一致。
 */
const val SNAPSHOT_VERSION = 2

/**
 * 四个固定模板。模板与指标是 1:1 的：每个模板恰好展示一个指标，因此原生侧
 * **没有指标词表**——[labelRes] 就是该模板正文的指标行文案，其余文字（金额、
 * 曲线数据）全部由 Flutter 侧投影下发。
 *
 * Provider 身份必须跨升级稳定：Glance 用类本身解析 receiver 与 session，所以每个
 * 模板各有一个 Provider 类。
 */
enum class VeriFinWidgetTemplate(val key: String, val labelRes: Int) {
    QUICK_ENTRY("quick_entry", R.string.widget_today_expense),
    BUDGET("budget", R.string.widget_budget_remaining),
    TREND("trend", R.string.widget_trend_period_expense),
    NET_WORTH("net_worth", R.string.widget_net_worth);

    companion object {
        fun fromKey(key: String): VeriFinWidgetTemplate =
            entries.firstOrNull { it.key == key } ?: error("Unknown widget template")

        fun fromProvider(provider: String) = when (provider.substringAfterLast('.')) {
            "QuickEntryWidgetProvider" -> QUICK_ENTRY
            "BudgetWidgetProvider" -> BUDGET
            "NetWorthWidgetProvider" -> NET_WORTH
            "TrendWidgetProvider" -> TREND
            else -> error("Unknown widget provider")
        }

        /** 模板对应的 Provider 类（选择器条目与桌面实例计数都按它查询）。 */
        fun providerClass(template: VeriFinWidgetTemplate): Class<*> = when (template) {
            QUICK_ENTRY -> QuickEntryWidgetProvider::class.java
            BUDGET -> BudgetWidgetProvider::class.java
            NET_WORTH -> NetWorthWidgetProvider::class.java
            TREND -> TrendWidgetProvider::class.java
        }

        /**
         * 桌面上各模板的实例数。Flutter 侧据此跳过「一个实例都没有」时的投影刷新与排程，
         * 避免用户没放组件也要算账、发广播、排闹钟。
         */
        fun instanceCounts(context: Context): Map<String, Int> {
            val manager = AppWidgetManager.getInstance(context)
            return entries.associate { template ->
                template.key to manager.getAppWidgetIds(
                    ComponentName(context, providerClass(template)),
                ).size
            }
        }
    }
}

/** 实例外观。默认跟随系统，用户可在配置页覆盖。 */
enum class WidgetAppearance(val key: String) {
    SYSTEM("system"),
    LIGHT("light"),
    DARK("dark");

    companion object {
        fun fromKey(key: String?): WidgetAppearance =
            entries.firstOrNull { it.key == key } ?: SYSTEM
    }
}

/** 一个桌面实例的设备本地配置：账本必选，外观可选。 */
data class WidgetInstanceSelection(
    val bookId: String = "",
    val appearance: WidgetAppearance = WidgetAppearance.SYSTEM,
)

/** 组件当前该渲染什么。 */
enum class WidgetContentState {
    /** 还没配置（或配置里的账本已不存在）：只显示一行「点击进入配置」。 */
    NEEDS_SETUP,

    /** 已配置但还没拿到该账本的数据：提示打开应用同步。 */
    NEEDS_SYNC,

    /** 正常渲染指标。 */
    READY,
}

data class WidgetDisplay(
    val state: WidgetContentState,
    val label: String,
    val amount: String = "",
    val points: List<Float> = emptyList(),
    val usage: Float? = null,
    val dark: Boolean = false,
    val bookId: String = "",
)

object VeriFinWidgetStore {
    const val CONFIG_PREFIX = "verifin.widget.config."

    fun prefs(context: Context): SharedPreferences = HomeWidgetPlugin.getData(context)

    /** 读取某个实例的配置；未配置或不可解析时返回空选择（账本为空 = 未配置）。 */
    fun config(prefs: SharedPreferences, id: Int): WidgetInstanceSelection {
        val raw = prefs.getString("$CONFIG_PREFIX$id", null) ?: return WidgetInstanceSelection()
        return try {
            val json = JSONObject(raw)
            val bookId = json.optString("bookId")
            if (bookId.isBlank()) {
                WidgetInstanceSelection()
            } else {
                WidgetInstanceSelection(bookId, WidgetAppearance.fromKey(json.optString("appearance")))
            }
        } catch (error: Exception) {
            android.util.Log.w("VeriFinWidgets", "Invalid instance configuration", error)
            WidgetInstanceSelection()
        }
    }

    /** 桌面上显示的文字跟随**应用语言**（用户可能在系统语言之外单独切换应用语言）。 */
    fun localized(context: Context, prefs: SharedPreferences): Context {
        val language = prefs.getString("verifin.widget.locale", "").orEmpty()
        if (language.isBlank()) return context
        return context.createConfigurationContext(
            Configuration(context.resources.configuration).apply {
                setLocale(Locale.forLanguageTag(language))
            },
        )
    }

    /**
     * 把「实例配置 + 投影快照」解析成可渲染的数据。
     *
     * [sample] 是选择器 / 生成预览用的样例态：只给零值，绝不读用户账目。
     */
    fun display(
        context: Context,
        template: VeriFinWidgetTemplate,
        selection: WidgetInstanceSelection,
        sample: Boolean = false,
        now: Date = Date(),
        prefs: SharedPreferences = prefs(context),
    ): WidgetDisplay {
        val localized = localized(context, prefs)
        val dark = when (selection.appearance) {
            WidgetAppearance.LIGHT -> false
            WidgetAppearance.DARK -> true
            WidgetAppearance.SYSTEM ->
                context.resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK ==
                    Configuration.UI_MODE_NIGHT_YES
        }
        val label = localized.getString(template.labelRes)
        if (sample) {
            return WidgetDisplay(
                state = WidgetContentState.READY,
                label = label,
                amount = "0",
                points = List(30) { 0f },
                usage = if (template == VeriFinWidgetTemplate.BUDGET) 0f else null,
                dark = dark,
            )
        }
        if (selection.bookId.isBlank()) {
            return WidgetDisplay(
                state = WidgetContentState.NEEDS_SETUP,
                label = localized.getString(R.string.widget_setup_required),
                dark = dark,
            )
        }
        val root = readSnapshots(prefs)
        val snapshot = if (root?.optInt("version", 0) == SNAPSHOT_VERSION) {
            root.optJSONObject(selection.bookId)
        } else {
            null
        }
        if (snapshot == null) {
            return WidgetDisplay(
                state = WidgetContentState.NEEDS_SYNC,
                label = localized.getString(R.string.widget_data_unavailable),
                dark = dark,
                bookId = selection.bookId,
            )
        }
        val item = snapshot.optJSONObject(template.key)
        // 「今日支出」跨天后直接归零：桌面不必等用户打开应用。
        val expiredToday = template == VeriFinWidgetTemplate.QUICK_ENTRY &&
            snapshot.optString("date") != SimpleDateFormat("yyyy-MM-dd", Locale.US).format(now)
        val amount = when {
            expiredToday -> "0"
            else -> item?.optString("amount").orEmpty().ifBlank { "—" }
        }
        val pointsJson = item?.optJSONArray("points")
        val points = if (pointsJson == null) {
            emptyList()
        } else {
            (0 until pointsJson.length())
                .map { pointsJson.optDouble(it, Double.NaN).toFloat() }
                .let { values -> if (values.all { it.isFinite() }) values else emptyList() }
        }
        val usage = item?.optDouble("usage", Double.NaN)?.toFloat()?.takeIf { it.isFinite() }
        return WidgetDisplay(
            state = WidgetContentState.READY,
            label = label,
            amount = amount,
            points = points,
            usage = usage,
            dark = dark,
            bookId = selection.bookId,
        )
    }

    private fun readSnapshots(prefs: SharedPreferences): JSONObject? = try {
        JSONObject(prefs.getString("verifin.widget.snapshots", "{}").orEmpty())
    } catch (error: Exception) {
        android.util.Log.w("VeriFinWidgets", "Invalid widget projection", error)
        null
    }
}

// Native counterparts of app_theme.dart tokens; shared by all Glance surfaces.
private val widgetRoyal = Color(0xFF346EDB)
private val widgetTextLight = Color(0xFF111827)
private val widgetTextDark = Color(0xFFF5F5F7)
private val widgetMutedLight = Color(0xFF6B7280)
private val widgetMutedDark = Color(0xFFB8C0CC)

/** Same composition for the launcher, generated preview and in-app draft preview. */
@Composable
fun VeriFinWidgetContent(
    template: VeriFinWidgetTemplate,
    data: WidgetDisplay,
    open: Action? = null,
    add: Action? = null,
    setup: Action? = null,
    widgetId: Int? = null,
) {
    val foreground = if (data.dark) widgetTextDark else widgetTextLight
    val muted = if (data.dark) widgetMutedDark else widgetMutedLight
    val size = LocalSize.current
    val small = size.width < 150.dp || size.height < 130.dp
    val metricSize =
        if (template == VeriFinWidgetTemplate.QUICK_ENTRY) 24
        else if (small || data.amount.length > 12) 20
        else 28
    val surface = if (data.dark) R.drawable.widget_surface_dark else R.drawable.widget_surface_light
    var card = GlanceModifier.fillMaxWidth().background(ImageProvider(surface))
        .cornerRadius(16.dp).appWidgetBackground()
    card = if (template == VeriFinWidgetTemplate.QUICK_ENTRY) card.height(72.dp)
    else card.fillMaxHeight()
    val action = when (data.state) {
        WidgetContentState.NEEDS_SETUP -> setup
        else -> open
    }
    if (action != null) card = card.clickable(action)
    Box(GlanceModifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        if (data.state != WidgetContentState.READY) {
            // 未配置 / 无数据：只显示一句话，不给任何金额，也不猜一个默认账本。
            Column(card.padding(if (small) 10.dp else 14.dp), verticalAlignment = Alignment.CenterVertically) {
                Text(
                    data.label,
                    style = TextStyle(color = ColorProvider(foreground), fontSize = 14.sp),
                    maxLines = 2,
                )
            }
        } else if (template == VeriFinWidgetTemplate.QUICK_ENTRY) {
            AndroidRemoteViews(
                QuickWidgetContent.views(LocalContext.current, data, widgetId),
                GlanceModifier.fillMaxWidth().height(72.dp),
            )
        } else {
            Column(card.padding(if (small) 10.dp else 14.dp)) {
                Text(
                    data.label,
                    style = TextStyle(color = ColorProvider(muted), fontSize = 12.sp),
                    maxLines = 1,
                )
                if (template == VeriFinWidgetTemplate.TREND) {
                    Spacer(GlanceModifier.height(8.dp))
                    Row(
                        GlanceModifier.fillMaxWidth().defaultWeight(),
                        verticalAlignment = Alignment.Bottom,
                    ) {
                        Column(GlanceModifier.defaultWeight()) {
                            MetricText(data, foreground, metricSize)
                        }
                        if (data.points.size >= 2) {
                            Spacer(GlanceModifier.width(16.dp))
                            Image(
                                ImageProvider(WidgetGraphics.sparkline(data.points)),
                                null,
                                GlanceModifier.defaultWeight().fillMaxHeight(),
                                contentScale = ContentScale.FillBounds,
                            )
                        }
                    }
                } else {
                    Column(
                        GlanceModifier.fillMaxWidth().defaultWeight(),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        MetricText(data, foreground, metricSize)
                    }
                    if (template == VeriFinWidgetTemplate.BUDGET && data.usage != null) {
                        Box(
                            GlanceModifier.fillMaxWidth().height(if (small) 48.dp else 64.dp),
                            contentAlignment = Alignment.CenterEnd,
                        ) {
                            Image(
                                ImageProvider(WidgetGraphics.ring(data.usage, data.dark)),
                                null,
                                GlanceModifier.size(if (small) 48.dp else 64.dp),
                            )
                        }
                    }
                    if (template == VeriFinWidgetTemplate.NET_WORTH && data.points.size >= 2) {
                        Image(
                            ImageProvider(WidgetGraphics.sparkline(data.points)),
                            null,
                            GlanceModifier.fillMaxWidth().height(44.dp),
                            contentScale = ContentScale.FillBounds,
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun MetricText(data: WidgetDisplay, foreground: Color, size: Int) {
    Spacer(GlanceModifier.height(4.dp))
    Text(
        data.amount,
        style = TextStyle(
            color = ColorProvider(foreground),
            fontSize = size.sp,
            fontWeight = FontWeight.Bold,
        ),
        maxLines = 1,
    )
}

/** Glance has no arbitrary chart canvas: charts are bitmap leaves, never a second UI. */
object WidgetGraphics {
    fun ring(usage: Float, dark: Boolean): Bitmap {
        val bitmap = Bitmap.createBitmap(192, 192, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            style = Paint.Style.STROKE
            strokeWidth = 16f
            strokeCap = Paint.Cap.ROUND
            color = if (dark) 0xFF30353D.toInt() else 0xFFE5E7EB.toInt()
        }
        canvas.drawCircle(96f, 96f, 78f, paint)
        paint.color = 0xFF346EDB.toInt()
        canvas.drawArc(18f, 18f, 174f, 174f, -90f, usage.coerceIn(0f, 1f) * 360f, false, paint)
        paint.style = Paint.Style.FILL
        paint.color = if (dark) android.graphics.Color.WHITE else 0xFF111827.toInt()
        paint.textSize = 46f
        paint.textAlign = Paint.Align.CENTER
        paint.typeface = android.graphics.Typeface.DEFAULT_BOLD
        canvas.drawText(
            "${(usage.coerceIn(0f, 1f) * 100).toInt()}%",
            96f,
            96f - (paint.ascent() + paint.descent()) / 2,
            paint,
        )
        return bitmap
    }

    fun sparkline(points: List<Float>): Bitmap {
        val bitmap = Bitmap.createBitmap(720, 240, Bitmap.Config.ARGB_8888)
        val canvas = Canvas(bitmap)
        var low = points.minOrNull() ?: 0f
        var high = points.maxOrNull() ?: 1f
        if (high - low < .0001f) {
            low -= 1
            high += 1
        }
        val line = Path()
        points.forEachIndexed { i, value ->
            val x = i * 719f / (points.size - 1).coerceAtLeast(1)
            val y = 232f - (value - low) / (high - low) * 224f
            if (i == 0) line.moveTo(x, y) else line.lineTo(x, y)
        }
        val paint = Paint(Paint.ANTI_ALIAS_FLAG).apply {
            color = 0x20346EDB
            style = Paint.Style.FILL
        }
        val fill = Path(line).apply {
            lineTo(720f, 240f)
            lineTo(0f, 240f)
            close()
        }
        canvas.drawPath(fill, paint)
        paint.color = 0xFF346EDB.toInt()
        paint.style = Paint.Style.STROKE
        paint.strokeWidth = 6f
        paint.strokeJoin = Paint.Join.ROUND
        canvas.drawPath(line, paint)
        return bitmap
    }
}

/** 组件点击路由：`verifin://widget/<实例 id>/<route>`，data 里的实例 id 同时保证
 * 各实例的 PendingIntent 互不覆盖（Intent 的 extras 不参与 filterEquals）。 */
fun widgetUri(id: Int, route: String, bookId: String = ""): Uri = Uri.Builder()
    .scheme("verifin")
    .authority("widget")
    .appendPath(id.toString())
    .appendPath(route)
    .appendQueryParameter("bookId", bookId)
    .build()

fun widgetAction(context: Context, id: Int, route: String, bookId: String): Action =
    actionStartActivity<MainActivity>(context, widgetUri(id, route, bookId))

/**
 * 「点击进入配置」的动作：直接拉起配置页，并把实例 id 交给它。
 *
 * 必须带 `ACTION_APPWIDGET_CONFIGURE`（home_widget 的
 * `initiallyLaunchedFromHomeWidgetConfigure` 按这个 action + `EXTRA_APPWIDGET_ID` 取值），
 * 同时用带实例 id 的 data 保证 PendingIntent 唯一。
 */
fun widgetSetupIntent(context: Context, id: Int): Intent =
    Intent(context, WidgetConfigurationActivity::class.java)
        .setAction(AppWidgetManager.ACTION_APPWIDGET_CONFIGURE)
        .setData(widgetUri(id, "setup"))
        .putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, id)
        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)

fun widgetSetupAction(context: Context, id: Int): Action =
    actionStartActivity(widgetSetupIntent(context, id))

/** RemoteViews 叶子（快速记账横条）用 PendingIntent 而不是 Glance Action。 */
fun widgetSetupPendingIntent(context: Context, id: Int): PendingIntent {
    var flags = PendingIntent.FLAG_UPDATE_CURRENT
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
        flags = flags or PendingIntent.FLAG_IMMUTABLE
    }
    // requestCode 用实例 id：每个实例一个独立的 PendingIntent。
    return PendingIntent.getActivity(context, id, widgetSetupIntent(context, id), flags)
}

open class VeriFinGlanceWidget(val template: VeriFinWidgetTemplate) : GlanceAppWidget() {
    override val stateDefinition = HomeWidgetGlanceStateDefinition()
    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val widgetId = GlanceAppWidgetManager(context).getAppWidgetId(id)
        provideContent {
            val preferences = currentState<HomeWidgetGlanceState>().preferences
            val data = VeriFinWidgetStore.display(
                context,
                template,
                VeriFinWidgetStore.config(preferences, widgetId),
                prefs = preferences,
            )
            VeriFinWidgetContent(
                template,
                data,
                widgetAction(context, widgetId, "app", data.bookId),
                widgetAction(context, widgetId, "entry", data.bookId),
                widgetSetupAction(context, widgetId),
                widgetId,
            )
        }
    }

    override suspend fun providePreview(context: Context, widgetCategory: Int) {
        provideContent {
            VeriFinWidgetContent(
                template,
                VeriFinWidgetStore.display(
                    context,
                    template,
                    WidgetInstanceSelection(),
                    sample = true,
                ),
            )
        }
    }
}

class QuickEntryGlanceWidget : VeriFinGlanceWidget(VeriFinWidgetTemplate.QUICK_ENTRY)
class BudgetGlanceWidget : VeriFinGlanceWidget(VeriFinWidgetTemplate.BUDGET)
class NetWorthGlanceWidget : VeriFinGlanceWidget(VeriFinWidgetTemplate.NET_WORTH)
class TrendGlanceWidget : VeriFinGlanceWidget(VeriFinWidgetTemplate.TREND)

abstract class VeriFinWidgetReceiver<T : VeriFinGlanceWidget> : HomeWidgetGlanceWidgetReceiver<T>() {
    /**
     * 预览指纹决定系统生成预览何时重推（系统限流约 2 次/小时）。
     * 用**应用版本**而不是手写版本号：任何一次视觉改动都随发版一起失效，
     * 不需要（也不允许）记得改常量。
     */
    override fun previewFingerprint(context: Context): String = listOf(
        "verifin-glance",
        BuildConfig.VERSION_NAME,
        glanceAppWidget.template.key,
        context.resources.configuration.uiMode.toString(),
        VeriFinWidgetStore.prefs(context).getString("verifin.widget.locale", ""),
    ).joinToString("|")

    override fun onDeleted(context: Context, appWidgetIds: IntArray) {
        val editor = VeriFinWidgetStore.prefs(context).edit()
        appWidgetIds.forEach { editor.remove(VeriFinWidgetStore.CONFIG_PREFIX + it) }
        editor.apply()
        super.onDeleted(context, appWidgetIds)
    }
}

class QuickEntryWidgetProvider : VeriFinWidgetReceiver<QuickEntryGlanceWidget>() {
    override val glanceAppWidget = QuickEntryGlanceWidget()
}

class BudgetWidgetProvider : VeriFinWidgetReceiver<BudgetGlanceWidget>() {
    override val glanceAppWidget = BudgetGlanceWidget()
}

class NetWorthWidgetProvider : VeriFinWidgetReceiver<NetWorthGlanceWidget>() {
    override val glanceAppWidget = NetWorthGlanceWidget()
}

class TrendWidgetProvider : VeriFinWidgetReceiver<TrendGlanceWidget>() {
    override val glanceAppWidget = TrendGlanceWidget()
}
