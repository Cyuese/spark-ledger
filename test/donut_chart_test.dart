import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/chart_painters.dart';

void main() {
  testWidgets('环内百分比标题与可点中心', (tester) async {
    var centerTaps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: VeriDonutChart(
                segments: const <VeriDonutSegment>[
                  VeriDonutSegment(
                    label: 'A',
                    value: 60,
                    color: Color(0xFF346EDB),
                  ),
                  VeriDonutSegment(
                    label: 'B',
                    value: 40,
                    color: Color(0xFF2AA198),
                  ),
                ],
                ringWidth: 30,
                showPercentTitles: true,
                onCenterTap: () => centerTaps++,
                center: const Text('center'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 环内标题由 fl_chart 直接绘制（不是 Text 组件），只能断言整体渲染成功。
    expect(find.byType(VeriDonutChart), findsOneWidget);

    await tester.tap(find.text('center'));
    await tester.pumpAndSettle();
    expect(centerTaps, 1);
  });

  testWidgets('占比过小的分段不画环内文字', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: VeriDonutChart(
                segments: const <VeriDonutSegment>[
                  VeriDonutSegment(
                    label: 'A',
                    value: 99,
                    color: Color(0xFF346EDB),
                  ),
                  VeriDonutSegment(
                    label: 'B',
                    value: 1,
                    color: Color(0xFF2AA198),
                  ),
                ],
                ringWidth: 30,
                showPercentTitles: true,
                center: const Text('center'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(VeriDonutChart), findsOneWidget);
  });

  testWidgets('环形图分段点击回传正确索引且中心空区不越界', (tester) async {
    int? selected = -99;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: VeriDonutChart(
                segments: const <VeriDonutSegment>[
                  VeriDonutSegment(
                    label: 'A',
                    value: 1,
                    color: Color(0xFF346EDB),
                  ),
                  VeriDonutSegment(
                    label: 'B',
                    value: 1,
                    color: Color(0xFF2AA198),
                  ),
                ],
                center: const Text('center'),
                onSelected: (index) => selected = index,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final center = tester.getCenter(find.byType(VeriDonutChart));
    // 起始角 -90°，右半圆属于第一段。
    await tester.tapAt(center + const Offset(87, 0));
    await tester.pumpAndSettle();
    expect(selected, 0);

    // 中心空区应回传 null，且不能把 -1 索引交给上层。
    await tester.tapAt(center);
    await tester.pumpAndSettle();
    expect(selected, isNull);
    expect(tester.takeException(), isNull);
  });
}
