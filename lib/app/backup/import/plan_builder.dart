import '../../category_tree.dart';
import '../../ledger_math.dart';
import '../../models.dart';
import 'raw_import.dart';

/// 导入计划：待新增的交易，以及为匹配名称需要新建的账户/分类/标签，和逐行错误。
class ImportPlan {
  const ImportPlan({
    required this.entries,
    required this.newAccounts,
    required this.newCategories,
    required this.errors,
    this.newTags = const <Tag>[],
    this.standaloneAccountIds = const <String>{},
  });

  final List<LedgerEntry> entries;
  final List<Account> newAccounts;
  final List<Category> newCategories;

  /// 为匹配交易里的标签名需要新建的标签（去重后）。标签全局共享、不分账本。
  final List<Tag> newTags;
  final List<ImportRowError> errors;

  /// 待新建账户中「即使没有交易引用也要创建」的 id 集合。默认空——普通导入的账户都由
  /// 交易派生、被排除后不应留下空账户；仅 Tally 这类携带账户余额/类型的来源，会把源账本
  /// 里的资产账户（含零余额、无流水的账户）标记为独立账户一并落库。
  final Set<String> standaloneAccountIds;

  int get importedCount => entries.length;
  int get errorCount => errors.length;
  bool get isEmpty => entries.isEmpty && errors.isEmpty;
}

/// 所有来源的**唯一共享落库计划生成器**：把各平台 parser 产出的强类型 [ParsedImport]
/// 变成 [ImportPlan]——按名建/复用账户、还原分类父子层级、标签去重、构造 [LedgerEntry]，
/// 并把 parser 收集的逐行错误透传。纯函数：不修改传入集合，id 由 [now] 与记录序派生
/// （保证同输入可复现）。
///
/// 「不同软件解析逻辑各自独立」的边界只到 parser 为止——账户/分类/标签解析是通用领域
/// 逻辑，只应有这一份实现（复制成每平台一份必然漂移、是 bug 温床）。
ImportPlan buildImportPlanFromRecords({
  required ParsedImport parsed,
  required String bookId,
  required List<Account> existingAccounts,
  required List<Category> existingCategories,
  required DateTime now,
  List<Tag> existingTags = const <Tag>[],
}) {
  final workingAccounts = List<Account>.from(existingAccounts);
  final workingCategories = List<Category>.from(existingCategories);
  final workingTags = List<Tag>.from(existingTags);
  final newAccounts = <Account>[];
  final newCategories = <Category>[];
  final newTags = <Tag>[];
  final entries = <LedgerEntry>[];
  final errors = <ImportRowError>[...parsed.errors];
  var idCounter = 0;

  String nextId(String prefix) {
    idCounter++;
    return '${prefix}_${now.microsecondsSinceEpoch}_$idCounter';
  }

  String resolveAccount(String name) {
    final match = workingAccounts.firstWhere(
      (account) => account.name == name,
      orElse: () => const Account(
        id: '',
        bookId: '',
        name: '',
        type: AccountType.cash,
        groupId: null,
        initialBalance: 0,
        iconCode: 'wallet',
        note: '',
        includeInAssets: true,
        hidden: false,
      ),
    );
    if (match.id.isNotEmpty) {
      return match.id;
    }
    final account = Account(
      id: nextId('account'),
      bookId: bookId,
      name: name,
      type: AccountType.cash,
      groupId: null,
      initialBalance: 0,
      iconCode: 'wallet',
      note: '',
      includeInAssets: true,
      hidden: false,
    );
    workingAccounts.add(account);
    newAccounts.add(account);
    return account.id;
  }

  // 解析/新建单个分类；[parentId] 限定层级（顶级传 null）。名称按归一化比较（容忍
  // 大小写/首尾空白/全半角差异），且**同一父级下**同名才复用——顶级与子级同名互不误合，
  // 与唯一索引 (label,type,IFNULL(parent_id,'')) 对齐。
  String resolveCategory(String name, EntryType type, {String? parentId}) {
    if (name.isEmpty) {
      return '';
    }
    final normalized = normalizedCategoryLabel(name);
    final match = workingCategories.firstWhere(
      (category) =>
          category.type == type &&
          category.parentId == parentId &&
          normalizedCategoryLabel(category.label) == normalized,
      orElse: () => const Category(
        id: '',
        label: '',
        type: EntryType.expense,
        iconCode: '',
      ),
    );
    if (match.id.isNotEmpty) {
      return match.id;
    }
    final category = Category(
      id: nextId('category'),
      label: name,
      type: type,
      iconCode: 'category',
      parentId: parentId,
    );
    workingCategories.add(category);
    newCategories.add(category);
    return category.id;
  }

  // 解析分类层级：一级 [parentLabel] + 二级 [subLabel]。两者都在时建/复用「父 → 子」
  // 层级、返回子分类 id；只有一个时按顶级分类处理。
  String resolveCategoryHierarchy(
    String parentLabel,
    String subLabel,
    EntryType type,
  ) {
    if (subLabel.isEmpty) {
      return resolveCategory(parentLabel, type);
    }
    if (parentLabel.isEmpty) {
      return resolveCategory(subLabel, type);
    }
    final parentId = resolveCategory(parentLabel, type);
    return resolveCategory(subLabel, type, parentId: parentId);
  }

  // 解析标签名列表：按归一化名去空去重，复用现有同名标签、否则新建，返回标签 id 列表。
  List<String> resolveTags(List<String> labels) {
    if (labels.isEmpty) {
      return const <String>[];
    }
    final ids = <String>[];
    final seen = <String>{};
    for (final label in labels) {
      if (label.isEmpty) {
        continue;
      }
      final normalized = normalizedCategoryLabel(label);
      if (!seen.add(normalized)) {
        continue;
      }
      final match = workingTags.firstWhere(
        (tag) => normalizedCategoryLabel(tag.label) == normalized,
        orElse: () => const Tag(id: '', label: ''),
      );
      if (match.id.isNotEmpty) {
        ids.add(match.id);
        continue;
      }
      final tag = Tag(id: nextId('tag'), label: label);
      workingTags.add(tag);
      newTags.add(tag);
      ids.add(tag.id);
    }
    return ids;
  }

  for (final record in parsed.records) {
    final line = record.sourceLine ?? 0;
    final tagIds = resolveTags(record.tags);

    if (record.type == EntryType.transfer) {
      final fromName = record.account;
      final toName = record.toAccount;
      if (fromName.isEmpty && toName.isEmpty) {
        errors.add(ImportRowError(line: line, message: '转账缺少账户'));
        continue;
      }
      if (fromName.isNotEmpty && toName == fromName) {
        errors.add(ImportRowError(line: line, message: '转出与转入账户不能相同'));
        continue;
      }
      // 单边为空（如源账本转入/转出到未跟踪账户）仍按转账记，空的一端不计余额。
      final fromId = fromName.isEmpty ? '' : resolveAccount(fromName);
      final toId = toName.isEmpty ? null : resolveAccount(toName);
      entries.add(
        LedgerEntry(
          id: nextId('entry'),
          bookId: bookId,
          type: EntryType.transfer,
          amount: record.amount,
          categoryId: '',
          accountId: fromId,
          toAccountId: toId,
          note: record.note,
          occurredAt: record.date,
          fee: record.fee,
          tagIds: tagIds,
        ),
      );
      continue;
    }

    final accountId = record.account.isEmpty
        ? ''
        : resolveAccount(record.account);
    final categoryId = resolveCategoryHierarchy(
      record.category,
      record.subCategory,
      record.type,
    );
    // 支出可带退款（部分/全额）：钳制在 [0, 金额]，使净额=金额−退款、退款回原账户
    // （与 App 内退款冲抵语义一致）。收入行忽略。
    final refunded = record.type == EntryType.expense
        ? record.refunded.clamp(0, record.amount).toDouble()
        : 0.0;
    entries.add(
      LedgerEntry(
        id: nextId('entry'),
        bookId: bookId,
        type: record.type,
        amount: record.amount,
        categoryId: categoryId,
        accountId: accountId,
        toAccountId: null,
        note: record.note,
        occurredAt: record.date,
        refundedAmount: refunded,
        tagIds: tagIds,
      ),
    );
  }

  // 携带余额/类型的账户元数据（Tally）：回推初始余额对齐来源、补建无流水账户。
  final standalone = _applyAccountMetadata(
    accounts: parsed.accounts,
    entries: entries,
    newAccounts: newAccounts,
    existingAccounts: existingAccounts,
    bookId: bookId,
    now: now,
  );

  return ImportPlan(
    entries: entries,
    newAccounts: newAccounts,
    newCategories: newCategories,
    newTags: newTags,
    errors: errors,
    standaloneAccountIds: standalone,
  );
}

/// 用账户元数据（目前仅 Tally 提供）修正 [newAccounts]：让每个源账户导入后的**显示
/// 余额**等于来源存的当前余额，并补建没有流水的账户。就地修改 [newAccounts]，返回需要
/// 「即使无交易引用也落库」的账户 id 集合。
///
/// Veri Fin 账户显示余额 = `initialBalance + Σ 交易增量`，故对**本次导入新建**的账户回推
/// `initialBalance = 目标余额 − Σ增量`；没有任何交易引用的资产则直接以目标余额新建。
/// 已存在的同名账户不改动（避免覆盖用户既有数据）。
Set<String> _applyAccountMetadata({
  required List<RawImportAccount> accounts,
  required List<LedgerEntry> entries,
  required List<Account> newAccounts,
  required List<Account> existingAccounts,
  required String bookId,
  required DateTime now,
}) {
  if (accounts.isEmpty) {
    return const <String>{};
  }

  // 各账户在本次导入交易中的余额增量合计（按最终账户 id 聚合）。
  final deltaByAccount = <String, double>{};
  for (final entry in entries) {
    for (final id in <String?>[entry.accountId, entry.toAccountId]) {
      if (id != null && id.isNotEmpty) {
        deltaByAccount[id] =
            (deltaByAccount[id] ?? 0) + accountDeltaForEntry(entry, id);
      }
    }
  }

  final standalone = <String>{};
  var counter = 0;
  for (final asset in accounts) {
    final newIndex = newAccounts.indexWhere((a) => a.name == asset.name);
    if (newIndex != -1) {
      // 本次导入新建的账户：回推初始余额，使显示余额对齐来源；标记为独立账户。
      final account = newAccounts[newIndex];
      final delta = deltaByAccount[account.id] ?? 0;
      newAccounts[newIndex] = account.copyWith(
        initialBalance: asset.signedBalance - delta,
        includeInAssets: asset.includeInAssets,
        type: asset.type,
      );
      standalone.add(account.id);
      continue;
    }
    // 已存在的同名账户：不改动（尊重用户既有数据）。
    if (existingAccounts.any((a) => a.name == asset.name)) {
      continue;
    }
    // 没有任何流水的资产（零余额钱包、借出/负债对象等）：直接以当前余额新建。
    counter++;
    final id = 'stdacct_${now.microsecondsSinceEpoch}_$counter';
    newAccounts.add(
      Account(
        id: id,
        bookId: bookId,
        name: asset.name,
        type: asset.type,
        groupId: null,
        initialBalance: asset.signedBalance,
        iconCode: 'wallet',
        note: '',
        includeInAssets: asset.includeInAssets,
        hidden: false,
      ),
    );
    standalone.add(id);
  }
  return standalone;
}
