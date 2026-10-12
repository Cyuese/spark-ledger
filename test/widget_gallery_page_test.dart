import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/native_widget_preview.dart';
import 'package:verifin/app/veri_fin_scope.dart';
import 'package:verifin/pages/widget_gallery_page.dart';

import 'support/test_harness.dart';

void main() {
  useTestDatabases();

  // 预览走 MethodChannel；测试宿主没有原生实现，未挂 mock 的调用会一直挂起
  // （预览停在加载态 → pumpAndSettle 超时），所以这里显式给出空实现。
  void mockChannels() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('verifin/app'),
          (call) async => null,
        );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('home_widget'),
          (call) async => null,
        );
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('verifin/app'), null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('home_widget'), null);
  });

  Future<void> pumpGallery(WidgetTester tester, Size size) async {
    mockChannels();
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = size;
    addTearDown(tester.view.reset);
    final controller = await makeController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      VeriFinScope(
        controller: controller,
        child: zhMaterialApp(home: const WidgetGalleryPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final size in const <Size>[Size(393, 852), Size(360, 800)]) {
    testWidgets('模板画廊 $size 按 4×2 → 2×1/2×2 → 2×2 排布且不溢出', (tester) async {
      await pumpGallery(tester, size);

      expect(tester.takeException(), isNull);
      for (final key in <String>[
        'widget_gallery_trend',
        'widget_gallery_quick_entry',
        'widget_gallery_budget',
        'widget_gallery_net_worth',
      ]) {
        expect(find.byKey(ValueKey<String>(key)), findsOneWidget, reason: key);
      }
      expect(find.byType(NativeWidgetPreview), findsNWidgets(4));

      final trend = tester.getTopLeft(
        find.byKey(const ValueKey<String>('widget_gallery_trend')),
      );
      final quick = tester.getTopLeft(
        find.byKey(const ValueKey<String>('widget_gallery_quick_entry')),
      );
      final budget = tester.getTopLeft(
        find.byKey(const ValueKey<String>('widget_gallery_budget')),
      );
      final netWorth = tester.getTopLeft(
        find.byKey(const ValueKey<String>('widget_gallery_net_worth')),
      );
      // 整宽的 4×2 在最上面，之后才是两列，末行不会在中间留下空洞。
      expect(trend.dy, lessThan(quick.dy));
      expect(quick.dy, budget.dy);
      expect(quick.dx, lessThan(budget.dx));
      expect(netWorth.dy, greaterThan(budget.dy));
      expect(netWorth.dx, quick.dx);

      // 说明卡与净资产预览同排，右侧不再空一格。
      expect(find.textContaining('长按桌面空白处'), findsOneWidget);
    });
  }

  testWidgets('画廊页沿用统一页边距（14，有效 16）', (tester) async {
    await pumpGallery(tester, const Size(393, 852));
    final listView = tester.widget<ListView>(
      find
          .descendant(
            of: find.byType(WidgetGalleryPage),
            matching: find.byType(ListView),
          )
          .first,
    );
    expect(listView.padding, const EdgeInsets.fromLTRB(14, 8, 14, 28));
  });
}
