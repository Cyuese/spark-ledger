import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/common_widgets.dart';

void main() {
  test('热力图下标按日历日计算（闰年 2 月 29 日是第 60 格）', () {
    expect(heatmapDayIndexOfYear(DateTime(2024, 1, 1)), 0);
    expect(heatmapDayIndexOfYear(DateTime(2024, 2, 1)), 31);
    expect(heatmapDayIndexOfYear(DateTime(2024, 2, 29)), 59);
    expect(heatmapDayIndexOfYear(DateTime(2024, 3, 1)), 60);
    expect(heatmapDayIndexOfYear(DateTime(2024, 12, 31)), 365);
    // 平年 3 月 1 日比闰年早一天。
    expect(heatmapDayIndexOfYear(DateTime(2023, 3, 1)), 59);
    // 只认日历日期，与当天的时分秒无关（绝对时间差会在夏令时地区少算一天）。
    expect(heatmapDayIndexOfYear(DateTime(2024, 3, 30, 23, 30)), 89);
    expect(heatmapDayIndexOfYear(DateTime(2024, 3, 30, 0, 5)), 89);
  });

  testWidgets('热力图：只有一天有记录时只填一个格子', (tester) async {
    const filled = Color(0xFFE84D6A);
    // 2024-02-29 是当年第 60 天（下标 59）。
    final values = List<double>.filled(366, 0)..[59] = 120;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: VeriCalendarHeatmap(
              year: 2024,
              dailyValues: values,
              color: filled,
              emptyColor: const Color(0xFFE0E0E0),
              monthLabelOf: (month) => '$month月',
            ),
          ),
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    for (var month = 1; month <= 12; month++) {
      expect(find.text('$month月'), findsOneWidget);
    }
    // 峰值格子上色到 100%（alpha 1.0），其余格子要么是空底要么带透明度。
    final filledCells = find.byWidgetPredicate((widget) {
      if (widget is! Container) {
        return false;
      }
      final decoration = widget.decoration;
      if (decoration is! BoxDecoration) {
        return false;
      }
      final color = decoration.color;
      return color != null &&
          color.a == 1.0 &&
          color.toARGB32() == filled.toARGB32();
    });
    expect(filledCells, findsOneWidget);
  });
}
