/// 分类模型：邻接表多级树（parentId），树形纯函数在 lib/app/category_tree.dart。
library;

import 'ledger_entry.dart';

class Category {
  const Category({
    required this.id,
    required this.label,
    required this.type,
    required this.iconCode,
    this.parentId,
  });

  final String id;
  final String label;
  final EntryType type;
  final String iconCode;

  /// 父分类 id；`null` 表示顶级分类。子分类与父分类的 [type] 必须一致。
  /// 支持任意层级树形结构（多级分类）。
  final String? parentId;

  /// 是否为顶级分类。
  bool get isRoot => parentId == null;

  /// 规范化父分类 id：空串归一为 null（顶级）。JSON 与 SQLite 两条反序列化
  /// 路径共用，防止「parentId=''」被当成指向空串 id 的父分类而变成孤儿。
  static String? normalizeParentId(String? raw) =>
      (raw != null && raw.isEmpty) ? null : raw;

  Category copyWith({
    String? id,
    String? label,
    EntryType? type,
    String? iconCode,
    // 使用哨兵区分「未传入」与「显式置空」，以便把子分类移动到顶级。
    Object? parentId = _copyWithSentinel,
  }) {
    return Category(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      iconCode: iconCode ?? this.iconCode,
      parentId: identical(parentId, _copyWithSentinel)
          ? this.parentId
          : parentId as String?,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'label': label,
      'type': type.storageValue,
      'iconCode': iconCode,
      if (parentId != null) 'parentId': parentId,
    };
  }

  static Category fromJson(Map<String, Object?> json) {
    return Category(
      id: json['id'] as String,
      label: json['label'] as String? ?? '未命名分类',
      type: EntryType.fromStorage(json['type'] as String? ?? 'expense'),
      iconCode: json['iconCode'] as String? ?? 'category',
      parentId: normalizeParentId(json['parentId'] as String?),
    );
  }
}

const Object _copyWithSentinel = Object();

/// 「未分类」兜底分类的固定 id（按类型各一）。导入缺失分类的兜底（plan_builder）与
/// 载入自愈（`_healCategoryData`）共用此约定——固定 id 保证两条路径幂等落到同一条分类，
/// 重复导入 / 反复自愈都复用而不再生。
String uncategorizedCategoryId(EntryType type) =>
    'uncategorized_${type.storageValue}';

/// [id] 是否为某类型「未分类」的固定 id。
bool isUncategorizedCategoryId(String id) =>
    EntryType.values.any((type) => uncategorizedCategoryId(type) == id);

/// 构造「未分类」分类。[english] 与种子数据同规则：按首启动语言取文案，播种后属
/// 用户数据、不随语言切换。
Category buildUncategorizedCategory(EntryType type, {required bool english}) =>
    Category(
      id: uncategorizedCategoryId(type),
      label: english ? 'Uncategorized' : '未分类',
      type: type,
      iconCode: 'category',
    );
