import 'dart:convert';

import 'package:flutter/material.dart';

import 'app_theme.dart';

/// 鸣谢头像：由展示名**确定性生成**的点阵头像，不依赖任何素材或第三方库。
///
/// 名单里的人没有提供头像，也不该去网上抓，所以这里按名字画一张：名字 → 稳定哈希 →
/// 5×5 左右对称的点阵 + 固定的身份底色。
///
/// 三条硬约束（`test/credits_test.dart` 断言）：
///
/// 1. **同名同图**：算法是纯函数，且不用 `String.hashCode`（它不保证跨 SDK 版本
///    稳定），自己实现 FNV-1a——否则升级一次 Flutter 就可能让所有人的头像换脸。
/// 2. **可读**：底色与图案的对比度 ≥ 4.5:1，且不随主题变化（同一个人在浅色与深色
///    主题下必须是同一张脸）。
/// 3. **不空**：点阵不会全空，避免渲染成一张纯色圆。

/// 点阵边长（5×5）：左半由哈希决定，右半镜像。
const int creditsAvatarGridSize = 5;

/// 生成头像用的 32 位 FNV-1a 哈希（按 UTF-8 字节）。
int creditsAvatarHash(String seed) {
  var hash = 0x811c9dc5;
  for (final byte in utf8.encode(seed)) {
    hash = (hash ^ byte) * 0x01000193 & 0xFFFFFFFF;
  }
  return hash;
}

/// 5×5 左右对称的点阵。只用哈希的低 15 位：列 0–2 取位决定，列 3–4 为镜像，
/// 因此任何名字都得到一个左右对称、看起来像「头像」而不像噪点的图案。
List<List<bool>> creditsAvatarPattern(String seed) {
  var hash = creditsAvatarHash(seed);
  final pattern = List<List<bool>>.generate(
    creditsAvatarGridSize,
    (_) => List<bool>.filled(creditsAvatarGridSize, false),
  );
  for (var row = 0; row < creditsAvatarGridSize; row++) {
    for (var col = 0; col < (creditsAvatarGridSize + 1) ~/ 2; col++) {
      final on = hash & 1 == 1;
      hash >>= 1;
      pattern[row][col] = on;
      pattern[row][creditsAvatarGridSize - 1 - col] = on;
    }
  }
  // 两端退化（各约 1/32768）都要兜住：全空会渲染成一张纯色圆，全满会渲染成一张
  // 全白圆，都不像头像。翻转中心格最省事，也保持左右对称。
  final center = creditsAvatarGridSize ~/ 2;
  final filled = pattern.expand((row) => row).where((cell) => cell).length;
  if (filled == 0) {
    pattern[center][center] = true;
  } else if (filled == creditsAvatarGridSize * creditsAvatarGridSize) {
    pattern[center][center] = false;
  }
  return pattern;
}

/// 头像的底色与图案色。
@immutable
class CreditsAvatarStyle {
  const CreditsAvatarStyle(this.background, [this.mark = Colors.white]);

  final Color background;
  final Color mark;
}

/// 身份色板（顺序即取色顺序）。
///
/// **故意不跟随主题色**：同一个人在浅色 / 深色主题、任何版本下都必须是同一张脸。
/// 只取非语义的品牌色——`veriIncome` / `veriExpense` / `veriBlue` / `veriWarning`
/// 表达金额与状态语义，拿来当头像底会让人误读。`veriCyan` / `veriMint` 在本仓库
/// 本就是装饰色（「我的」宫格），但原色太亮（与白色对比 < 3:1），按同一色相压暗后
/// 使用；每个底色与白色图案的对比度由测试断言 ≥ 4.5:1。
final List<CreditsAvatarStyle> creditsAvatarStyles =
    List<CreditsAvatarStyle>.unmodifiable(<CreditsAvatarStyle>[
      const CreditsAvatarStyle(veriRoyal),
      const CreditsAvatarStyle(veriIndigo),
      CreditsAvatarStyle(
        HSLColor.fromColor(veriCyan).withLightness(0.32).toColor(),
      ),
      CreditsAvatarStyle(
        HSLColor.fromColor(veriMint).withLightness(0.28).toColor(),
      ),
    ]);

/// 按名字取身份色（纯函数）。
CreditsAvatarStyle creditsAvatarStyleFor(String seed) =>
    creditsAvatarStyles[creditsAvatarHash(seed) % creditsAvatarStyles.length];

/// 鸣谢头像。
///
/// 有 [imageAsset]（对方给了真实头像，图片放在 `assets/credits/`）时圆形裁剪显示该
/// 图片；否则按 [seed]（默认取展示名）生成点阵头像。
class CreditsAvatar extends StatelessWidget {
  const CreditsAvatar({
    super.key,
    required this.seed,
    this.imageAsset,
    this.size = 56,
  });

  /// 生成头像的种子；改名后想保住原头像时，由调用方传固定值。
  final String seed;

  /// 真实头像资源路径，为空则生成点阵头像。
  final String? imageAsset;

  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = imageAsset;
    if (asset != null) {
      return ClipOval(
        child: Image.asset(asset, width: size, height: size, fit: BoxFit.cover),
      );
    }
    return SizedBox.square(
      dimension: size,
      child: CustomPaint(
        painter: _CreditsAvatarPainter(
          seed: seed,
          style: creditsAvatarStyleFor(seed),
        ),
      ),
    );
  }
}

class _CreditsAvatarPainter extends CustomPainter {
  const _CreditsAvatarPainter({required this.seed, required this.style});

  final String seed;
  final CreditsAvatarStyle style;

  /// 点阵占头像直径的比例：留出边距，避免方块被圆边切掉一角。
  static const double _patternExtent = 0.78;

  @override
  void paint(Canvas canvas, Size size) {
    final side = size.shortestSide;
    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, side / 2, Paint()..color = style.background);

    final pattern = creditsAvatarPattern(seed);
    final gridSide = side * _patternExtent;
    final cell = gridSide / creditsAvatarGridSize;
    final origin = Offset(
      (size.width - gridSide) / 2,
      (size.height - gridSide) / 2,
    );
    final mark = Paint()..color = style.mark;
    final corner = Radius.circular(cell * 0.18);
    for (var row = 0; row < creditsAvatarGridSize; row++) {
      for (var col = 0; col < creditsAvatarGridSize; col++) {
        if (!pattern[row][col]) {
          continue;
        }
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              origin.dx + col * cell,
              origin.dy + row * cell,
              cell,
              cell,
            ),
            corner,
          ),
          mark,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_CreditsAvatarPainter oldDelegate) =>
      oldDelegate.seed != seed || oldDelegate.style != style;
}
