/// 交易域模型：条目类型、交易、周期记账规则、图片附件与标签。
library;

import '../../l10n/app_localizations.dart';

import 'ledger_book.dart';

enum EntryType {
  expense,
  income,
  transfer,

  /// 退款：挂在某笔原支出（[LedgerEntry.refundOf]）上的独立条目，把钱退回某账户。
  /// 类比转账——不计入收支统计、只影响账户余额（仅「已到账」`settledAt != null` 时）；
  /// 并通过缓存 [LedgerEntry.refundedAmount] 冲减原支出净额。不能在普通记账页手动选择，
  /// 只能从「原支出 → 添加退款」创建。
  refund;

  String label(AppLocalizations l10n) {
    switch (this) {
      case EntryType.expense:
        return l10n.entryTypeExpense;
      case EntryType.income:
        return l10n.entryTypeIncome;
      case EntryType.transfer:
        return l10n.entryTypeTransfer;
      case EntryType.refund:
        return l10n.entryTypeRefund;
    }
  }

  String get storageValue {
    switch (this) {
      case EntryType.expense:
        return 'expense';
      case EntryType.income:
        return 'income';
      case EntryType.transfer:
        return 'transfer';
      case EntryType.refund:
        return 'refund';
    }
  }

  static EntryType fromStorage(String value) {
    return EntryType.values.firstWhere(
      (type) => type.storageValue == value,
      orElse: () => EntryType.expense,
    );
  }

  /// 用户可在记账 / 编辑 / 统计界面直接选择的类型（不含 [refund]——退款只能从
  /// 「原支出 → 添加退款」创建，不作为普通可选类型）。
  static const List<EntryType> userSelectable = <EntryType>[
    EntryType.expense,
    EntryType.income,
    EntryType.transfer,
  ];
}

class LedgerEntry {
  const LedgerEntry({
    required this.id,
    required this.bookId,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    this.toAccountId,
    required this.note,
    required this.occurredAt,
    this.tagIds = const <String>[],
    this.fee = 0,
    this.reimbursable = false,
    this.refundedAmount = 0,
    this.refundOf,
    this.settledAt,
  });

  final String id;
  final String bookId;
  final EntryType type;
  final double amount;
  final String categoryId;
  final String accountId;
  final String? toAccountId;
  final String note;
  final DateTime occurredAt;

  /// 该交易关联的标签 id 列表（多对多，可为空）。
  final List<String> tagIds;

  /// 转账手续费（仅 [EntryType.transfer] 有意义），由转出账户承担；
  /// 转出账户余额额外减少该金额，转入账户不变。
  final double fee;

  /// 是否标记为「待报销」（仅支出有意义）。仅作标记，不影响金额；
  /// 报销/退款到账通过关联的退款条目（[EntryType.refund]）冲抵原交易。
  final bool reimbursable;

  /// 已被退款 / 报销回款冲抵的金额（仅支出有意义）——**派生缓存**，
  /// 恒等于「挂在本支出上的·已到账·退款条目金额之和」，由 controller 的
  /// `_syncRefundData()` 在载入 / 导入 / 退款增删改时重算并落库，从不独立写入。
  /// 只驱动 **统计口径的净额**（[netAmount]）；**账户余额不读它**——余额是
  /// 「支出扣全额 + 退款条目给到账账户加」，故支持退款到不同账户。
  final double refundedAmount;

  /// 退款条目专用：指向被退的原支出 `id`（仅 [EntryType.refund] 非空）。
  final String? refundOf;

  /// 退款条目专用：**到账日期**；`null` = 待到账（pending）。
  /// 待到账退款不进余额 / 净额 / 收支统计，只进「待退款」清单；`occurredAt` 复用为
  /// **发起日期**。仅 [EntryType.refund] 有意义。
  final DateTime? settledAt;

  /// 是否为「待到账」退款（已申请、钱还没回来）。
  bool get isPendingRefund => type == EntryType.refund && settledAt == null;

  /// 是否为「已到账」退款（真正影响余额 / 净额）。
  bool get isSettledRefund => type == EntryType.refund && settledAt != null;

  /// 净支出额（原金额减去已退款/报销回款）。非支出返回原金额。
  /// 净额钳制在 [0, amount]：编辑时把金额改到低于已退款额、或损坏备份导入越界值时，
  /// 净额不会变负（否则支出会被 signedAmount 当成收入、账户余额虚增）。
  double get netAmount {
    if (type != EntryType.expense) return amount;
    if (amount <= 0) return 0; // 异常/损坏数据兜底，避免 clamp 上界小于下界
    return (amount - refundedAmount).clamp(0.0, amount);
  }

  LedgerEntry copyWith({
    String? id,
    String? bookId,
    EntryType? type,
    double? amount,
    String? categoryId,
    String? accountId,
    String? toAccountId,
    bool clearToAccountId = false,
    String? note,
    DateTime? occurredAt,
    List<String>? tagIds,
    double? fee,
    bool? reimbursable,
    double? refundedAmount,
    String? refundOf,
    bool clearRefundOf = false,
    DateTime? settledAt,
    bool clearSettledAt = false,
  }) {
    return LedgerEntry(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: clearToAccountId ? null : toAccountId ?? this.toAccountId,
      note: note ?? this.note,
      occurredAt: occurredAt ?? this.occurredAt,
      tagIds: tagIds ?? this.tagIds,
      fee: fee ?? this.fee,
      reimbursable: reimbursable ?? this.reimbursable,
      refundedAmount: refundedAmount ?? this.refundedAmount,
      refundOf: clearRefundOf ? null : refundOf ?? this.refundOf,
      settledAt: clearSettledAt ? null : settledAt ?? this.settledAt,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'bookId': bookId,
      'type': type.storageValue,
      'amount': amount,
      'categoryId': categoryId,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'note': note,
      'occurredAt': occurredAt.toIso8601String(),
      if (tagIds.isNotEmpty) 'tagIds': tagIds,
      if (fee != 0) 'fee': fee,
      if (reimbursable) 'reimbursable': true,
      if (refundedAmount != 0) 'refundedAmount': refundedAmount,
      if (refundOf != null) 'refundOf': refundOf,
      if (settledAt != null) 'settledAt': settledAt!.toIso8601String(),
    };
  }

  static LedgerEntry fromJson(Map<String, Object?> json) {
    return LedgerEntry(
      id: json['id'] as String,
      bookId: json['bookId'] as String? ?? defaultLedgerBookId,
      type: EntryType.fromStorage(json['type'] as String? ?? 'expense'),
      amount: (json['amount'] as num).toDouble(),
      categoryId: json['categoryId'] as String? ?? 'dining',
      accountId: json['accountId'] as String? ?? 'alipay',
      toAccountId: json['toAccountId'] as String?,
      note: json['note'] as String? ?? '',
      occurredAt:
          DateTime.tryParse(json['occurredAt'] as String? ?? '') ??
          DateTime.now(),
      tagIds: _stringList(json['tagIds']),
      fee: (json['fee'] as num?)?.toDouble() ?? 0,
      reimbursable: json['reimbursable'] as bool? ?? false,
      refundedAmount: (json['refundedAmount'] as num?)?.toDouble() ?? 0,
      refundOf: json['refundOf'] as String?,
      settledAt: DateTime.tryParse(json['settledAt'] as String? ?? ''),
    );
  }
}

List<String> _stringList(Object? value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList(growable: false);
  }
  return const <String>[];
}

/// 周期记账频率。
enum RecurringFrequency {
  daily('daily'),
  weekly('weekly'),
  monthly('monthly'),
  yearly('yearly');

  const RecurringFrequency(this.storageValue);

  final String storageValue;

  String label(AppLocalizations l10n) {
    switch (this) {
      case RecurringFrequency.daily:
        return l10n.recurringDaily;
      case RecurringFrequency.weekly:
        return l10n.recurringWeekly;
      case RecurringFrequency.monthly:
        return l10n.recurringMonthly;
      case RecurringFrequency.yearly:
        return l10n.recurringYearly;
    }
  }

  static RecurringFrequency fromStorage(String? value) {
    return RecurringFrequency.values.firstWhere(
      (f) => f.storageValue == value,
      orElse: () => RecurringFrequency.monthly,
    );
  }
}

/// 周期记账规则：按频率自动补记交易（如房租、工资）。规则本身带 [bookId]，
/// 生成的交易落入同一账本；[nextRunDate] 为下一次应生成的日期。
class RecurringRule {
  const RecurringRule({
    required this.id,
    required this.bookId,
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    this.toAccountId,
    required this.note,
    required this.frequency,
    required this.startDate,
    required this.nextRunDate,
    this.active = true,
  });

  final String id;
  final String bookId;
  final EntryType type;
  final double amount;
  final String categoryId;
  final String accountId;
  final String? toAccountId;
  final String note;
  final RecurringFrequency frequency;
  final DateTime startDate;
  final DateTime nextRunDate;
  final bool active;

  RecurringRule copyWith({
    String? note,
    double? amount,
    String? categoryId,
    String? accountId,
    String? toAccountId,
    bool clearToAccountId = false,
    EntryType? type,
    RecurringFrequency? frequency,
    DateTime? startDate,
    DateTime? nextRunDate,
    bool? active,
  }) {
    return RecurringRule(
      id: id,
      bookId: bookId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      categoryId: categoryId ?? this.categoryId,
      accountId: accountId ?? this.accountId,
      toAccountId: clearToAccountId ? null : toAccountId ?? this.toAccountId,
      note: note ?? this.note,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      nextRunDate: nextRunDate ?? this.nextRunDate,
      active: active ?? this.active,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'bookId': bookId,
      'type': type.storageValue,
      'amount': amount,
      'categoryId': categoryId,
      'accountId': accountId,
      'toAccountId': toAccountId,
      'note': note,
      'frequency': frequency.storageValue,
      'startDate': startDate.toIso8601String(),
      'nextRunDate': nextRunDate.toIso8601String(),
      'active': active,
    };
  }

  static RecurringRule fromJson(Map<String, Object?> json) {
    final now = DateTime.now();
    return RecurringRule(
      id: json['id'] as String,
      bookId: json['bookId'] as String? ?? defaultLedgerBookId,
      type: EntryType.fromStorage(json['type'] as String? ?? 'expense'),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      categoryId: json['categoryId'] as String? ?? 'dining',
      accountId: json['accountId'] as String? ?? '',
      toAccountId: json['toAccountId'] as String?,
      note: json['note'] as String? ?? '',
      frequency: RecurringFrequency.fromStorage(json['frequency'] as String?),
      startDate: DateTime.tryParse(json['startDate'] as String? ?? '') ?? now,
      nextRunDate:
          DateTime.tryParse(json['nextRunDate'] as String? ?? '') ?? now,
      active: json['active'] as bool? ?? true,
    );
  }
}

/// 交易的图片附件（如票据）。以压缩后的 JPEG data URL 存储在独立表中，
/// 不放进 entries 表，避免整表覆盖式写入放大；数据落在应用私有的 SQLite 内。
class Attachment {
  const Attachment({
    required this.id,
    required this.entryId,
    required this.dataUrl,
  });

  final String id;
  final String entryId;

  /// `data:image/jpeg;base64,...` 形式的图片，移动端用内存图片渲染。
  final String dataUrl;

  Attachment copyWith({String? id, String? entryId, String? dataUrl}) {
    return Attachment(
      id: id ?? this.id,
      entryId: entryId ?? this.entryId,
      dataUrl: dataUrl ?? this.dataUrl,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{'id': id, 'entryId': entryId, 'dataUrl': dataUrl};
  }

  static Attachment fromJson(Map<String, Object?> json) {
    return Attachment(
      id: json['id'] as String,
      entryId: json['entryId'] as String? ?? '',
      dataUrl: json['dataUrl'] as String? ?? '',
    );
  }
}

/// 标签：与交易多对多关联，用于跨分类的横向归类与统计。
class Tag {
  const Tag({required this.id, required this.label});

  final String id;
  final String label;

  Tag copyWith({String? id, String? label}) {
    return Tag(id: id ?? this.id, label: label ?? this.label);
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{'id': id, 'label': label};
  }

  static Tag fromJson(Map<String, Object?> json) {
    return Tag(
      id: json['id'] as String,
      label: json['label'] as String? ?? '未命名标签',
    );
  }
}
