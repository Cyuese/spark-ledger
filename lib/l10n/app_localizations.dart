import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
  ];

  /// 应用名称
  ///
  /// In zh, this message translates to:
  /// **'Veri Fin'**
  String get appTitle;

  /// 底部导航:首页
  ///
  /// In zh, this message translates to:
  /// **'首页'**
  String get tabHome;

  /// 底部导航:资产
  ///
  /// In zh, this message translates to:
  /// **'资产'**
  String get tabAssets;

  /// 底部导航:看板
  ///
  /// In zh, this message translates to:
  /// **'看板'**
  String get tabReports;

  /// 底部导航:我的
  ///
  /// In zh, this message translates to:
  /// **'我的'**
  String get tabProfile;

  /// 快速记账入口(FAB 提示与数字键盘标题)
  ///
  /// In zh, this message translates to:
  /// **'快速记账'**
  String get quickEntry;

  /// 首页按返回键时的退出提示
  ///
  /// In zh, this message translates to:
  /// **'再次返回退出程序'**
  String get pressBackAgainToExit;

  /// 设置页:语言入口标题
  ///
  /// In zh, this message translates to:
  /// **'语言'**
  String get settingsLanguage;

  /// 语言选择弹窗标题
  ///
  /// In zh, this message translates to:
  /// **'选择语言'**
  String get languagePickerTitle;

  /// 语言选项:跟随系统语言
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get localeFollowSystem;

  /// No description provided for @commonCancel.
  ///
  /// In zh, this message translates to:
  /// **'取消'**
  String get commonCancel;

  /// No description provided for @commonConfirm.
  ///
  /// In zh, this message translates to:
  /// **'确认'**
  String get commonConfirm;

  /// No description provided for @commonDelete.
  ///
  /// In zh, this message translates to:
  /// **'删除'**
  String get commonDelete;

  /// 页头返回按钮 tooltip
  ///
  /// In zh, this message translates to:
  /// **'返回'**
  String get commonBack;

  /// 耗时任务加载对话框默认文案
  ///
  /// In zh, this message translates to:
  /// **'正在处理…'**
  String get commonProcessing;

  /// 交易行徽标:已被退款/报销冲抵
  ///
  /// In zh, this message translates to:
  /// **'已退'**
  String get badgeRefunded;

  /// 交易行徽标:标记待报销
  ///
  /// In zh, this message translates to:
  /// **'待报销'**
  String get badgeReimbursable;

  /// No description provided for @calendarTitle.
  ///
  /// In zh, this message translates to:
  /// **'日历'**
  String get calendarTitle;

  /// No description provided for @calendarPrevMonth.
  ///
  /// In zh, this message translates to:
  /// **'上个月'**
  String get calendarPrevMonth;

  /// No description provided for @calendarNextMonth.
  ///
  /// In zh, this message translates to:
  /// **'下个月'**
  String get calendarNextMonth;

  /// 日历星期表头(短)
  ///
  /// In zh, this message translates to:
  /// **'一'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In zh, this message translates to:
  /// **'二'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In zh, this message translates to:
  /// **'三'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In zh, this message translates to:
  /// **'四'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In zh, this message translates to:
  /// **'五'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In zh, this message translates to:
  /// **'六'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In zh, this message translates to:
  /// **'日'**
  String get weekdaySun;

  /// 记账表单标签行为空时的占位提示
  ///
  /// In zh, this message translates to:
  /// **'添加标签'**
  String get entryAddTags;

  /// 账户图标选择弹窗:内置图标分组名
  ///
  /// In zh, this message translates to:
  /// **'通用图标'**
  String get iconGroupGeneric;

  /// No description provided for @accountIconPickerTitle.
  ///
  /// In zh, this message translates to:
  /// **'选择账户图标'**
  String get accountIconPickerTitle;

  /// No description provided for @accountHandleTitle.
  ///
  /// In zh, this message translates to:
  /// **'处理此账户？'**
  String get accountHandleTitle;

  /// 删除有交易的账户时的确认说明
  ///
  /// In zh, this message translates to:
  /// **'账户「{name}」已有 {count} 笔相关交易。你可以隐藏账户，或删除账户并同步删除这些交易记录。'**
  String accountHandleMessage(String name, int count);

  /// No description provided for @accountHide.
  ///
  /// In zh, this message translates to:
  /// **'隐藏账户'**
  String get accountHide;

  /// No description provided for @accountDeleteWithEntries.
  ///
  /// In zh, this message translates to:
  /// **'删除账户和交易'**
  String get accountDeleteWithEntries;

  /// No description provided for @accountDeleteTitle.
  ///
  /// In zh, this message translates to:
  /// **'删除此账户？'**
  String get accountDeleteTitle;

  /// No description provided for @accountDeleteMessage.
  ///
  /// In zh, this message translates to:
  /// **'账户「{name}」删除后无法恢复。'**
  String accountDeleteMessage(String name);

  /// No description provided for @tagCreateTitle.
  ///
  /// In zh, this message translates to:
  /// **'新建标签'**
  String get tagCreateTitle;

  /// No description provided for @tagNameLabel.
  ///
  /// In zh, this message translates to:
  /// **'标签名称'**
  String get tagNameLabel;

  /// No description provided for @entryTypeExpense.
  ///
  /// In zh, this message translates to:
  /// **'支出'**
  String get entryTypeExpense;

  /// No description provided for @entryTypeIncome.
  ///
  /// In zh, this message translates to:
  /// **'收入'**
  String get entryTypeIncome;

  /// No description provided for @entryTypeTransfer.
  ///
  /// In zh, this message translates to:
  /// **'转账'**
  String get entryTypeTransfer;

  /// No description provided for @themeSystem.
  ///
  /// In zh, this message translates to:
  /// **'跟随系统'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In zh, this message translates to:
  /// **'浅色'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In zh, this message translates to:
  /// **'深色'**
  String get themeDark;

  /// No description provided for @accountTypeOnlinePayment.
  ///
  /// In zh, this message translates to:
  /// **'网络支付'**
  String get accountTypeOnlinePayment;

  /// No description provided for @accountTypeCreditCard.
  ///
  /// In zh, this message translates to:
  /// **'信用卡'**
  String get accountTypeCreditCard;

  /// No description provided for @accountTypeDebitCard.
  ///
  /// In zh, this message translates to:
  /// **'储蓄卡'**
  String get accountTypeDebitCard;

  /// No description provided for @accountTypeInvestment.
  ///
  /// In zh, this message translates to:
  /// **'投资账户'**
  String get accountTypeInvestment;

  /// No description provided for @accountTypeCash.
  ///
  /// In zh, this message translates to:
  /// **'现金'**
  String get accountTypeCash;

  /// No description provided for @assetViewGroup.
  ///
  /// In zh, this message translates to:
  /// **'分类视图'**
  String get assetViewGroup;

  /// No description provided for @assetViewType.
  ///
  /// In zh, this message translates to:
  /// **'类型视图'**
  String get assetViewType;

  /// No description provided for @assetViewToggleToType.
  ///
  /// In zh, this message translates to:
  /// **'切换为类型视图'**
  String get assetViewToggleToType;

  /// No description provided for @assetViewToggleToGroup.
  ///
  /// In zh, this message translates to:
  /// **'切换为分类视图'**
  String get assetViewToggleToGroup;

  /// No description provided for @recurringDaily.
  ///
  /// In zh, this message translates to:
  /// **'每天'**
  String get recurringDaily;

  /// No description provided for @recurringWeekly.
  ///
  /// In zh, this message translates to:
  /// **'每周'**
  String get recurringWeekly;

  /// No description provided for @recurringMonthly.
  ///
  /// In zh, this message translates to:
  /// **'每月'**
  String get recurringMonthly;

  /// No description provided for @recurringYearly.
  ///
  /// In zh, this message translates to:
  /// **'每年'**
  String get recurringYearly;

  /// No description provided for @genderUnset.
  ///
  /// In zh, this message translates to:
  /// **'不设置'**
  String get genderUnset;

  /// No description provided for @genderMale.
  ///
  /// In zh, this message translates to:
  /// **'男'**
  String get genderMale;

  /// No description provided for @genderFemale.
  ///
  /// In zh, this message translates to:
  /// **'女'**
  String get genderFemale;

  /// No description provided for @panelTrendLabel.
  ///
  /// In zh, this message translates to:
  /// **'支出走势'**
  String get panelTrendLabel;

  /// No description provided for @panelTrendDesc.
  ///
  /// In zh, this message translates to:
  /// **'按 7 天周期展示支出趋势与结余'**
  String get panelTrendDesc;

  /// No description provided for @panelRecentLabel.
  ///
  /// In zh, this message translates to:
  /// **'最近交易'**
  String get panelRecentLabel;

  /// No description provided for @panelRecentDesc.
  ///
  /// In zh, this message translates to:
  /// **'展示最近 5 条交易记录'**
  String get panelRecentDesc;

  /// No description provided for @panelBudgetLabel.
  ///
  /// In zh, this message translates to:
  /// **'月度预算'**
  String get panelBudgetLabel;

  /// No description provided for @panelBudgetDesc.
  ///
  /// In zh, this message translates to:
  /// **'本月预算进度与分类超支提醒'**
  String get panelBudgetDesc;

  /// No description provided for @panelCalendarDesc.
  ///
  /// In zh, this message translates to:
  /// **'按日历查看每天的收支情况'**
  String get panelCalendarDesc;

  /// No description provided for @panelBudgetExecutionLabel.
  ///
  /// In zh, this message translates to:
  /// **'预算执行'**
  String get panelBudgetExecutionLabel;

  /// No description provided for @panelBudgetExecutionDesc.
  ///
  /// In zh, this message translates to:
  /// **'本月预算、支出与分类预算执行情况'**
  String get panelBudgetExecutionDesc;

  /// No description provided for @panelCategoryRingLabel.
  ///
  /// In zh, this message translates to:
  /// **'分类统计'**
  String get panelCategoryRingLabel;

  /// No description provided for @panelCategoryRingDesc.
  ///
  /// In zh, this message translates to:
  /// **'本月支出分类占比环形图'**
  String get panelCategoryRingDesc;

  /// No description provided for @panelCategoryRankLabel.
  ///
  /// In zh, this message translates to:
  /// **'分类明细'**
  String get panelCategoryRankLabel;

  /// No description provided for @panelCategoryRankDesc.
  ///
  /// In zh, this message translates to:
  /// **'本月支出分类排行与占比'**
  String get panelCategoryRankDesc;

  /// No description provided for @panelTagStatsLabel.
  ///
  /// In zh, this message translates to:
  /// **'标签统计'**
  String get panelTagStatsLabel;

  /// No description provided for @panelTagStatsDesc.
  ///
  /// In zh, this message translates to:
  /// **'本月各标签的支出金额与占比'**
  String get panelTagStatsDesc;

  /// No description provided for @panelDailyTrendLabel.
  ///
  /// In zh, this message translates to:
  /// **'日趋势'**
  String get panelDailyTrendLabel;

  /// No description provided for @panelDailyTrendDesc.
  ///
  /// In zh, this message translates to:
  /// **'近 7 天每日支出趋势'**
  String get panelDailyTrendDesc;

  /// No description provided for @panelMonthlyStructureLabel.
  ///
  /// In zh, this message translates to:
  /// **'月度收支'**
  String get panelMonthlyStructureLabel;

  /// No description provided for @panelMonthlyStructureDesc.
  ///
  /// In zh, this message translates to:
  /// **'今年每月支出结构柱状图'**
  String get panelMonthlyStructureDesc;

  /// 面板管理入口:开启数量
  ///
  /// In zh, this message translates to:
  /// **'{count}个{page}面板'**
  String panelCountLabel(int count, String page);

  /// No description provided for @panelPageTitle.
  ///
  /// In zh, this message translates to:
  /// **'{page}面板'**
  String panelPageTitle(String page);

  /// No description provided for @panelSortHint.
  ///
  /// In zh, this message translates to:
  /// **'拖动手柄调整顺序'**
  String get panelSortHint;

  /// No description provided for @panelToggleHint.
  ///
  /// In zh, this message translates to:
  /// **'开关与排序'**
  String get panelToggleHint;

  /// No description provided for @panelSortDone.
  ///
  /// In zh, this message translates to:
  /// **'完成排序'**
  String get panelSortDone;

  /// No description provided for @panelSortStart.
  ///
  /// In zh, this message translates to:
  /// **'排序面板'**
  String get panelSortStart;

  /// No description provided for @panelResetTitle.
  ///
  /// In zh, this message translates to:
  /// **'恢复默认{page}面板？'**
  String panelResetTitle(String page);

  /// No description provided for @panelResetMessage.
  ///
  /// In zh, this message translates to:
  /// **'将恢复默认顺序并开启全部面板。'**
  String get panelResetMessage;

  /// No description provided for @panelResetConfirm.
  ///
  /// In zh, this message translates to:
  /// **'恢复默认'**
  String get panelResetConfirm;

  /// No description provided for @panelKeepOneMessage.
  ///
  /// In zh, this message translates to:
  /// **'至少保留一个开启的{page}面板'**
  String panelKeepOneMessage(String page);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
