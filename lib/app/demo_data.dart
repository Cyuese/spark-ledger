import 'package:flutter/material.dart';

import 'models.dart';

const List<AccountGroup> defaultAccountGroups = <AccountGroup>[];

const List<Account> defaultAccounts = <Account>[];

const UserProfile defaultUserProfile = UserProfile(
  nickname: 'Veri Fin',
  bio: '完全免费 · 数据自主',
  avatarDataUrl: '',
);

final List<LedgerBook> defaultLedgerBooks = <LedgerBook>[
  LedgerBook(
    id: defaultLedgerBookId,
    name: '日常账本',
    createdAt: DateTime(2026),
    isDefault: true,
  ),
];

const List<String> accountIconCodes = <String>[
  'wallet',
  'alipay',
  'wechat',
  'credit',
  'bank',
  'cash',
  'investment',
  'savings',
  'card',
  'folder',
];

const List<String> categoryIconCodes = <String>[
  'category',
  'dining',
  'transport',
  'shopping',
  'housing',
  'entertainment',
  'medical',
  'salary',
  'savings',
  'interest',
  'investment',
  'bonus',
  'work',
  'transfer_out',
  'transfer_in',
  'repayment',
  'adjust',
];

IconData iconForCode(String code) {
  switch (code) {
    case 'category':
      return Icons.category_outlined;
    case 'dining':
      return Icons.restaurant;
    case 'transport':
      return Icons.directions_bus;
    case 'shopping':
      return Icons.shopping_bag;
    case 'housing':
      return Icons.home_work;
    case 'entertainment':
      return Icons.movie;
    case 'medical':
      return Icons.local_hospital;
    case 'salary':
      return Icons.payments;
    case 'interest':
      return Icons.percent;
    case 'bonus':
      return Icons.military_tech;
    case 'work':
      return Icons.work;
    case 'transfer_out':
      return Icons.call_made;
    case 'transfer_in':
      return Icons.call_received;
    case 'repayment':
      return Icons.swap_horiz;
    case 'adjust':
      return Icons.tune;
    case 'alipay':
      return Icons.account_balance_wallet;
    case 'wechat':
      return Icons.chat_bubble_outline;
    case 'credit':
      return Icons.credit_card;
    case 'bank':
      return Icons.account_balance;
    case 'cash':
      return Icons.payments;
    case 'investment':
      return Icons.trending_up;
    case 'savings':
      return Icons.savings;
    case 'card':
      return Icons.payment;
    case 'folder':
      return Icons.folder_outlined;
    case 'wallet':
    default:
      return Icons.account_balance_wallet_outlined;
  }
}

String iconLabelForCode(String code) {
  switch (code) {
    case 'category':
      return '分类';
    case 'dining':
      return '餐饮';
    case 'transport':
      return '交通';
    case 'shopping':
      return '购物';
    case 'housing':
      return '居住';
    case 'entertainment':
      return '娱乐';
    case 'medical':
      return '医疗';
    case 'salary':
      return '收入';
    case 'interest':
      return '利息';
    case 'bonus':
      return '奖励';
    case 'work':
      return '工作';
    case 'transfer_out':
      return '转出';
    case 'transfer_in':
      return '转入';
    case 'repayment':
      return '还款';
    case 'adjust':
      return '调整';
    case 'alipay':
      return '支付';
    case 'wechat':
      return '微信';
    case 'credit':
      return '信用';
    case 'bank':
      return '银行';
    case 'cash':
      return '现金';
    case 'investment':
      return '投资';
    case 'savings':
      return '储蓄';
    case 'card':
      return '卡片';
    case 'folder':
      return '分组';
    case 'wallet':
    default:
      return '钱包';
  }
}

const List<Category> defaultCategories = <Category>[
  Category(
    id: 'dining',
    label: '餐饮',
    type: EntryType.expense,
    iconCode: 'dining',
  ),
  Category(
    id: 'transport',
    label: '交通',
    type: EntryType.expense,
    iconCode: 'transport',
  ),
  Category(
    id: 'shopping',
    label: '购物',
    type: EntryType.expense,
    iconCode: 'shopping',
  ),
  Category(
    id: 'housing',
    label: '居住',
    type: EntryType.expense,
    iconCode: 'housing',
  ),
  Category(
    id: 'entertainment',
    label: '娱乐',
    type: EntryType.expense,
    iconCode: 'entertainment',
  ),
  Category(
    id: 'medical',
    label: '医疗',
    type: EntryType.expense,
    iconCode: 'medical',
  ),
  Category(
    id: 'balance_adjust_expense',
    label: '余额调整',
    type: EntryType.expense,
    iconCode: 'adjust',
  ),
  Category(
    id: 'salary',
    label: '工资',
    type: EntryType.income,
    iconCode: 'salary',
  ),
  Category(
    id: 'living',
    label: '生活费',
    type: EntryType.income,
    iconCode: 'savings',
  ),
  Category(
    id: 'interest',
    label: '利息',
    type: EntryType.income,
    iconCode: 'interest',
  ),
  Category(
    id: 'investment',
    label: '投资',
    type: EntryType.income,
    iconCode: 'investment',
  ),
  Category(id: 'bonus', label: '奖金', type: EntryType.income, iconCode: 'bonus'),
  Category(
    id: 'part_time',
    label: '兼职',
    type: EntryType.income,
    iconCode: 'work',
  ),
  Category(
    id: 'balance_adjust_income',
    label: '余额调整',
    type: EntryType.income,
    iconCode: 'adjust',
  ),
  Category(
    id: 'transfer_out',
    label: '转出',
    type: EntryType.transfer,
    iconCode: 'transfer_out',
  ),
  Category(
    id: 'transfer_in',
    label: '转入',
    type: EntryType.transfer,
    iconCode: 'transfer_in',
  ),
  Category(
    id: 'repayment',
    label: '还款',
    type: EntryType.transfer,
    iconCode: 'repayment',
  ),
];

const List<Category> demoCategories = defaultCategories;

List<Category> categoriesFor(EntryType type, [List<Category>? categories]) {
  return (categories ?? defaultCategories)
      .where((category) => category.type == type)
      .toList(growable: false);
}

Category categoryById(String id, [List<Category>? categories]) {
  return categoryByIdFrom(categories ?? defaultCategories, id);
}

Category categoryByIdFrom(List<Category> categories, String id) {
  final source = categories.isEmpty ? defaultCategories : categories;
  return source.firstWhere(
    (category) => category.id == id,
    orElse: () => source.first,
  );
}

Account accountById(List<Account> accounts, String id) {
  return accounts.firstWhere(
    (account) => account.id == id,
    orElse: () => accounts.isEmpty
        ? const Account(
            id: 'missing',
            bookId: defaultLedgerBookId,
            name: '已删除账户',
            type: AccountType.cash,
            groupId: null,
            initialBalance: 0,
            iconCode: 'wallet',
            note: '',
            includeInAssets: false,
            hidden: true,
          )
        : accounts.first,
  );
}
