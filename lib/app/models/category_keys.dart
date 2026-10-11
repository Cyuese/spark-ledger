/// 分类的**语义键**：id 一律随机生成、不承载含义，需要「认出某条分类是什么」的地方
/// 一律比较这个键，而不是解析 id。
///
/// 只有两类分类有键：
/// - **默认分类**（餐饮/交通/…/转出/转入/还款）：每个账本播种一份，键与种子定义一致；
/// - **系统分类**（余额调整，支出/收入各一条）——用户可改名换图标但不能移动/合并/删除，
///   是「调整余额」写交易的落点；
/// - **未分类**兜底（导入缺失分类与载入自愈共用），键形如 `uncategorized_expense`。
///
/// 用户自建的分类没有键（`null`）。键在同一账本内唯一，跨账本天然重复（每个账本各一份），
/// 所以键的唯一索引带 `book_id`。
///
/// 本文件不依赖任何其它模块（数据层的迁移也会用它判定「旧 id 是否为已知语义键」）。
library;

/// 系统分类（余额调整）的语义键。
const String balanceAdjustExpenseKey = 'balance_adjust_expense';
const String balanceAdjustIncomeKey = 'balance_adjust_income';

/// 默认分类的语义键，顺序与种子定义一致。
const List<String> defaultCategoryKeys = <String>[
  'dining',
  'transport',
  'shopping',
  'housing',
  'entertainment',
  'medical',
  balanceAdjustExpenseKey,
  'salary',
  'living',
  'interest',
  'investment',
  'bonus',
  'part_time',
  balanceAdjustIncomeKey,
  'transfer_out',
  'transfer_in',
  'repayment',
];

/// 「未分类」兜底键的前缀。
const String uncategorizedKeyPrefix = 'uncategorized_';

/// 由「条目类型的存储值」拼出该类型的「未分类」键。
String uncategorizedKeyForStorageValue(String storageValue) =>
    '$uncategorizedKeyPrefix$storageValue';

/// 该键是否为有约定的分类键（默认分类或未分类兜底）。
bool isKnownCategoryKey(String key) =>
    defaultCategoryKeys.contains(key) || key.startsWith(uncategorizedKeyPrefix);
