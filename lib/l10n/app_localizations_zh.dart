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
}
