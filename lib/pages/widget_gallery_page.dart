import 'dart:async';

import 'package:flutter/material.dart';

import '../app/common_widgets.dart';
import '../app/native_widget_preview.dart';
import '../app/veri_fin_scope.dart';
import '../app/widgets/widget_catalog.dart';
import '../app/widgets/widget_service.dart';
import '../l10n/app_localizations.dart';

/// 「我的 → 桌面小组件」：只读模板画廊。
///
/// 预览用原生渲染器绘制当前账本的真实数据（与桌面同一套 Glance 组合）。
/// 页面进入时推一次投影，让预览拿到最新数据；之后不再跟着界面变化重算。
class WidgetGalleryPage extends StatefulWidget {
  const WidgetGalleryPage({super.key});

  @override
  State<WidgetGalleryPage> createState() => _WidgetGalleryPageState();
}

class _WidgetGalleryPageState extends State<WidgetGalleryPage> {
  bool _pushed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pushed) return;
    _pushed = true;
    unawaited(pushWidgetProjection(VeriFinScope.of(context), force: true));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final bookId = VeriFinScope.of(context).activeBook.id;
    return Scaffold(
      body: SafeArea(
        child: VeriPage(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
            children: <Widget>[
              VeriHeader(
                title: l.widgetGalleryTitle,
                subtitle: l.widgetGallerySubtitle,
                showBack: true,
              ),
              const SizedBox(height: 12),
              LayoutBuilder(
                builder: (context, constraints) {
                  final column = ((constraints.maxWidth - 12) / 2)
                      .floor()
                      .clamp(100, 280);
                  final wide = column * 2 + 12;
                  Widget preview(WidgetTemplate template, int w, int h) =>
                      NativeWidgetPreview(
                        key: ValueKey('widget_gallery_${template.key}'),
                        template: template.key,
                        width: w,
                        height: h,
                        bookId: bookId,
                        semanticLabel: template.name(l),
                      );
                  return Column(
                    children: <Widget>[
                      // 4×2 放最前面：整宽卡片收在顶部，后面的两列不会在中间留洞。
                      preview(WidgetTemplate.trend, wide, column),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          preview(WidgetTemplate.quickEntry, column, 72),
                          const SizedBox(width: 12),
                          preview(WidgetTemplate.budget, column, column),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          preview(WidgetTemplate.netWorth, column, column),
                          const SizedBox(width: 12),
                          Expanded(child: _HowToAddCard(height: column)),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 收纳添加与配置说明的卡片，同时填补末行右侧的空位。
class _HowToAddCard extends StatelessWidget {
  const _HowToAddCard({required this.height});

  final int height;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SizedBox(
      height: height.toDouble(),
      child: VeriCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              l.widgetGalleryShort,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l.widgetHowToAddDesc,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l.widgetConfigureHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
