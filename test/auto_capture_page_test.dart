import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/ai/ai_settings.dart';
import 'package:verifin/app/veri_fin_scope.dart';
import 'package:verifin/local_storage/local_storage.dart';
import 'package:verifin/pages/auto_capture_settings_page.dart';

import 'support/test_harness.dart';

void main() {
  useTestDatabases();

  Future<void> pumpPage(WidgetTester tester, LocalKeyValueStore store) async {
    final controller = await makeController(store);
    await tester.pumpWidget(
      VeriFinScope(
        controller: controller,
        child: zhMaterialApp(home: const AutoCaptureSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('展示 Alpha 提示且默认未开启', (WidgetTester tester) async {
    await pumpPage(tester, LocalKeyValueStore());
    expect(find.textContaining('Alpha'), findsOneWidget);
    expect(find.text('开启通知自动记账'), findsOneWidget);
    // 未开启时不显示来源卡片。
    expect(find.text('监听来源'), findsNothing);
  });

  testWidgets('未配置 AI 时开启会引导去配置，且不启用', (WidgetTester tester) async {
    final store = LocalKeyValueStore();
    await pumpPage(tester, store);

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    // 弹出「需要先配置 AI」对话框。
    expect(find.text('需要先配置 AI'), findsOneWidget);
    // 开关保持关闭。
    expect(
      VeriFinScope.of(
        tester.element(find.byType(AutoCaptureSettingsPage)),
      ).autoCaptureSettings.notificationEnabled,
      isFalse,
    );
  });

  testWidgets('已配置 AI 时可开启并展示来源、写入默认来源', (WidgetTester tester) async {
    final store = LocalKeyValueStore();
    final controller = await makeController(store);
    controller.setAiSettings(
      const AiSettings(baseUrl: 'https://x/v1', apiKey: 'k', model: 'm'),
    );
    await tester.pumpWidget(
      VeriFinScope(
        controller: controller,
        child: zhMaterialApp(home: const AutoCaptureSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Switch).first);
    await tester.pumpAndSettle();

    expect(controller.autoCaptureSettings.notificationEnabled, isTrue);
    expect(
      controller.autoCaptureSettings.sourcePackages,
      contains('com.eg.android.AlipayGphone'),
    );
    // 开启后出现来源卡片。
    expect(find.text('监听来源'), findsOneWidget);
    // 持久化到 KV。
    expect(store.read('verifin.auto_capture.v1'), isNotNull);
  });
}
