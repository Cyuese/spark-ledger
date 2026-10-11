// EmptyState 的渲染与降级约定：默认画跟随主题色的原生插画，不依赖外部素材；
// 系统开启「减少动态效果」时保持静止，不留下常驻动画。
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/app_theme.dart';
import 'package:verifin/app/common_widgets.dart';

Widget _host(
  Widget child, {
  Brightness brightness = Brightness.light,
  bool reduceMotion = false,
}) {
  return MaterialApp(
    theme: buildVeriFinTheme(brightness),
    home: Builder(
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduceMotion),
        child: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

void main() {
  testWidgets('空状态渲染插画与文案，且不再依赖动画资产', (tester) async {
    await tester.pumpWidget(
      _host(
        EmptyState(
          icon: Icons.search_off,
          title: '暂无数据',
          description: '保存记录后会显示在这里。',
          action: FilledButton(onPressed: () {}, child: const Text('添加账户')),
        ),
      ),
    );

    expect(find.byKey(const Key('empty_state_illustration')), findsOneWidget);
    expect(find.text('暂无数据'), findsOneWidget);
    expect(find.text('保存记录后会显示在这里。'), findsOneWidget);
    expect(find.text('添加账户'), findsOneWidget);
  });

  testWidgets('空状态插画在深色主题下同样渲染', (tester) async {
    await tester.pumpWidget(
      _host(
        const EmptyState(
          icon: Icons.label_outline,
          title: '暂无标签',
          description: 'd',
        ),
        brightness: Brightness.dark,
      ),
    );

    expect(find.byKey(const Key('empty_state_illustration')), findsOneWidget);
    expect(find.text('暂无标签'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('插画只有一次性入场动画，页面能收敛到静止', (tester) async {
    await tester.pumpWidget(
      _host(
        const EmptyState(icon: Icons.search_off, title: 't', description: 'd'),
      ),
    );

    // 入场期间还在出帧；常驻循环动画会让 pumpAndSettle 直接超时。
    await tester.pump(const Duration(milliseconds: 60));
    expect(tester.binding.hasScheduledFrame, isTrue);
    await tester.pumpAndSettle();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('开启减少动态效果时插画直接到位', (tester) async {
    await tester.pumpWidget(
      _host(
        const EmptyState(icon: Icons.search_off, title: 't', description: 'd'),
        reduceMotion: true,
      ),
    );

    await tester.pump();
    expect(tester.binding.hasScheduledFrame, isFalse);
  });
}
