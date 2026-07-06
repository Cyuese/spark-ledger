import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/chart_painters.dart';

/// 一个采样点的 RGBA（各通道 0–255）。
typedef _Rgba = ({int r, int g, int b, int a});

/// 把 [BudgetRingPainter] 画到位图并按角度采样环带中线上的像素。
Future<List<_Rgba>> _sampleRing({
  required double value,
  required int size,
  required List<double> anglesRad,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  BudgetRingPainter(
    value: value,
    trackColor: const Color(0xFF333333),
    progressColor: const Color(0xFFF5A623), // 黄
  ).paint(canvas, Size(size.toDouble(), size.toDouble()));
  final image = await recorder.endRecording().toImage(size, size);
  final data = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  image.dispose();

  final center = size / 2;
  final strokeWidth = size * 0.10;
  // rect 内缩了 strokeWidth/2，环带中线半径即 rect 短边的一半。
  final radius = (size - strokeWidth) / 2;
  final samples = <_Rgba>[];
  for (final angle in anglesRad) {
    final x = (center + radius * math.cos(angle)).round().clamp(0, size - 1);
    final y = (center + radius * math.sin(angle)).round().clamp(0, size - 1);
    final offset = (y * size + x) * 4;
    samples.add((
      r: data.getUint8(offset),
      g: data.getUint8(offset + 1),
      b: data.getUint8(offset + 2),
      a: data.getUint8(offset + 3),
    ));
  }
  return samples;
}

int _maxChannelDelta(_Rgba a, _Rgba b) {
  return [
    (a.r - b.r).abs(),
    (a.g - b.g).abs(),
    (a.b - b.b).abs(),
  ].reduce(math.max);
}

void main() {
  // 回归：进度环的扫描渐变过去用 startAngle 偏移色标，但 SweepGradient 的角度
  // 环绕断点恒在 +x 轴（3 点方向），导致右侧出现明显的黄/蓝硬分界线。改用
  // GradientRotation 后断点移到 12 点（首尾同色）——右侧应当平滑无接缝。
  testWidgets('budget ring has no color seam on the right (3 o\'clock)', (
    WidgetTester tester,
  ) async {
    await tester.runAsync(() async {
      const size = 240;
      // 绕 3 点方向（角度 0）密集采样，环绕断点若存在会造成相邻样本颜色突变。
      final angles = <double>[for (double a = -0.35; a <= 0.35; a += 0.02) a];
      final samples = await _sampleRing(
        value: 1, // 满环：每个角度都被绘制
        size: size,
        anglesRad: angles,
      );

      var maxAdjacentDelta = 0;
      for (var i = 1; i < samples.length; i++) {
        // 只在两侧都画到了环带（不透明）时比较。
        if (samples[i].a > 200 && samples[i - 1].a > 200) {
          maxAdjacentDelta = math.max(
            maxAdjacentDelta,
            _maxChannelDelta(samples[i], samples[i - 1]),
          );
        }
      }

      // 平滑渐变下相邻 ~1.1° 的颜色变化很小；旧的断点接缝会造成数十级的突跳。
      expect(maxAdjacentDelta, lessThan(24), reason: '右侧 3 点方向出现颜色突变，疑似渐变接缝回归');
    });
  });
}
