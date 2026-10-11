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

/// 一条默认分类的定义：语义键 + 展示文案。分类 id 一律随机生成、不承载语义，
/// 所以「这是什么分类」只认 [key]（见 lib/app/models/category_keys.dart）。
class CategorySeed {
  const CategorySeed({
    required this.key,
    required this.label,
    required this.type,
    required this.iconCode,
  });

  final String key;
  final String label;
  final EntryType type;
  final String iconCode;

  /// 实例化到某个账本下；[id] 由调用方生成（随机、全局唯一）。
  Category build({required String id, required String bookId}) => Category(
    id: id,
    bookId: bookId,
    key: key,
    label: label,
    type: type,
    iconCode: iconCode,
  );
}

/// 默认分类：每个新建账本播种一份。系统分类（余额调整）也是默认集的一员，
/// 每个账本各有一条。
const List<CategorySeed> defaultCategorySeeds = <CategorySeed>[
  CategorySeed(
    key: 'dining',
    label: '餐饮',
    type: EntryType.expense,
    iconCode: 'dining',
  ),
  CategorySeed(
    key: 'transport',
    label: '交通',
    type: EntryType.expense,
    iconCode: 'transport',
  ),
  CategorySeed(
    key: 'shopping',
    label: '购物',
    type: EntryType.expense,
    iconCode: 'shopping',
  ),
  CategorySeed(
    key: 'housing',
    label: '居住',
    type: EntryType.expense,
    iconCode: 'housing',
  ),
  CategorySeed(
    key: 'entertainment',
    label: '娱乐',
    type: EntryType.expense,
    iconCode: 'entertainment',
  ),
  CategorySeed(
    key: 'medical',
    label: '医疗',
    type: EntryType.expense,
    iconCode: 'medical',
  ),
  CategorySeed(
    key: balanceAdjustExpenseKey,
    label: '余额调整',
    type: EntryType.expense,
    iconCode: 'adjust',
  ),
  CategorySeed(
    key: 'salary',
    label: '工资',
    type: EntryType.income,
    iconCode: 'salary',
  ),
  CategorySeed(
    key: 'living',
    label: '生活费',
    type: EntryType.income,
    iconCode: 'savings',
  ),
  CategorySeed(
    key: 'interest',
    label: '利息',
    type: EntryType.income,
    iconCode: 'interest',
  ),
  CategorySeed(
    key: 'investment',
    label: '投资',
    type: EntryType.income,
    iconCode: 'investment',
  ),
  CategorySeed(
    key: 'bonus',
    label: '奖金',
    type: EntryType.income,
    iconCode: 'bonus',
  ),
  CategorySeed(
    key: 'part_time',
    label: '兼职',
    type: EntryType.income,
    iconCode: 'work',
  ),
  CategorySeed(
    key: balanceAdjustIncomeKey,
    label: '余额调整',
    type: EntryType.income,
    iconCode: 'adjust',
  ),
  CategorySeed(
    key: 'transfer_out',
    label: '转出',
    type: EntryType.transfer,
    iconCode: 'transfer_out',
  ),
  CategorySeed(
    key: 'transfer_in',
    label: '转入',
    type: EntryType.transfer,
    iconCode: 'transfer_in',
  ),
  CategorySeed(
    key: 'repayment',
    label: '还款',
    type: EntryType.transfer,
    iconCode: 'repayment',
  ),
];

/// 英文种子分类：键/图标与中文版一一对应，仅名称不同。
const List<CategorySeed> _defaultCategorySeedsEn = <CategorySeed>[
  CategorySeed(
    key: 'dining',
    label: 'Dining',
    type: EntryType.expense,
    iconCode: 'dining',
  ),
  CategorySeed(
    key: 'transport',
    label: 'Transport',
    type: EntryType.expense,
    iconCode: 'transport',
  ),
  CategorySeed(
    key: 'shopping',
    label: 'Shopping',
    type: EntryType.expense,
    iconCode: 'shopping',
  ),
  CategorySeed(
    key: 'housing',
    label: 'Housing',
    type: EntryType.expense,
    iconCode: 'housing',
  ),
  CategorySeed(
    key: 'entertainment',
    label: 'Entertainment',
    type: EntryType.expense,
    iconCode: 'entertainment',
  ),
  CategorySeed(
    key: 'medical',
    label: 'Medical',
    type: EntryType.expense,
    iconCode: 'medical',
  ),
  CategorySeed(
    key: balanceAdjustExpenseKey,
    label: 'Balance adjustment',
    type: EntryType.expense,
    iconCode: 'adjust',
  ),
  CategorySeed(
    key: 'salary',
    label: 'Salary',
    type: EntryType.income,
    iconCode: 'salary',
  ),
  CategorySeed(
    key: 'living',
    label: 'Allowance',
    type: EntryType.income,
    iconCode: 'savings',
  ),
  CategorySeed(
    key: 'interest',
    label: 'Interest',
    type: EntryType.income,
    iconCode: 'interest',
  ),
  CategorySeed(
    key: 'investment',
    label: 'Investment',
    type: EntryType.income,
    iconCode: 'investment',
  ),
  CategorySeed(
    key: 'bonus',
    label: 'Bonus',
    type: EntryType.income,
    iconCode: 'bonus',
  ),
  CategorySeed(
    key: 'part_time',
    label: 'Part-time',
    type: EntryType.income,
    iconCode: 'work',
  ),
  CategorySeed(
    key: balanceAdjustIncomeKey,
    label: 'Balance adjustment',
    type: EntryType.income,
    iconCode: 'adjust',
  ),
  CategorySeed(
    key: 'transfer_out',
    label: 'Transfer out',
    type: EntryType.transfer,
    iconCode: 'transfer_out',
  ),
  CategorySeed(
    key: 'transfer_in',
    label: 'Transfer in',
    type: EntryType.transfer,
    iconCode: 'transfer_in',
  ),
  CategorySeed(
    key: 'repayment',
    label: 'Repayment',
    type: EntryType.transfer,
    iconCode: 'repayment',
  ),
];

/// 按语言取默认分类的种子定义。
List<CategorySeed> categorySeedsFor({required bool english}) =>
    english ? _defaultCategorySeedsEn : defaultCategorySeeds;

/// 给**还没有任何分类**的账本补一份默认分类，返回新列表（首启动、新建账本、
/// 导入缺分类的备份与载入自愈共用同一入口，避免到处手写「分类为空才播种」）。
/// [nextId] 由调用方提供，保证新分类的 id 与其它实体同源地随机生成。
List<Category> withSeededBookCategories(
  List<Category> categories, {
  required Iterable<String> bookIds,
  required bool english,
  required String Function() nextId,
}) {
  final result = List<Category>.of(categories);
  final booksWithCategories = <String>{
    for (final category in result) category.bookId,
  };
  for (final bookId in bookIds) {
    if (!booksWithCategories.add(bookId)) {
      continue;
    }
    for (final seed in categorySeedsFor(english: english)) {
      result.add(seed.build(id: nextId(), bookId: bookId));
    }
  }
  return result;
}
