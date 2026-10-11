import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/app_theme.dart';
import 'package:verifin/app/common_widgets.dart';
import 'package:verifin/app/models.dart';
import 'package:verifin/pages/budget_pages.dart';
import 'package:verifin/pages/data_management_page.dart';
import 'package:verifin/pages/profile_pages.dart';
import 'package:verifin/pages/transactions_pages.dart';
import 'support/test_harness.dart';

void main() {
  useTestDatabases();
  for (final width in [360.0, 393.0]) {
    for (final theme in [ThemePreference.light, ThemePreference.dark]) {
      testWidgets('统一设计 $width $theme 根页面和管理页共享排版且可返回', (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 852);
        addTearDown(tester.view.reset);
        final controller = await pumpApp(tester);
        controller.setThemePreference(theme);
        await tester.pumpAndSettle();
        for (final tab in [0, 1, 2, 3]) {
          await tapBottomTab(tester, tab);
          expect(find.byType(VeriHeader), findsAtLeastNWidgets(1));
          expect(tester.takeException(), isNull);
        }
        final title = tester.widget<Text>(find.text('账本'));
        final subtitle = tester.widget<Text>(find.text('日常账本'));
        expect(title.style!.fontSize, greaterThan(subtitle.style!.fontSize!));
        expect(
          title.style!.fontWeight!.value,
          greaterThan(subtitle.style!.fontWeight!.value),
        );
        final context = tester.element(find.byType(ProfilePage));
        final navigator = Navigator.of(context);
        for (final page in <Widget>[
          const SettingsPage(),
          const TransactionsPage(),
          BudgetOverviewPage(initialMonth: DateTime(2026, 9)),
          const CategoryManagementPage(),
          const TagManagementPage(),
          const DataManagementPage(),
        ]) {
          // 路由返回在下方显式执行，不能先等待 push 完成。
          unawaited(
            navigator.push(MaterialPageRoute<void>(builder: (_) => page)),
          );
          await tester.pumpAndSettle();
          expect(find.byType(VeriHeader), findsAtLeastNWidgets(1));
          expect(tester.takeException(), isNull, reason: '${page.runtimeType}');
          navigator.pop();
          await tester.pumpAndSettle();
        }
      });
    }
  }

  // 评审外观现在是唯一外观：几何常量与骨架默认值都不再有第二套分支。
  test('设计令牌只保留评审外观的几何常量', () {
    expect(veriCardRadius, 16);
    expect(veriHeaderHeight, 56);
    expect(veriRadiusMd, 12);
    expect(veriRadiusLg, 16);
    expect(
      const VeriCard(child: SizedBox.shrink()).padding,
      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    );
  });

  // 大字号 + 英文是最容易撞上裁切的组合：四列宫格宽度固定，英文标签又长。
  testWidgets('大字号下「我的」宫格标签不被裁切', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 852);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final controller = await pumpApp(tester);
    controller.setLocalePreference(LocalePreference.en);
    await tester.pumpAndSettle();
    await tapBottomTab(tester, 3);

    final grid = find.byKey(
      const ValueKey<String>('profile_feature_grid_bookkeeping'),
    );
    for (final element
        in find.descendant(of: grid, matching: find.byType(Text)).evaluate()) {
      final paragraph = element.renderObject;
      if (paragraph is! RenderParagraph) {
        continue;
      }
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason: '宫格文案被裁切：${(element.widget as Text).data}',
      );
    }
    expect(tester.takeException(), isNull);
  });
}
