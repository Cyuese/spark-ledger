import 'package:flutter/material.dart';

enum EntryType {
  expense,
  income,
  transfer;

  String get label {
    switch (this) {
      case EntryType.expense:
        return '支出';
      case EntryType.income:
        return '收入';
      case EntryType.transfer:
        return '转账';
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
    }
  }

  static EntryType fromStorage(String value) {
    return EntryType.values.firstWhere(
      (type) => type.storageValue == value,
      orElse: () => EntryType.expense,
    );
  }
}

enum ThemePreference {
  system,
  light,
  dark;

  String get label {
    switch (this) {
      case ThemePreference.system:
        return '跟随系统';
      case ThemePreference.light:
        return '浅色';
      case ThemePreference.dark:
        return '深色';
    }
  }

  ThemeMode get themeMode {
    switch (this) {
      case ThemePreference.system:
        return ThemeMode.system;
      case ThemePreference.light:
        return ThemeMode.light;
      case ThemePreference.dark:
        return ThemeMode.dark;
    }
  }

  static ThemePreference fromStorage(String? value) {
    return ThemePreference.values.firstWhere(
      (preference) => preference.name == value,
      orElse: () => ThemePreference.system,
    );
  }
}

enum AccountType {
  onlinePayment,
  creditCard,
  debitCard,
  investment,
  cash;

  String get label {
    switch (this) {
      case AccountType.onlinePayment:
        return '网络支付';
      case AccountType.creditCard:
        return '信用卡';
      case AccountType.debitCard:
        return '储蓄卡';
      case AccountType.investment:
        return '投资账户';
      case AccountType.cash:
        return '现金';
    }
  }

  static AccountType fromStorage(String? value) {
    return AccountType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => AccountType.onlinePayment,
    );
  }
}

enum AssetAccountViewMode {
  group,
  type;

  String get label {
    switch (this) {
      case AssetAccountViewMode.group:
        return '分类视图';
      case AssetAccountViewMode.type:
        return '类型视图';
    }
  }

  String get toggleLabel {
    switch (this) {
      case AssetAccountViewMode.group:
        return '切换为类型视图';
      case AssetAccountViewMode.type:
        return '切换为分类视图';
    }
  }

  static AssetAccountViewMode fromStorage(String? value) {
    return AssetAccountViewMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => AssetAccountViewMode.group,
    );
  }
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
    );
  }
}

const String defaultLedgerBookId = 'default';

class LedgerBook {
  const LedgerBook({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.isDefault,
  });

  final String id;
  final String name;
  final DateTime createdAt;
  final bool isDefault;

  LedgerBook copyWith({String? id, String? name, DateTime? createdAt}) {
    return LedgerBook(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      isDefault: isDefault,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'name': name,
      'createdAt': createdAt.toIso8601String(),
      'isDefault': isDefault,
    };
  }

  static LedgerBook fromJson(Map<String, Object?> json) {
    final id = json['id'] as String? ?? defaultLedgerBookId;
    return LedgerBook(
      id: id,
      name: json['name'] as String? ?? '日常账本',
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      isDefault: json['isDefault'] as bool? ?? id == defaultLedgerBookId,
    );
  }
}

class Account {
  const Account({
    required this.id,
    required this.bookId,
    required this.name,
    required this.type,
    required this.groupId,
    required this.initialBalance,
    required this.iconCode,
    required this.note,
    required this.includeInAssets,
    required this.hidden,
  });

  final String id;
  final String bookId;
  final String name;
  final AccountType type;
  final String? groupId;
  final double initialBalance;
  final String iconCode;
  final String note;
  final bool includeInAssets;
  final bool hidden;

  Account copyWith({
    String? id,
    String? bookId,
    String? name,
    AccountType? type,
    String? groupId,
    double? initialBalance,
    String? iconCode,
    String? note,
    bool? includeInAssets,
    bool? hidden,
  }) {
    return Account(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      name: name ?? this.name,
      type: type ?? this.type,
      groupId: groupId ?? this.groupId,
      initialBalance: initialBalance ?? this.initialBalance,
      iconCode: iconCode ?? this.iconCode,
      note: note ?? this.note,
      includeInAssets: includeInAssets ?? this.includeInAssets,
      hidden: hidden ?? this.hidden,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'bookId': bookId,
      'name': name,
      'type': type.name,
      'groupId': groupId,
      'initialBalance': initialBalance,
      'iconCode': iconCode,
      'note': note,
      'includeInAssets': includeInAssets,
      'hidden': hidden,
    };
  }

  static Account fromJson(Map<String, Object?> json) {
    return Account(
      id: json['id'] as String,
      bookId: json['bookId'] as String? ?? defaultLedgerBookId,
      name: json['name'] as String? ?? '未命名账户',
      type: AccountType.fromStorage(json['type'] as String?),
      groupId: json['groupId'] as String?,
      initialBalance: (json['initialBalance'] as num? ?? 0).toDouble(),
      iconCode: json['iconCode'] as String? ?? 'wallet',
      note: json['note'] as String? ?? '',
      includeInAssets: json['includeInAssets'] as bool? ?? true,
      hidden: json['hidden'] as bool? ?? false,
    );
  }
}

class AccountGroup {
  const AccountGroup({
    required this.id,
    required this.bookId,
    required this.name,
    required this.iconCode,
    required this.sortOrder,
  });

  final String id;
  final String bookId;
  final String name;
  final String iconCode;
  final int sortOrder;

  AccountGroup copyWith({
    String? id,
    String? bookId,
    String? name,
    String? iconCode,
    int? sortOrder,
  }) {
    return AccountGroup(
      id: id ?? this.id,
      bookId: bookId ?? this.bookId,
      name: name ?? this.name,
      iconCode: iconCode ?? this.iconCode,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'bookId': bookId,
      'name': name,
      'iconCode': iconCode,
      'sortOrder': sortOrder,
    };
  }

  static AccountGroup fromJson(Map<String, Object?> json) {
    return AccountGroup(
      id: json['id'] as String,
      bookId: json['bookId'] as String? ?? defaultLedgerBookId,
      name: json['name'] as String? ?? '未命名分组',
      iconCode: json['iconCode'] as String? ?? 'folder',
      sortOrder: json['sortOrder'] as int? ?? 0,
    );
  }
}

class UserProfile {
  const UserProfile({
    required this.nickname,
    required this.bio,
    required this.avatarDataUrl,
  });

  final String nickname;
  final String bio;
  final String avatarDataUrl;

  UserProfile copyWith({String? nickname, String? bio, String? avatarDataUrl}) {
    return UserProfile(
      nickname: nickname ?? this.nickname,
      bio: bio ?? this.bio,
      avatarDataUrl: avatarDataUrl ?? this.avatarDataUrl,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'nickname': nickname,
      'bio': bio,
      'avatarDataUrl': avatarDataUrl,
    };
  }

  static UserProfile fromJson(Map<String, Object?> json) {
    return UserProfile(
      nickname: json['nickname'] as String? ?? 'Veri Fin',
      bio: json['bio'] as String? ?? '完全免费 · 数据自主',
      avatarDataUrl: json['avatarDataUrl'] as String? ?? '',
    );
  }
}

class Category {
  const Category({
    required this.id,
    required this.label,
    required this.type,
    required this.iconCode,
  });

  final String id;
  final String label;
  final EntryType type;
  final String iconCode;

  Category copyWith({
    String? id,
    String? label,
    EntryType? type,
    String? iconCode,
  }) {
    return Category(
      id: id ?? this.id,
      label: label ?? this.label,
      type: type ?? this.type,
      iconCode: iconCode ?? this.iconCode,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'id': id,
      'label': label,
      'type': type.storageValue,
      'iconCode': iconCode,
    };
  }

  static Category fromJson(Map<String, Object?> json) {
    return Category(
      id: json['id'] as String,
      label: json['label'] as String? ?? '未命名分类',
      type: EntryType.fromStorage(json['type'] as String? ?? 'expense'),
      iconCode: json['iconCode'] as String? ?? 'category',
    );
  }
}
