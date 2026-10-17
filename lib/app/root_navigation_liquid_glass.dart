import 'package:flutter/material.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';

import '../l10n/app_localizations.dart';
import 'app_theme.dart';
import 'root_navigation.dart';

/// 可选液态玻璃底栏：把应用的根导航契约适配到 `GlassTabBar.bottom`。
///
/// 第三方玻璃实现只允许出现在这里，不能扩散到卡片、菜单、弹层或页面背景。
/// 四个目的地、回调时机和 Shell 切页状态机仍由 [VeriRootNavigationSpec] 决定。
class VeriLiquidGlassRootNavigationStyle implements VeriRootNavigationStyle {
  const VeriLiquidGlassRootNavigationStyle();

  /// 持久化标识。与 `NavigationStylePreference.liquidGlass` 的枚举名一致。
  static const String styleId = 'liquidGlass';

  /// 胶囊高度（不含系统安全区与底部留白）。
  static const double barHeight = 60;

  /// 胶囊左右外边距。
  static const double sideGap = 12;

  /// 胶囊与系统安全区之间的留白。
  static const double bottomGap = 24;

  /// 列表末项在避让之外额外保留的呼吸空间。
  static const double listBottomGap = 16;

  static const VeriRootNavigationLayout _layout = VeriRootNavigationLayout(
    extendBody: true,
    occupiedHeight: barHeight + bottomGap,
    listBottomGap: listBottomGap,
  );

  @override
  String get id => styleId;

  @override
  String label(AppLocalizations l10n) => l10n.navigationStyleLiquidGlassName;

  @override
  String description(AppLocalizations l10n) =>
      l10n.navigationStyleLiquidGlassDesc;

  @override
  VeriRootNavigationLayout get layout => _layout;

  /// 页面切页弹簧与底栏玻璃动画共用的时间尺度。
  ///
  /// `GlassTabBar.bottom` 的指示器使用库内弹簧，库没有公开 `.bottom` 的弹簧参数；
  /// 这里沿用原液态玻璃样式的时间尺度，避免 Shell 的切页动画先于或晚于底栏落位。
  @override
  Duration get switchDuration => const Duration(milliseconds: 240);

  @override
  Widget buildBar(BuildContext context, VeriRootNavigationSpec spec) =>
      VeriLiquidGlassRootNavigation(spec: spec);
}

/// `GlassTabBar.bottom` 的根导航适配层。
///
/// 预览场景把 [VeriRootNavigationSpec.onSelect] 设为 null；这里传入空回调以满足
/// 库的必填参数，但预览外层会通过 `IgnorePointer` 阻止交互。
class VeriLiquidGlassRootNavigation extends StatelessWidget {
  const VeriLiquidGlassRootNavigation({super.key, required this.spec});

  final VeriRootNavigationSpec spec;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final tabs = <GlassTab>[
      for (var index = 0; index < spec.destinations.length; index++)
        GlassTab(
          // `GlassTab` 本身没有 key；把稳定 key 放在未选中图标上。库会同时绘制
          // 未选中层和选中层，`activeIcon` 不重复挂 key，避免同一棵树出现重复 key。
          icon: KeyedSubtree(
            key: ValueKey<String>(spec.keyOf('nav_item_$index')),
            child: Icon(spec.destinations[index].icon),
          ),
          activeIcon: Icon(spec.destinations[index].selectedIcon),
          label: spec.destinations[index].label,
          semanticLabel: spec.destinations[index].label,
        ),
    ];

    return SafeArea(
      key: ValueKey<String>(spec.keyOf('bottom_nav')),
      top: false,
      maintainBottomViewPadding: true,
      minimum: const EdgeInsets.only(
        bottom: VeriLiquidGlassRootNavigationStyle.bottomGap,
      ),
      child: GlassTabBar.bottom(
        key: ValueKey<String>(spec.keyOf('nav_bar')),
        tabs: tabs,
        selectedIndex: spec.currentIndex,
        onTabSelected: spec.onSelect ?? (_) {},
        horizontalPadding: VeriLiquidGlassRootNavigationStyle.sideGap,
        // 当前样式的几何是 60dp 胶囊 + 24dp 底部留白；库的 verticalPadding
        // 会把自身高度算进 preferredSize，因此这里保持 0，由外层 SafeArea 提供留白。
        verticalPadding: 0,
        barHeight: VeriLiquidGlassRootNavigationStyle.barHeight,
        iconSize: 24,
        labelFontSize: 12,
        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        selectedIconColor: scheme.primary,
        unselectedIconColor: veriNavigationUnselected,
        selectedLabelColor: scheme.primary,
        unselectedLabelColor: veriNavigationUnselected,
        adaptiveBrightness: false,
        quality: GlassQuality.premium,
      ),
    );
  }
}
