import 'package:flutter_test/flutter_test.dart';

import '../scripts/src/widget_previews.dart';

void main() {
  test('预览资源路径按「语言 → night → 密度」排列限定符', () {
    expect(
      previewDrawablePath(templateKey: 'budget', dark: false, english: false),
      'android/app/src/main/res/drawable-nodpi/widget_preview_budget.png',
    );
    expect(
      previewDrawablePath(templateKey: 'budget', dark: true, english: false),
      'android/app/src/main/res/drawable-night-nodpi/widget_preview_budget.png',
    );
    expect(
      previewDrawablePath(templateKey: 'budget', dark: false, english: true),
      'android/app/src/main/res/drawable-en-nodpi/widget_preview_budget.png',
    );
    expect(
      previewDrawablePath(templateKey: 'budget', dark: true, english: true),
      'android/app/src/main/res/drawable-en-night-nodpi/widget_preview_budget.png',
    );
  });

  test('导出文件名映射到仓库路径，非预览图忽略', () {
    expect(
      previewTargetFor('sample-trend-light-en.png'),
      'android/app/src/main/res/drawable-en-nodpi/widget_preview_trend.png',
    );
    expect(
      previewTargetFor('sample-net_worth-dark-zh.png'),
      'android/app/src/main/res/drawable-night-nodpi/widget_preview_net_worth.png',
    );
    expect(previewTargetFor('state-setup-quick_entry.png'), isNull);
    expect(previewTargetFor('sample-unknown-dark-zh.png'), isNull);
  });
}
