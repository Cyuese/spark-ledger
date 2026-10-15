import 'dart:convert';

import 'package:crypto/crypto.dart' show sha1;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:jdenticon_dart/jdenticon_dart.dart';

/// 鸣谢头像：把称呼哈希成一张 [Jdenticon] 头像（三层几何图形）。
///
/// 算法实现在 `third_party/jdenticon_dart`（上游 MIT，本地 vendor，只放宽了 SDK
/// 上限；原因与同步方式见该目录的 README）。
///
/// 三条硬约束（`test/credits_test.dart` 断言）：
///
/// 1. **同名同图**：只依赖 `SHA1(seed)`，同一称呼在任何设备、任何版本上都是同一张脸；
/// 2. **不联网、不抓图、不读主题**：几何图形由本地算法画出，颜色只由名字决定，
///    因此浅色与深色主题下是同一张头像；
/// 3. **可读**：jdenticon 默认在透明底上画三层图形（明度 0.3–0.9），这里补一层与图案
///    同色相的高明度圆底，保证图形在深浅两种界面上都看得清。

/// 生成头像 SVG；结果只与 [seed] 有关，因此按 seed 缓存——列表滚动、页面重建都不会
/// 重复算哈希。缓存上界就是名单长度（几百条也只是几百个短字符串）。
String creditsAvatarSvg(String seed) => _svgCache[seed] ??= _buildSvg(seed);

final Map<String, String> _svgCache = <String, String>{};

String _buildSvg(String seed) => Jdenticon.toSvg(
  seed,
  size: 200,
  // 圆形裁切会切掉画布四角，留白比上游默认值（0.08）稍大，避免外层图形贴边被削平。
  padding: 0.12,
  backColor: _discColor(seed),
);

/// 淡彩圆底：取与图案同一个色相（jdenticon 自己也是从哈希尾部取色相），明度拉到很高，
/// 这样三层图形（0.3–0.9）在深浅两种界面上都有对比，同一个人换主题也不会「换脸」。
String _discColor(String seed) {
  final hash = '${sha1.convert(utf8.encode(seed))}';
  final hue = int.parse(hash.substring(hash.length - 7), radix: 16) / 0xfffffff;
  return '#${_hex(HSLColor.fromAHSL(1, hue * 360, 0.34, 0.93).toColor())}ff';
}

String _hex(Color color) {
  String channel(double value) =>
      (value * 255).round().clamp(0, 255).toRadixString(16).padLeft(2, '0');
  return '${channel(color.r)}${channel(color.g)}${channel(color.b)}';
}

/// 鸣谢头像。
///
/// 有 [imageAsset]（对方给了真实头像，图片放在 `assets/credits/`）时圆形裁剪显示该
/// 图片；否则按 [seed]（默认取展示名）生成 jdenticon 头像。
class CreditsAvatar extends StatelessWidget {
  const CreditsAvatar({
    super.key,
    required this.seed,
    this.imageAsset,
    this.size = 56,
  });

  /// 生成头像的种子；改名后想保住原头像时，由调用方传固定值。
  final String seed;

  /// 真实头像资源路径，为空则生成 jdenticon 头像。
  final String? imageAsset;

  final double size;

  @override
  Widget build(BuildContext context) {
    final asset = imageAsset;
    return ClipOval(
      child: asset != null
          ? Image.asset(asset, width: size, height: size, fit: BoxFit.cover)
          : SvgPicture.string(
              creditsAvatarSvg(seed),
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
    );
  }
}
