import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/test_harness.dart';

void main() {
  useTestDatabases();

  Future<void> openNumberPad(WidgetTester tester) async {
    await pumpApp(tester);
    await tapBottomTab(tester, 0);
    await tester.tap(find.byKey(const Key('quick_entry_fab')));
    await tester.pumpAndSettle();
  }

  testWidgets('算式 500+800 展示结果并可确认为 1300', (tester) async {
    await openNumberPad(tester);

    await tester.tap(find.byKey(const Key('number_key_5')));
    await tester.tap(find.byKey(const Key('number_key_00')));
    await tester.tap(find.byKey(const Key('number_key_+')));
    await tester.tap(find.byKey(const Key('number_key_8')));
    await tester.tap(find.byKey(const Key('number_key_00')));
    await tester.pump();

    // 右下角浅色结果预览。
    expect(find.text('= 1300'), findsOneWidget);

    await tester.tap(find.byKey(const Key('number_pad_ok')));
    await tester.pumpAndSettle();

    // 落到记账页，大金额为 1300。
    expect(find.text('1300'), findsOneWidget);
  });

  testWidgets('不完整算式提示且不可确认', (tester) async {
    await openNumberPad(tester);

    await tester.tap(find.byKey(const Key('number_key_5')));
    await tester.tap(find.byKey(const Key('number_key_00')));
    await tester.tap(find.byKey(const Key('number_key_+')));
    await tester.pump();

    expect(find.text('算式不完整'), findsOneWidget);

    final okButton = tester.widget<FilledButton>(
      find.byKey(const Key('number_pad_ok')),
    );
    expect(okButton.onPressed, isNull);
  });
}
