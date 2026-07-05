// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'Veri Fin';

  @override
  String get tabHome => '首页';

  @override
  String get tabAssets => '资产';

  @override
  String get tabReports => '看板';

  @override
  String get tabProfile => '我的';

  @override
  String get quickEntry => '快速记账';

  @override
  String get pressBackAgainToExit => '再次返回退出程序';

  @override
  String get settingsLanguage => '语言';

  @override
  String get languagePickerTitle => '选择语言';

  @override
  String get localeFollowSystem => '跟随系统';

  @override
  String get commonCancel => '取消';

  @override
  String get commonConfirm => '确认';

  @override
  String get commonDelete => '删除';

  @override
  String get commonBack => '返回';

  @override
  String get commonProcessing => '正在处理…';

  @override
  String get badgeRefunded => '已退';

  @override
  String get badgeReimbursable => '待报销';

  @override
  String get calendarTitle => '日历';

  @override
  String get calendarPrevMonth => '上个月';

  @override
  String get calendarNextMonth => '下个月';

  @override
  String get weekdayMon => '一';

  @override
  String get weekdayTue => '二';

  @override
  String get weekdayWed => '三';

  @override
  String get weekdayThu => '四';

  @override
  String get weekdayFri => '五';

  @override
  String get weekdaySat => '六';

  @override
  String get weekdaySun => '日';

  @override
  String get entryAddTags => '添加标签';

  @override
  String get iconGroupGeneric => '通用图标';

  @override
  String get accountIconPickerTitle => '选择账户图标';

  @override
  String get accountHandleTitle => '处理此账户？';

  @override
  String accountHandleMessage(String name, int count) {
    return '账户「$name」已有 $count 笔相关交易。你可以隐藏账户，或删除账户并同步删除这些交易记录。';
  }

  @override
  String get accountHide => '隐藏账户';

  @override
  String get accountDeleteWithEntries => '删除账户和交易';

  @override
  String get accountDeleteTitle => '删除此账户？';

  @override
  String accountDeleteMessage(String name) {
    return '账户「$name」删除后无法恢复。';
  }

  @override
  String get tagCreateTitle => '新建标签';

  @override
  String get tagNameLabel => '标签名称';

  @override
  String get entryTypeExpense => '支出';

  @override
  String get entryTypeIncome => '收入';

  @override
  String get entryTypeTransfer => '转账';

  @override
  String get themeSystem => '跟随系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

  @override
  String get accountTypeOnlinePayment => '网络支付';

  @override
  String get accountTypeCreditCard => '信用卡';

  @override
  String get accountTypeDebitCard => '储蓄卡';

  @override
  String get accountTypeInvestment => '投资账户';

  @override
  String get accountTypeCash => '现金';

  @override
  String get assetViewGroup => '分类视图';

  @override
  String get assetViewType => '类型视图';

  @override
  String get assetViewToggleToType => '切换为类型视图';

  @override
  String get assetViewToggleToGroup => '切换为分类视图';

  @override
  String get recurringDaily => '每天';

  @override
  String get recurringWeekly => '每周';

  @override
  String get recurringMonthly => '每月';

  @override
  String get recurringYearly => '每年';

  @override
  String get genderUnset => '不设置';

  @override
  String get genderMale => '男';

  @override
  String get genderFemale => '女';

  @override
  String get panelTrendLabel => '支出走势';

  @override
  String get panelTrendDesc => '按 7 天周期展示支出趋势与结余';

  @override
  String get panelRecentLabel => '最近交易';

  @override
  String get panelRecentDesc => '展示最近 5 条交易记录';

  @override
  String get panelBudgetLabel => '月度预算';

  @override
  String get panelBudgetDesc => '本月预算进度与分类超支提醒';

  @override
  String get panelCalendarDesc => '按日历查看每天的收支情况';

  @override
  String get panelBudgetExecutionLabel => '预算执行';

  @override
  String get panelBudgetExecutionDesc => '本月预算、支出与分类预算执行情况';

  @override
  String get panelCategoryRingLabel => '分类统计';

  @override
  String get panelCategoryRingDesc => '本月支出分类占比环形图';

  @override
  String get panelCategoryRankLabel => '分类明细';

  @override
  String get panelCategoryRankDesc => '本月支出分类排行与占比';

  @override
  String get panelTagStatsLabel => '标签统计';

  @override
  String get panelTagStatsDesc => '本月各标签的支出金额与占比';

  @override
  String get panelDailyTrendLabel => '日趋势';

  @override
  String get panelDailyTrendDesc => '近 7 天每日支出趋势';

  @override
  String get panelMonthlyStructureLabel => '月度收支';

  @override
  String get panelMonthlyStructureDesc => '今年每月支出结构柱状图';

  @override
  String panelCountLabel(int count, String page) {
    return '$count个$page面板';
  }

  @override
  String panelPageTitle(String page) {
    return '$page面板';
  }

  @override
  String get panelSortHint => '拖动手柄调整顺序';

  @override
  String get panelToggleHint => '开关与排序';

  @override
  String get panelSortDone => '完成排序';

  @override
  String get panelSortStart => '排序面板';

  @override
  String panelResetTitle(String page) {
    return '恢复默认$page面板？';
  }

  @override
  String get panelResetMessage => '将恢复默认顺序并开启全部面板。';

  @override
  String get panelResetConfirm => '恢复默认';

  @override
  String panelKeepOneMessage(String page) {
    return '至少保留一个开启的$page面板';
  }

  @override
  String get iconLabelCategory => '分类';

  @override
  String get iconLabelDining => '餐饮';

  @override
  String get iconLabelTransport => '交通';

  @override
  String get iconLabelShopping => '购物';

  @override
  String get iconLabelHousing => '居住';

  @override
  String get iconLabelEntertainment => '娱乐';

  @override
  String get iconLabelMedical => '医疗';

  @override
  String get iconLabelSalary => '收入';

  @override
  String get iconLabelInterest => '利息';

  @override
  String get iconLabelBonus => '奖励';

  @override
  String get iconLabelWork => '工作';

  @override
  String get iconLabelTransferOut => '转出';

  @override
  String get iconLabelTransferIn => '转入';

  @override
  String get iconLabelRepayment => '还款';

  @override
  String get iconLabelAdjust => '调整';

  @override
  String get iconLabelPay => '支付';

  @override
  String get iconLabelWechat => '微信';

  @override
  String get iconLabelCredit => '信用';

  @override
  String get iconLabelBank => '银行';

  @override
  String get iconLabelCash => '现金';

  @override
  String get iconLabelInvestment => '投资';

  @override
  String get iconLabelSavings => '储蓄';

  @override
  String get iconLabelCard => '卡片';

  @override
  String get iconLabelFolder => '分组';

  @override
  String get iconLabelWallet => '钱包';

  @override
  String get iconGroupCredit => '信用账户';

  @override
  String get iconGroupPayment => '支付平台';

  @override
  String get iconGroupBank => '银行';

  @override
  String get balanceAdjustNote => '余额调整';

  @override
  String get commonNone => '暂无';

  @override
  String get commonDone => '完成';

  @override
  String get homeNoEntriesTitle => '还没有交易';

  @override
  String get homeNoEntriesDesc => '点击右下角加号开始第一笔记账。';

  @override
  String trendNet(String amount) {
    return '结余 $amount';
  }

  @override
  String get homeDaysTracked => '记账日';

  @override
  String daysCount(int count) {
    return '$count天';
  }

  @override
  String get homeDailyAvgExpense => '日均支出';

  @override
  String dateMonthDay(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat('M月d日', localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String monthBudgetTitle(DateTime month) {
    final intl.DateFormat monthDateFormat = intl.DateFormat('M月', localeName);
    final String monthString = monthDateFormat.format(month);

    return '$monthString预算';
  }

  @override
  String get budgetRemaining => '剩余';

  @override
  String get budgetDailyRemaining => '剩余日均';

  @override
  String budgetTotalLabel(String amount) {
    return '预算 $amount';
  }

  @override
  String get incomeExpenseTitle => '收支统计';

  @override
  String get homeNoStatsTitle => '暂无统计';

  @override
  String get homeNoStatsDesc => '当前月份没有对应记录。';

  @override
  String get statTypeTitle => '统计类型';

  @override
  String budgetCatOver(String category, String amount) {
    return '$category超出 $amount';
  }

  @override
  String budgetCatUsed(String category, String percent) {
    return '$category已用 $percent%';
  }

  @override
  String entriesCount(int count) {
    return '$count笔';
  }

  @override
  String get categoryAll => '全部分类';

  @override
  String get tagPickerTitle => '选择标签';

  @override
  String get coverBlueCity => '蓝色城市';

  @override
  String get coverAurora => '极光夜色';

  @override
  String get coverFinanceOffice => '金融办公';

  @override
  String get coverDeepBlue => '深蓝渐层';

  @override
  String get assetsUngrouped => '未分组';

  @override
  String get netAssets => '净资产';

  @override
  String get assetsActions => '资产操作';

  @override
  String get assetsChangeCover => '更换资产卡片背景';

  @override
  String assetsAmount(String amount) {
    return '资产 $amount';
  }

  @override
  String liabilitiesAmount(String amount) {
    return '负债 $amount';
  }

  @override
  String netAssetsAmount(String amount) {
    return '净资产 $amount';
  }

  @override
  String monthNumber(int month) {
    return '$month月';
  }

  @override
  String get assetsEmptyTitle => '还没有资产账户';

  @override
  String get assetsEmptyDesc => '请先点击右上角添加资产，之后可以在这里按类型或分组查看资产。';

  @override
  String get assetsSortHint => '拖动右侧手柄调整分组顺序';

  @override
  String hiddenAccountsCount(int count) {
    return '$count个隐藏账户';
  }

  @override
  String get assetsCoverTitle => '资产卡片背景';

  @override
  String get coverUseOnline => '使用线上图片';

  @override
  String get coverEnterUrl => '输入图片链接';

  @override
  String get coverPickLocal => '选择本地图片';

  @override
  String get coverClear => '清除背景图片';

  @override
  String get coverPickOnlineTitle => '选择线上图片';

  @override
  String get coverCustomTitle => '自定义图片';

  @override
  String get coverUrlLabel => '图片链接';

  @override
  String get coverCropTitle => '裁剪资产背景';

  @override
  String get coverGenerating => '正在生成背景图…';

  @override
  String get accountAdd => '添加账户';

  @override
  String get groupManage => '管理分组';

  @override
  String get sectionSort => '排序分组';

  @override
  String get sectionSortNeedTwo => '至少有 2 个分组才能排序';

  @override
  String get sortLabel => '排序';

  @override
  String get hiddenAccountsTitle => '隐藏账户';

  @override
  String get hiddenAccountsEmptyTitle => '暂无隐藏账户';

  @override
  String get hiddenAccountsEmptyDesc => '隐藏账户会在这里集中展示。';

  @override
  String get accountGroupsTitle => '账户分组';

  @override
  String get groupAdd => '新增分组';

  @override
  String get groupsEmptyTitle => '还没有账户分组';

  @override
  String get groupsEmptyDesc => '点击右上角加号创建分组，用来整理不同账户。';

  @override
  String accountsCount(int count) {
    return '$count个账户';
  }

  @override
  String get commonRename => '重命名';

  @override
  String get commonIcon => '图标';

  @override
  String get groupRenameTitle => '重命名分组';

  @override
  String get groupNameLabel => '分组名称';

  @override
  String get groupIconPickerTitle => '选择分组图标';

  @override
  String get accountIconLabel => '账户图标';

  @override
  String get accountSaveTooltip => '保存账户';

  @override
  String get accountTypeLabel => '账户类型';

  @override
  String get accountNameLabel => '账户名称';

  @override
  String get accountNameRequired => '账户名称必填';

  @override
  String get cardLast4Label => '卡号后四位';

  @override
  String get cardLast4Invalid => '请输入 1-4 位数字';

  @override
  String get accountBalanceLabel => '账户余额';

  @override
  String get accountBalanceHint => '不填默认为 0';

  @override
  String get accountNoteLabel => '账户备注';

  @override
  String get accountGroupLabel => '账户分组';

  @override
  String get accountTypePickerTitle => '选择账户类型';

  @override
  String get accountGroupPickerTitle => '选择账户分组';

  @override
  String get balanceAdjustTooltip => '调整余额';

  @override
  String get currentBalance => '当前余额';

  @override
  String get balanceTrend => '余额趋势';

  @override
  String get dayShort => '日';

  @override
  String get monthShort => '月';

  @override
  String balanceAmount(String amount) {
    return '余额 $amount';
  }

  @override
  String get viewReport => '查看报告';

  @override
  String get addEntryTooltip => '记一笔';

  @override
  String get noEntriesTitle => '暂无交易';

  @override
  String get accountNoEntriesDesc => '该账户还没有交易记录。';

  @override
  String accountEntriesTitle(String name) {
    return '$name交易';
  }

  @override
  String get allEntries => '所有交易';

  @override
  String get includeInAssets => '计入资产';

  @override
  String get commonType => '类型';

  @override
  String get commonName => '名称';

  @override
  String get notSet => '未设置';

  @override
  String get clearOption => '不设置';

  @override
  String get statementDay => '账单日';

  @override
  String get dueDay => '还款日';

  @override
  String monthlyDayLabel(int day) {
    return '每月 $day 日';
  }

  @override
  String get commonCurrency => '货币';

  @override
  String get currencyCny => '人民币';

  @override
  String get commonNote => '备注';

  @override
  String get commonNoneShort => '无';

  @override
  String get commonGroup => '分组';

  @override
  String get accountDelete => '删除账户';

  @override
  String get deletableLabel => '可删除';

  @override
  String get hasEntriesLabel => '已有交易';

  @override
  String get balanceEditConfirmTitle => '是否确认修改余额？';

  @override
  String balanceEditConfirmMessage(String name, String amount) {
    return '将把「$name」的余额调整为 $amount。';
  }

  @override
  String get balanceEditRecord => '计入收支';

  @override
  String get balanceEditRecordDesc => '生成一笔余额调整交易；不勾选则直接修改账户初始余额，不影响收支统计。';

  @override
  String get accountNameEditTitle => '编辑账户名称';

  @override
  String get cardLast4EditTitle => '编辑卡号后四位';

  @override
  String get pickDueDay => '选择还款日';

  @override
  String get pickStatementDay => '选择账单日';

  @override
  String get accountNoteEditTitle => '编辑账户备注';

  @override
  String get accountReportTitle => '账户报告';

  @override
  String get thisMonth => '本月';

  @override
  String get dueToday => '就是今天';

  @override
  String dueInDays(int days) {
    return '还有 $days 天';
  }

  @override
  String monthlyRepayLine(int day) {
    return '每月 $day 日还款';
  }
}
