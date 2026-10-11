import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/chart_painters.dart';

import 'support/test_harness.dart';

// 柱子的圆角适配规则。
//
// fl_chart 会把「正柱」的像素高度垫到至少 `cornerHeight`（上下圆角半径之和）：半径
// 写死 4 时，任何算出来矮于 8px 的柱子都被画成一条等高的短杠。看板近 7 日卡片切换
// 支出 / 收入时，归零的柱子因此表现为「平滑缩小 → 卡成短杠不动 → 末帧整根消失」。
// 适配层让圆角跟着柱高走（不超过柱高的一半），矮柱才不会被垫高。
void main() {
  ChartTooltip tooltipOf(int index) =>
      ChartTooltip(title: '第 $index 天', lines: const <ChartTooltipLine>[]);

  /// 取第 [groupIndex] 根柱子交给 fl_chart 的圆角半径。
  double rodRadius(WidgetTester tester, int groupIndex) {
    final chart = tester.widget<BarChart>(find.byType(BarChart));
    final rod = chart.data.barGroups[groupIndex].barRods.first;
    return rod.borderRadius!.topLeft.x;
  }

  Future<void> pumpChart(WidgetTester tester) async {
    await tester.pumpWidget(
      zhMaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 138,
              child: InteractiveBarChart(
                values: const <double>[1000, 1, 0],
                tooltipOf: tooltipOf,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('矮柱子的圆角不超过柱高的一半，不会被垫成固定高度的短杠', (tester) async {
    await pumpChart(tester);

    // 高柱（1000 / 轴上限 1080，绘图区约 116dp）保留设计圆角。
    expect(rodRadius(tester, 0), 4);
    // 1 的柱子只有约 0.1dp 高：圆角必须跟着收窄，否则 fl_chart 会把它垫到 8dp。
    expect(rodRadius(tester, 1), lessThan(0.5));
    // 零值柱子不画，圆角归零。
    expect(rodRadius(tester, 2), 0);
  });

  testWidgets('单序列柱子可以用语义色指定颜色', (tester) async {
    await tester.pumpWidget(
      zhMaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 138,
              child: InteractiveBarChart(
                values: const <double>[1, 2, 3],
                color: const Color(0xFF123456),
                tooltipOf: tooltipOf,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final chart = tester.widget<BarChart>(find.byType(BarChart));
    expect(
      chart.data.barGroups.first.barRods.first.color,
      const Color(0xFF123456),
    );
  });
}
