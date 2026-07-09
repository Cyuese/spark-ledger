import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import 'account_icon_assets.dart';
import 'models.dart';

const List<AccountGroup> defaultAccountGroups = <AccountGroup>[];

const List<Account> defaultAccounts = <Account>[];

const UserProfile defaultUserProfile = UserProfile(
  nickname: 'Veri Fin',
  bio: '完全免费 · 数据自主',
  avatarDataUrl: '',
);

/// 按语言取默认个人资料（首启动/初始化播种用；中文为兼容基准）。
UserProfile defaultUserProfileFor({required bool english}) => english
    ? const UserProfile(
        nickname: 'Veri Fin',
        bio: 'Completely free · Own your data',
        avatarDataUrl: '',
      )
    : defaultUserProfile;

final List<LedgerBook> defaultLedgerBooks = <LedgerBook>[
  LedgerBook(
    id: defaultLedgerBookId,
    name: '日常账本',
    createdAt: DateTime(2026),
    isDefault: true,
  ),
];

/// 按语言取默认账本（账本名是数据，播种后随用户编辑）。
List<LedgerBook> defaultLedgerBooksFor({required bool english}) => <LedgerBook>[
  LedgerBook(
    id: defaultLedgerBookId,
    name: english ? 'Daily Ledger' : '日常账本',
    createdAt: DateTime(2026),
    isDefault: true,
  ),
];

const List<String> accountIconCodes = <String>[
  'wallet',
  'alipay',
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
  'coffee',
  'drink',
  'snack',
  'cake',
  'grocery',
  'shopping',
  'clothing',
  'beauty',
  'haircut',
  'transport',
  'car',
  'taxi',
  'fuel',
  'parking',
  'train',
  'flight',
  'bike',
  'housing',
  'rent',
  'utilities',
  'water',
  'phone',
  'internet',
  'repair',
  'furniture',
  'laundry',
  'entertainment',
  'game',
  'music',
  'sports',
  'book',
  'education',
  'travel',
  'hotel',
  'medical',
  'medicine',
  'pet',
  'baby',
  'family',
  'love',
  'gift',
  'redpacket',
  'charity',
  'electronics',
  'subscription',
  'work',
  'salary',
  'bonus',
  'savings',
  'interest',
  'investment',
  'insurance',
  'tax',
  'refund',
  'repayment',
  'transfer_out',
  'transfer_in',
  'star',
  'adjust',
];

/// emoji 分类图标的存储前缀：`emoji:🍜`。以此与内置图标 code 区分。
const String emojiIconPrefix = 'emoji:';

/// 该图标 code 是否为 emoji 自定义图标。
bool isEmojiIconCode(String code) => code.startsWith(emojiIconPrefix);

/// 取出 emoji 图标的字符（非 emoji code 原样返回）。
String emojiOfIconCode(String code) =>
    isEmojiIconCode(code) ? code.substring(emojiIconPrefix.length) : code;

/// 把一个 emoji 字符封装为可存储的图标 code。
String emojiIconCode(String emoji) => '$emojiIconPrefix$emoji';

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
    // ---- 扩充分类图标（与 categoryIconCodes 对应）----
    case 'coffee':
      return Icons.local_cafe;
    case 'grocery':
      return Icons.local_grocery_store;
    case 'snack':
      return Icons.icecream;
    case 'drink':
      return Icons.local_bar;
    case 'cake':
      return Icons.cake;
    case 'car':
      return Icons.directions_car;
    case 'taxi':
      return Icons.local_taxi;
    case 'fuel':
      return Icons.local_gas_station;
    case 'train':
      return Icons.train;
    case 'flight':
      return Icons.flight;
    case 'parking':
      return Icons.local_parking;
    case 'bike':
      return Icons.pedal_bike;
    case 'rent':
      return Icons.vpn_key;
    case 'utilities':
      return Icons.bolt;
    case 'water':
      return Icons.water_drop;
    case 'phone':
      return Icons.smartphone;
    case 'internet':
      return Icons.wifi;
    case 'repair':
      return Icons.build;
    case 'furniture':
      return Icons.chair;
    case 'laundry':
      return Icons.local_laundry_service;
    case 'clothing':
      return Icons.checkroom;
    case 'beauty':
      return Icons.spa;
    case 'haircut':
      return Icons.content_cut;
    case 'sports':
      return Icons.fitness_center;
    case 'game':
      return Icons.sports_esports;
    case 'music':
      return Icons.music_note;
    case 'book':
      return Icons.menu_book;
    case 'education':
      return Icons.school;
    case 'travel':
      return Icons.luggage;
    case 'hotel':
      return Icons.hotel;
    case 'pet':
      return Icons.pets;
    case 'baby':
      return Icons.child_friendly;
    case 'gift':
      return Icons.card_giftcard;
    case 'redpacket':
      return Icons.redeem;
    case 'medicine':
      return Icons.medication;
    case 'electronics':
      return Icons.devices;
    case 'subscription':
      return Icons.subscriptions;
    case 'tax':
      return Icons.receipt_long;
    case 'insurance':
      return Icons.verified_user;
    case 'charity':
      return Icons.volunteer_activism;
    case 'refund':
      return Icons.replay;
    case 'love':
      return Icons.favorite;
    case 'family':
      return Icons.family_restroom;
    case 'star':
      return Icons.star;
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

String iconLabelForCode(AppLocalizations l10n, String code) {
  final assetIcon = accountAssetIconByCode(code);
  if (assetIcon != null) {
    // 品牌/银行图标名是专有名词，不随语言切换。
    return assetIcon.label;
  }

  switch (code) {
    case 'category':
      return l10n.iconLabelCategory;
    case 'dining':
      return l10n.iconLabelDining;
    case 'transport':
      return l10n.iconLabelTransport;
    case 'shopping':
      return l10n.iconLabelShopping;
    case 'housing':
      return l10n.iconLabelHousing;
    case 'entertainment':
      return l10n.iconLabelEntertainment;
    case 'medical':
      return l10n.iconLabelMedical;
    case 'salary':
      return l10n.iconLabelSalary;
    case 'interest':
      return l10n.iconLabelInterest;
    case 'bonus':
      return l10n.iconLabelBonus;
    case 'work':
      return l10n.iconLabelWork;
    case 'transfer_out':
      return l10n.iconLabelTransferOut;
    case 'transfer_in':
      return l10n.iconLabelTransferIn;
    case 'repayment':
      return l10n.iconLabelRepayment;
    case 'adjust':
      return l10n.iconLabelAdjust;
    case 'alipay':
      return l10n.iconLabelPay;
    case 'wechat':
      return l10n.iconLabelWechat;
    case 'credit':
      return l10n.iconLabelCredit;
    case 'bank':
      return l10n.iconLabelBank;
    case 'cash':
      return l10n.iconLabelCash;
    case 'investment':
      return l10n.iconLabelInvestment;
    case 'savings':
      return l10n.iconLabelSavings;
    case 'card':
      return l10n.iconLabelCard;
    case 'folder':
      return l10n.iconLabelFolder;
    case 'wallet':
    default:
      return l10n.iconLabelWallet;
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

/// 英文种子分类：id/图标与中文版一一对应，仅名称不同。
const List<Category> _defaultCategoriesEn = <Category>[
  Category(
    id: 'dining',
    label: 'Dining',
    type: EntryType.expense,
    iconCode: 'dining',
  ),
  Category(
    id: 'transport',
    label: 'Transport',
    type: EntryType.expense,
    iconCode: 'transport',
  ),
  Category(
    id: 'shopping',
    label: 'Shopping',
    type: EntryType.expense,
    iconCode: 'shopping',
  ),
  Category(
    id: 'housing',
    label: 'Housing',
    type: EntryType.expense,
    iconCode: 'housing',
  ),
  Category(
    id: 'entertainment',
    label: 'Entertainment',
    type: EntryType.expense,
    iconCode: 'entertainment',
  ),
  Category(
    id: 'medical',
    label: 'Medical',
    type: EntryType.expense,
    iconCode: 'medical',
  ),
  Category(
    id: 'balance_adjust_expense',
    label: 'Balance adjustment',
    type: EntryType.expense,
    iconCode: 'adjust',
  ),
  Category(
    id: 'salary',
    label: 'Salary',
    type: EntryType.income,
    iconCode: 'salary',
  ),
  Category(
    id: 'living',
    label: 'Allowance',
    type: EntryType.income,
    iconCode: 'savings',
  ),
  Category(
    id: 'interest',
    label: 'Interest',
    type: EntryType.income,
    iconCode: 'interest',
  ),
  Category(
    id: 'investment',
    label: 'Investment',
    type: EntryType.income,
    iconCode: 'investment',
  ),
  Category(
    id: 'bonus',
    label: 'Bonus',
    type: EntryType.income,
    iconCode: 'bonus',
  ),
  Category(
    id: 'part_time',
    label: 'Part-time',
    type: EntryType.income,
    iconCode: 'work',
  ),
  Category(
    id: 'balance_adjust_income',
    label: 'Balance adjustment',
    type: EntryType.income,
    iconCode: 'adjust',
  ),
  Category(
    id: 'transfer_out',
    label: 'Transfer out',
    type: EntryType.transfer,
    iconCode: 'transfer_out',
  ),
  Category(
    id: 'transfer_in',
    label: 'Transfer in',
    type: EntryType.transfer,
    iconCode: 'transfer_in',
  ),
  Category(
    id: 'repayment',
    label: 'Repayment',
    type: EntryType.transfer,
    iconCode: 'repayment',
  ),
];

/// 按语言取默认分类（首启动/初始化播种用；分类名是数据，播种后随用户编辑）。
List<Category> defaultCategoriesFor({required bool english}) =>
    english ? _defaultCategoriesEn : defaultCategories;

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

/// 交易账户显示名：空 id 表示「无账户」（只记金额、不计入任何账户余额）。
/// 展示层用它替代直接 [accountById]——后者对空/未知 id 会回退到首个账户而误显示。
String accountDisplayName(List<Account> accounts, String id, String noneLabel) {
  return id.isEmpty ? noneLabel : accountById(accounts, id).name;
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
