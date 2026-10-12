/// 选择器预览 PNG 的路径规则（纯逻辑，可单测）。
library;

/// 有预览图的四个模板（与 Dart/Kotlin 的模板 key 一致）。
const List<String> widgetPreviewTemplateKeys = <String>[
  'quick_entry',
  'budget',
  'trend',
  'net_worth',
];

/// 预览 PNG 在仓库里的目标路径。
///
/// Android 资源限定符顺序是「语言 → night → 密度」，所以四个变体分别落在
/// `drawable-nodpi` / `drawable-night-nodpi` / `drawable-en-nodpi` /
/// `drawable-en-night-nodpi`——目录名顺序写反会被 aapt2 当成非法限定符。
String previewDrawablePath({
  required String templateKey,
  required bool dark,
  required bool english,
}) {
  final qualifiers = <String>[
    if (english) 'en',
    if (dark) 'night',
    'nodpi',
  ].join('-');
  return 'android/app/src/main/res/drawable-$qualifiers/widget_preview_$templateKey.png';
}

/// 设备导出的文件名（`sample-<模板>-<light|dark>-<zh|en>.png`）映射到仓库内路径。
///
/// 返回 `null` 表示这个文件不是资源预览图（例如三种状态的确认图），由调用方忽略。
String? previewTargetFor(String exportName) {
  final match = RegExp(
    r'^sample-([a-z_]+)-(light|dark)-(zh|en)\.png$',
  ).firstMatch(exportName);
  if (match == null) return null;
  final templateKey = match.group(1)!;
  if (!widgetPreviewTemplateKeys.contains(templateKey)) return null;
  return previewDrawablePath(
    templateKey: templateKey,
    dark: match.group(2) == 'dark',
    english: match.group(3) == 'en',
  );
}
