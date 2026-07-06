import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/models.dart';
import 'package:verifin/local_storage/local_storage.dart';
import 'package:verifin/main.dart';

import 'support/test_harness.dart';

void main() {
  useTestDatabases();

  testWidgets('点击手动·长按AI：单点走数字键盘', (tester) async {
    final store = LocalKeyValueStore();
    final controller = await makeController(store);
    controller.setFabActionMode(FabActionMode.manualTapAiLongPress);
    await tester.pumpWidget(VeriFinApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('quick_entry_fab')));
    await tester.pumpAndSettle();

    // 数字键盘出现（OK 键存在）。
    expect(find.byKey(const Key('number_pad_ok')), findsOneWidget);
  });

  testWidgets('点击手动·长按AI：长按走AI（未配置则弹配置提示）', (tester) async {
    final store = LocalKeyValueStore();
    final controller = await makeController(store);
    controller.setFabActionMode(FabActionMode.manualTapAiLongPress);
    await tester.pumpWidget(VeriFinApp(controller: controller));
    await tester.pumpAndSettle();

    await tester.longPress(find.byKey(const Key('quick_entry_fab')));
    await tester.pumpAndSettle();

    // AI 未配置 → 弹出「尚未配置 AI」对话框；数字键盘不应出现。
    expect(find.text('尚未配置 AI'), findsOneWidget);
    expect(find.byKey(const Key('number_pad_ok')), findsNothing);
  });
}
