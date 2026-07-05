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
}
