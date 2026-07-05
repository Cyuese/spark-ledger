import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/entry_sheets.dart';
import 'package:verifin/app/models.dart';

import 'support/test_harness.dart';

void main() {
  final categories = <Category>[
    const Category(
      id: 'dining',
      label: '餐饮',
      type: EntryType.expense,
      iconCode: 'dining',
    ),
    const Category(
      id: 'coffee',
      label: '咖啡',
      type: EntryType.expense,
      iconCode: 'dining',
      parentId: 'dining',
    ),
    const Category(
      id: 'shopping',
      label: '购物',
      type: EntryType.expense,
      iconCode: 'shopping',
    ),
  ];

  Future<String?> openPicker(WidgetTester tester) async {
    String? result;
    await tester.pumpWidget(
      zhMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  result = await showModalBottomSheet<String>(
                    context: context,
                    builder: (_) => CategoryPickerSheet(
                      categories: categories,
                      selectedId: 'dining',
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    return Future<String?>.value(result);
  }

  testWidgets('子分类默认展开显示', (tester) async {
    await openPicker(tester);
    expect(find.text('餐饮'), findsOneWidget);
    expect(find.text('咖啡'), findsOneWidget);
    expect(find.text('购物'), findsOneWidget);
  });

  testWidgets('折叠父分类隐藏其子分类', (tester) async {
    await openPicker(tester);
    // 「餐饮」有子分类，尾部是展开箭头，点击后收起「咖啡」。
    await tester.tap(find.byIcon(Icons.expand_more));
    await tester.pumpAndSettle();
    expect(find.text('咖啡'), findsNothing);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('点选子分类返回其 id', (tester) async {
    String? picked;
    await tester.pumpWidget(
      zhMaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  picked = await showModalBottomSheet<String>(
                    context: context,
                    builder: (_) => CategoryPickerSheet(
                      categories: categories,
                      selectedId: 'dining',
                    ),
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('咖啡'));
    await tester.pumpAndSettle();
    expect(picked, 'coffee');
  });
}
