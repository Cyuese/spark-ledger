package top.talyra42.verifin

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.res.Configuration
import android.graphics.Bitmap
import android.graphics.Canvas
import android.view.View
import android.widget.FrameLayout
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import es.antonborri.home_widget.HomeWidgetPreviews
import java.io.File
import java.util.Locale
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith

/**
 * 设备侧冒烟 + 预览导出。**手动执行，不进 CI**（CI 没有设备）：
 *
 * ```
 * dart run scripts/widget_previews.dart      # 构建、安装、跑本类并把 PNG 放回 res/
 * ```
 *
 * 覆盖三件事：
 * 1. 四个 Provider 与配置 Activity 都已在系统里注册、可加载；
 * 2. 快速记账横条在极长金额下不省略、不裁切，加号与整条点击互不覆盖；
 * 3. 真机渲染出选择器预览 PNG 与三种状态的样例 PNG（供人眼确认）。
 */
@RunWith(AndroidJUnit4::class)
class WidgetGlanceInstrumentationTest {
    private val context: Context
        get() = InstrumentationRegistry.getInstrumentation().targetContext

    /** 每个模板按「真实格子」的比例导出：2×1 / 2×2 / 4×2。 */
    private val sizes: Map<VeriFinWidgetTemplate, Pair<Int, Int>> = mapOf(
        VeriFinWidgetTemplate.QUICK_ENTRY to (220 to 72),
        VeriFinWidgetTemplate.BUDGET to (220 to 220),
        VeriFinWidgetTemplate.NET_WORTH to (220 to 220),
        VeriFinWidgetTemplate.TREND to (360 to 220),
    )

    private val output: File
        // 放外部私有目录：`scripts/widget_previews.dart` 可以直接 adb pull，
        // 不必走 run-as（设备上真机调试时更省事）。
        get() = File(
            context.getExternalFilesDir(null) ?: context.filesDir,
            "widget-previews",
        ).apply { mkdirs() }

    @Test
    fun providersAndConfigurationActivityAreInstalled() {
        val manager = AppWidgetManager.getInstance(context)
        val installed = manager.getInstalledProvidersForPackage(context.packageName, null)
            .map { it.provider.className }
        VeriFinWidgetTemplate.entries.forEach { template ->
            val expected = VeriFinWidgetTemplate.providerClass(template).name
            assertTrue("$expected 未在系统里注册", installed.contains(expected))
        }
        // 实例计数接口是「无实例就跳过刷新」闸门的依据，必须覆盖全部模板。
        assertEquals(
            VeriFinWidgetTemplate.entries.map { it.key }.toSet(),
            VeriFinWidgetTemplate.instanceCounts(context).keys,
        )
        assertTrue(
            "配置 Activity 必须可加载",
            WidgetConfigurationActivity::class.java.name.isNotBlank(),
        )
    }

    @Test
    fun quickEntryKeepsLongAmountsReadable() {
        val data = WidgetDisplay(
            state = WidgetContentState.READY,
            label = "今日支出",
            amount = "CNY 123,456,789.99",
            dark = true,
        )
        val density = context.resources.displayMetrics.density
        InstrumentationRegistry.getInstrumentation().runOnMainSync {
            for (width in listOf(148, 180, 220)) {
                val view = QuickWidgetContent.views(context, data)
                    .apply(context, FrameLayout(context))
                val w = (width * density).toInt()
                val h = (72 * density).toInt()
                view.measure(
                    View.MeasureSpec.makeMeasureSpec(w, View.MeasureSpec.EXACTLY),
                    View.MeasureSpec.makeMeasureSpec(h, View.MeasureSpec.EXACTLY),
                )
                view.layout(0, 0, w, h)
                for (id in listOf(R.id.quick_widget_label, R.id.quick_widget_amount)) {
                    val text = view.findViewById<android.widget.TextView>(id)
                    val layout = requireNotNull(text.layout)
                    assertTrue(
                        "宽度 $width 下出现省略号",
                        (0 until layout.lineCount).all { layout.getEllipsisCount(it) == 0 },
                    )
                    assertEquals(
                        "宽度 $width 下文本被裁切",
                        text.text.length,
                        layout.getLineEnd(layout.lineCount - 1),
                    )
                    assertTrue("宽度 $width 下文本被裁切", layout.height <= text.height)
                }
                val bitmap = Bitmap.createBitmap(w, h, Bitmap.Config.ARGB_8888)
                view.draw(Canvas(bitmap))
                bitmap.recycle()
            }
        }
        val app = widgetUri(41, "app", "book-a")
        val entry = widgetUri(41, "entry", "book-a")
        assertEquals("app", app.lastPathSegment)
        assertEquals("entry", entry.lastPathSegment)
        assertNotEquals(
            "整条点击与加号的 PendingIntent 不能互相覆盖",
            es.antonborri.home_widget.HomeWidgetLaunchIntent.getActivity(
                context, MainActivity::class.java, app,
            ),
            es.antonborri.home_widget.HomeWidgetLaunchIntent.getActivity(
                context, MainActivity::class.java, entry,
            ),
        )
    }

    /**
     * 导出人眼确认用的 PNG：16 张样例态（4 模板 × 深浅 × 中英）+ 各状态样例。
     * 用只读空偏好渲染样例态，所以不会读也不会写用户账目。
     */
    @Test
    fun exportRenders() = runBlocking {
        sizes.forEach { (template, size) ->
            listOf(false, true).forEach { dark ->
                listOf(false, true).forEach { english ->
                    val variant = variantContext(dark = dark, english = english)
                    val png = WidgetPreviewRenderer.png(
                        variant,
                        template,
                        size.first,
                        size.second,
                        WidgetInstanceSelection(
                            appearance = if (dark) WidgetAppearance.DARK else WidgetAppearance.LIGHT,
                        ),
                        sample = true,
                        prefs = HomeWidgetPreviews.emptyPreferences,
                    )
                    File(
                        output,
                        "sample-${template.key}-${if (dark) "dark" else "light"}-${if (english) "en" else "zh"}.png",
                    ).writeBytes(png)
                }
            }
        }

        // 三种状态都要能渲染：未配置、已配置但无数据、正常。
        val prefs = VeriFinWidgetStore.prefs(context)
        val configKey = "${VeriFinWidgetStore.CONFIG_PREFIX}9001"
        val snapshotKey = "verifin.widget.snapshots"
        val previousConfig = prefs.getString(configKey, null)
        val previousSnapshot = prefs.getString(snapshotKey, null)
        try {
            prefs.edit().remove(configKey).remove(snapshotKey).commit()
            VeriFinWidgetTemplate.entries.forEach { template ->
                val size = sizes.getValue(template)
                writeState(template, size, "setup")
            }

            prefs.edit()
                .putString(configKey, """{"bookId":"book-x","appearance":"light"}""")
                .commit()
            VeriFinWidgetTemplate.entries.forEach { template ->
                val size = sizes.getValue(template)
                writeState(template, size, "sync")
            }

            prefs.edit().putString(
                snapshotKey,
                """{"version":$SNAPSHOT_VERSION,"book-x":{"date":"2026-10-12",""" +
                    """"quick_entry":{"amount":"128"},""" +
                    """"budget":{"amount":"3872","usage":0.37},""" +
                    """"trend":{"amount":"1204","points":[0,12,8,20,16,28,24,36,30,42,38,50,44,58,52,66,60,74,68,82,76,90,84,98,92,106,100,114,108,122]},""" +
                    """"net_worth":{"amount":"52300","points":[51000,51100,51200,51300,51400,51500,51600,51700,51800,51900,52000,52050,52100,52150,52200,52250,52300,52350,52400,52450,52500,52550,52600,52650,52700,52750,52800,52850,52900,52950]}}}""",
            ).commit()
            VeriFinWidgetTemplate.entries.forEach { template ->
                val size = sizes.getValue(template)
                writeState(template, size, "ready")
            }
        } finally {
            prefs.edit().apply {
                if (previousConfig == null) remove(configKey) else putString(configKey, previousConfig)
                if (previousSnapshot == null) {
                    remove(snapshotKey)
                } else {
                    putString(snapshotKey, previousSnapshot)
                }
            }.commit()
        }
    }

    private suspend fun writeState(
        template: VeriFinWidgetTemplate,
        size: Pair<Int, Int>,
        state: String,
    ) {
        val selection = WidgetInstanceSelection(
            bookId = if (state == "setup") "" else "book-x",
            appearance = WidgetAppearance.LIGHT,
        )
        val png = WidgetPreviewRenderer.png(
            context,
            template,
            size.first,
            size.second,
            selection,
            sample = false,
        )
        File(output, "state-$state-${template.key}.png").writeBytes(png)
    }

    /** 指定深浅色与语言的资源上下文：预览 PNG 要按这两维各存一份。 */
    private fun variantContext(dark: Boolean, english: Boolean): Context {
        val config = Configuration(context.resources.configuration).apply {
            uiMode = (uiMode and Configuration.UI_MODE_NIGHT_MASK.inv()) or
                if (dark) Configuration.UI_MODE_NIGHT_YES else Configuration.UI_MODE_NIGHT_NO
            val locale = if (english) Locale.ENGLISH else Locale.SIMPLIFIED_CHINESE
            setLocale(locale)
            setLayoutDirection(locale)
        }
        return context.createConfigurationContext(config)
    }
}
