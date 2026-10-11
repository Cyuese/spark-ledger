import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/models.dart';

import 'support/test_harness.dart';

/// 真实页面的冒烟测试：360/393 与浅深色下导航、菜单和保存都可用。
/// （原 `unified_design_preview_test.dart`：设计预览参数移除后，评审批次外观就是唯一外观。）
void main() {
  useTestDatabases();
  for (final width in [360.0, 393.0]) {
    for (final theme in [ThemePreference.light, ThemePreference.dark]) {
      testWidgets('真实页面 $width ${theme.name} 导航、菜单和保存可用', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 852);
        addTearDown(tester.view.reset);
        final controller = await pumpApp(tester);
        controller.setThemePreference(theme);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await addTestAccount(tester, '预览账户');
        expect(controller.accounts.single.name, '预览账户');
        for (final tab in [2, 3, 0]) {
          await tapBottomTab(tester, tab);
          expect(tester.takeException(), isNull);
        }
        await createQuickEntry(tester);
        expect(tester.takeException(), isNull);
        final save = find.byKey(const Key('save_entry_button'));
        expect(tester.getRect(save).bottom, lessThanOrEqualTo(852));
        await tester.tap(save);
        await tester.pumpAndSettle();
        await controller.waitForPendingWrites();
        expect(controller.entries.single.amount, 45);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
