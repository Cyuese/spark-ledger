import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/category_tree.dart';
import 'package:verifin/app/models.dart';

Category _cat(String id, {String? parent, EntryType type = EntryType.expense}) {
  return Category(
    id: id,
    label: id,
    type: type,
    iconCode: 'category',
    parentId: parent,
  );
}

void main() {
  // 树：
  //   dining
  //     coffee
  //       latte
  //     tea
  //   transport
  //   salary(income)
  final all = <Category>[
    _cat('dining'),
    _cat('coffee', parent: 'dining'),
    _cat('latte', parent: 'coffee'),
    _cat('tea', parent: 'dining'),
    _cat('transport'),
    _cat('salary', type: EntryType.income),
  ];

  test('rootCategories 只返回指定类型的顶级分类', () {
    expect(
      rootCategories(all, EntryType.expense).map((c) => c.id).toList(),
      <String>['dining', 'transport'],
    );
    expect(
      rootCategories(all, EntryType.income).map((c) => c.id).toList(),
      <String>['salary'],
    );
  });

  test('childrenOf 返回直接子分类', () {
    expect(childrenOf(all, 'dining').map((c) => c.id).toList(), <String>[
      'coffee',
      'tea',
    ]);
    expect(childrenOf(all, 'tea'), isEmpty);
    expect(hasChildren(all, 'dining'), isTrue);
    expect(hasChildren(all, 'latte'), isFalse);
  });

  test('ancestorIds 由近到远，rootIdOf 返回顶级', () {
    expect(ancestorIds(all, 'latte'), <String>['coffee', 'dining']);
    expect(ancestorIds(all, 'dining'), isEmpty);
    expect(rootIdOf(all, 'latte'), 'dining');
    expect(rootIdOf(all, 'dining'), 'dining');
    expect(rootIdOf(all, 'unknown'), 'unknown');
  });

  test('descendantIds 前序遍历所有后代', () {
    expect(descendantIds(all, 'dining'), <String>['coffee', 'latte', 'tea']);
    expect(descendantIds(all, 'tea'), isEmpty);
  });

  test('isDescendantOf 用于环检测', () {
    expect(isDescendantOf(all, 'latte', 'dining'), isTrue);
    expect(isDescendantOf(all, 'latte', 'coffee'), isTrue);
    expect(isDescendantOf(all, 'dining', 'latte'), isFalse);
    expect(isDescendantOf(all, 'transport', 'dining'), isFalse);
  });

  test('depthOf 计算层级深度', () {
    expect(depthOf(all, 'dining'), 0);
    expect(depthOf(all, 'coffee'), 1);
    expect(depthOf(all, 'latte'), 2);
  });

  test('pathLabel 拼接完整路径', () {
    expect(pathLabel(all, 'latte'), 'dining / coffee / latte');
    expect(pathLabel(all, 'dining'), 'dining');
    expect(pathLabel(all, 'unknown'), '');
  });

  test('flattenTree 前序展开并携带深度', () {
    final flat = flattenTree(all, EntryType.expense);
    expect(flat.map((n) => '${n.category.id}@${n.depth}').toList(), <String>[
      'dining@0',
      'coffee@1',
      'latte@2',
      'tea@1',
      'transport@0',
    ]);
  });

  test('数据成环时遍历不死循环', () {
    final cyclic = <Category>[_cat('a', parent: 'b'), _cat('b', parent: 'a')];
    expect(ancestorIds(cyclic, 'a'), <String>['b']);
    expect(descendantIds(cyclic, 'a'), <String>['b']);
    expect(flattenTree(cyclic, EntryType.expense), isEmpty);
  });
}
