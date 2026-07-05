// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Veri Fin';

  @override
  String get tabHome => 'Home';

  @override
  String get tabAssets => 'Assets';

  @override
  String get tabReports => 'Reports';

  @override
  String get tabProfile => 'Me';

  @override
  String get quickEntry => 'Quick Entry';

  @override
  String get pressBackAgainToExit => 'Press back again to exit';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get languagePickerTitle => 'Select language';

  @override
  String get localeFollowSystem => 'Follow system';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonBack => 'Back';

  @override
  String get commonProcessing => 'Processing…';

  @override
  String get badgeRefunded => 'Refunded';

  @override
  String get badgeReimbursable => 'Reimbursable';

  @override
  String get calendarTitle => 'Calendar';

  @override
  String get calendarPrevMonth => 'Previous month';

  @override
  String get calendarNextMonth => 'Next month';

  @override
  String get weekdayMon => 'Mon';

  @override
  String get weekdayTue => 'Tue';

  @override
  String get weekdayWed => 'Wed';

  @override
  String get weekdayThu => 'Thu';

  @override
  String get weekdayFri => 'Fri';

  @override
  String get weekdaySat => 'Sat';

  @override
  String get weekdaySun => 'Sun';

  @override
  String get entryAddTags => 'Add tags';

  @override
  String get iconGroupGeneric => 'General icons';

  @override
  String get accountIconPickerTitle => 'Choose account icon';

  @override
  String get accountHandleTitle => 'Manage this account?';

  @override
  String accountHandleMessage(String name, int count) {
    return 'Account \"$name\" already has $count related transactions. You can hide the account, or delete it together with those transactions.';
  }

  @override
  String get accountHide => 'Hide account';

  @override
  String get accountDeleteWithEntries => 'Delete account & transactions';

  @override
  String get accountDeleteTitle => 'Delete this account?';

  @override
  String accountDeleteMessage(String name) {
    return 'Account \"$name\" cannot be restored once deleted.';
  }

  @override
  String get tagCreateTitle => 'New tag';

  @override
  String get tagNameLabel => 'Tag name';

  @override
  String get entryTypeExpense => 'Expense';

  @override
  String get entryTypeIncome => 'Income';

  @override
  String get entryTypeTransfer => 'Transfer';

  @override
  String get themeSystem => 'Follow system';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get accountTypeOnlinePayment => 'Online payment';

  @override
  String get accountTypeCreditCard => 'Credit card';

  @override
  String get accountTypeDebitCard => 'Debit card';

  @override
  String get accountTypeInvestment => 'Investment';

  @override
  String get accountTypeCash => 'Cash';

  @override
  String get assetViewGroup => 'Group view';

  @override
  String get assetViewType => 'Type view';

  @override
  String get assetViewToggleToType => 'Switch to type view';

  @override
  String get assetViewToggleToGroup => 'Switch to group view';

  @override
  String get recurringDaily => 'Daily';

  @override
  String get recurringWeekly => 'Weekly';

  @override
  String get recurringMonthly => 'Monthly';

  @override
  String get recurringYearly => 'Yearly';

  @override
  String get genderUnset => 'Not set';

  @override
  String get genderMale => 'Male';

  @override
  String get genderFemale => 'Female';

  @override
  String get panelTrendLabel => 'Spending trend';

  @override
  String get panelTrendDesc => 'Spending trend and balance in 7-day periods';

  @override
  String get panelRecentLabel => 'Recent transactions';

  @override
  String get panelRecentDesc => 'Shows the 5 most recent transactions';

  @override
  String get panelBudgetLabel => 'Monthly budget';

  @override
  String get panelBudgetDesc =>
      'This month\'s budget progress and category overspend alerts';

  @override
  String get panelCalendarDesc =>
      'View daily income and spending on a calendar';

  @override
  String get panelBudgetExecutionLabel => 'Budget execution';

  @override
  String get panelBudgetExecutionDesc =>
      'This month\'s budget, spending and category budget execution';

  @override
  String get panelCategoryRingLabel => 'Category breakdown';

  @override
  String get panelCategoryRingDesc =>
      'Donut chart of this month\'s spending by category';

  @override
  String get panelCategoryRankLabel => 'Category details';

  @override
  String get panelCategoryRankDesc =>
      'This month\'s category ranking and share';

  @override
  String get panelTagStatsLabel => 'Tag stats';

  @override
  String get panelTagStatsDesc =>
      'Spending amount and share per tag this month';

  @override
  String get panelDailyTrendLabel => 'Daily trend';

  @override
  String get panelDailyTrendDesc => 'Daily spending trend for the last 7 days';

  @override
  String get panelMonthlyStructureLabel => 'Monthly overview';

  @override
  String get panelMonthlyStructureDesc =>
      'Bar chart of monthly spending this year';

  @override
  String panelCountLabel(int count, String page) {
    return '$count $page panels';
  }

  @override
  String panelPageTitle(String page) {
    return '$page panels';
  }

  @override
  String get panelSortHint => 'Drag the handles to reorder';

  @override
  String get panelToggleHint => 'Toggle and reorder';

  @override
  String get panelSortDone => 'Done sorting';

  @override
  String get panelSortStart => 'Reorder panels';

  @override
  String panelResetTitle(String page) {
    return 'Restore default $page panels?';
  }

  @override
  String get panelResetMessage =>
      'Restores the default order and enables all panels.';

  @override
  String get panelResetConfirm => 'Restore defaults';

  @override
  String panelKeepOneMessage(String page) {
    return 'Keep at least one $page panel enabled';
  }

  @override
  String get iconLabelCategory => 'Category';

  @override
  String get iconLabelDining => 'Dining';

  @override
  String get iconLabelTransport => 'Transport';

  @override
  String get iconLabelShopping => 'Shopping';

  @override
  String get iconLabelHousing => 'Housing';

  @override
  String get iconLabelEntertainment => 'Entertainment';

  @override
  String get iconLabelMedical => 'Medical';

  @override
  String get iconLabelSalary => 'Income';

  @override
  String get iconLabelInterest => 'Interest';

  @override
  String get iconLabelBonus => 'Bonus';

  @override
  String get iconLabelWork => 'Work';

  @override
  String get iconLabelTransferOut => 'Transfer out';

  @override
  String get iconLabelTransferIn => 'Transfer in';

  @override
  String get iconLabelRepayment => 'Repayment';

  @override
  String get iconLabelAdjust => 'Adjust';

  @override
  String get iconLabelPay => 'Payment';

  @override
  String get iconLabelWechat => 'WeChat';

  @override
  String get iconLabelCredit => 'Credit';

  @override
  String get iconLabelBank => 'Bank';

  @override
  String get iconLabelCash => 'Cash';

  @override
  String get iconLabelInvestment => 'Investment';

  @override
  String get iconLabelSavings => 'Savings';

  @override
  String get iconLabelCard => 'Card';

  @override
  String get iconLabelFolder => 'Group';

  @override
  String get iconLabelWallet => 'Wallet';

  @override
  String get iconGroupCredit => 'Credit accounts';

  @override
  String get iconGroupPayment => 'Payment platforms';

  @override
  String get iconGroupBank => 'Banks';

  @override
  String get balanceAdjustNote => 'Balance adjustment';

  @override
  String get commonNone => 'None';

  @override
  String get commonDone => 'Done';

  @override
  String get homeNoEntriesTitle => 'No transactions yet';

  @override
  String get homeNoEntriesDesc =>
      'Tap the plus button to record your first entry.';

  @override
  String trendNet(String amount) {
    return 'Net $amount';
  }

  @override
  String get homeDaysTracked => 'Days tracked';

  @override
  String daysCount(int count) {
    return '$count days';
  }

  @override
  String get homeDailyAvgExpense => 'Daily average';

  @override
  String dateMonthDay(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat('MMM d', localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String monthBudgetTitle(DateTime month) {
    final intl.DateFormat monthDateFormat = intl.DateFormat.MMM(localeName);
    final String monthString = monthDateFormat.format(month);

    return '$monthString budget';
  }

  @override
  String get budgetRemaining => 'Remaining';

  @override
  String get budgetDailyRemaining => 'Daily remaining';

  @override
  String budgetTotalLabel(String amount) {
    return 'Budget $amount';
  }

  @override
  String get incomeExpenseTitle => 'Income & expense';

  @override
  String get homeNoStatsTitle => 'No data';

  @override
  String get homeNoStatsDesc => 'No records for this month.';

  @override
  String get statTypeTitle => 'Statistic type';

  @override
  String budgetCatOver(String category, String amount) {
    return '$category over by $amount';
  }

  @override
  String budgetCatUsed(String category, String percent) {
    return '$category used $percent%';
  }

  @override
  String entriesCount(int count) {
    return '$count entries';
  }

  @override
  String get categoryAll => 'All categories';

  @override
  String get tagPickerTitle => 'Select tags';

  @override
  String get coverBlueCity => 'Blue city';

  @override
  String get coverAurora => 'Aurora night';

  @override
  String get coverFinanceOffice => 'Finance office';

  @override
  String get coverDeepBlue => 'Deep blue';

  @override
  String get assetsUngrouped => 'Ungrouped';

  @override
  String get netAssets => 'Net worth';

  @override
  String get assetsActions => 'Asset actions';

  @override
  String get assetsChangeCover => 'Change card background';

  @override
  String assetsAmount(String amount) {
    return 'Assets $amount';
  }

  @override
  String liabilitiesAmount(String amount) {
    return 'Liabilities $amount';
  }

  @override
  String netAssetsAmount(String amount) {
    return 'Net worth $amount';
  }

  @override
  String monthNumber(int month) {
    return 'M$month';
  }

  @override
  String get assetsEmptyTitle => 'No accounts yet';

  @override
  String get assetsEmptyDesc =>
      'Add an account from the top right; you can then view assets by type or group here.';

  @override
  String get assetsSortHint =>
      'Drag the handles on the right to reorder sections';

  @override
  String hiddenAccountsCount(int count) {
    return '$count hidden accounts';
  }

  @override
  String get assetsCoverTitle => 'Asset card background';

  @override
  String get coverUseOnline => 'Use online image';

  @override
  String get coverEnterUrl => 'Enter image URL';

  @override
  String get coverPickLocal => 'Choose local image';

  @override
  String get coverClear => 'Clear background image';

  @override
  String get coverPickOnlineTitle => 'Choose online image';

  @override
  String get coverCustomTitle => 'Custom image';

  @override
  String get coverUrlLabel => 'Image URL';

  @override
  String get coverCropTitle => 'Crop background';

  @override
  String get coverGenerating => 'Generating background…';

  @override
  String get accountAdd => 'Add account';

  @override
  String get groupManage => 'Manage groups';

  @override
  String get sectionSort => 'Sort sections';

  @override
  String get sectionSortNeedTwo => 'Need at least 2 sections to sort';

  @override
  String get sortLabel => 'Sort';

  @override
  String get hiddenAccountsTitle => 'Hidden accounts';

  @override
  String get hiddenAccountsEmptyTitle => 'No hidden accounts';

  @override
  String get hiddenAccountsEmptyDesc => 'Hidden accounts appear here.';

  @override
  String get accountGroupsTitle => 'Account groups';

  @override
  String get groupAdd => 'New group';

  @override
  String get groupsEmptyTitle => 'No account groups yet';

  @override
  String get groupsEmptyDesc =>
      'Tap the plus at top right to create groups for organizing accounts.';

  @override
  String accountsCount(int count) {
    return '$count accounts';
  }

  @override
  String get commonRename => 'Rename';

  @override
  String get commonIcon => 'Icon';

  @override
  String get groupRenameTitle => 'Rename group';

  @override
  String get groupNameLabel => 'Group name';

  @override
  String get groupIconPickerTitle => 'Choose group icon';

  @override
  String get accountIconLabel => 'Account icon';

  @override
  String get accountSaveTooltip => 'Save account';

  @override
  String get accountTypeLabel => 'Account type';

  @override
  String get accountNameLabel => 'Account name';

  @override
  String get accountNameRequired => 'Account name is required';

  @override
  String get cardLast4Label => 'Last 4 digits';

  @override
  String get cardLast4Invalid => 'Enter 1-4 digits';

  @override
  String get accountBalanceLabel => 'Account balance';

  @override
  String get accountBalanceHint => 'Defaults to 0';

  @override
  String get accountNoteLabel => 'Account note';

  @override
  String get accountGroupLabel => 'Account group';

  @override
  String get accountTypePickerTitle => 'Choose account type';

  @override
  String get accountGroupPickerTitle => 'Choose account group';

  @override
  String get balanceAdjustTooltip => 'Adjust balance';

  @override
  String get currentBalance => 'Current balance';

  @override
  String get balanceTrend => 'Balance trend';

  @override
  String get dayShort => 'Day';

  @override
  String get monthShort => 'Month';

  @override
  String balanceAmount(String amount) {
    return 'Balance $amount';
  }

  @override
  String get viewReport => 'View report';

  @override
  String get addEntryTooltip => 'Add entry';

  @override
  String get noEntriesTitle => 'No transactions';

  @override
  String get accountNoEntriesDesc => 'This account has no transactions yet.';

  @override
  String accountEntriesTitle(String name) {
    return '$name transactions';
  }

  @override
  String get allEntries => 'All transactions';

  @override
  String get includeInAssets => 'Count in assets';

  @override
  String get commonType => 'Type';

  @override
  String get commonName => 'Name';

  @override
  String get notSet => 'Not set';

  @override
  String get clearOption => 'Don\'t set';

  @override
  String get statementDay => 'Statement day';

  @override
  String get dueDay => 'Due day';

  @override
  String monthlyDayLabel(int day) {
    return 'Day $day of each month';
  }

  @override
  String get commonCurrency => 'Currency';

  @override
  String get currencyCny => 'CNY';

  @override
  String get commonNote => 'Note';

  @override
  String get commonNoneShort => 'None';

  @override
  String get commonGroup => 'Group';

  @override
  String get accountDelete => 'Delete account';

  @override
  String get deletableLabel => 'Deletable';

  @override
  String get hasEntriesLabel => 'Has transactions';

  @override
  String get balanceEditConfirmTitle => 'Confirm balance change?';

  @override
  String balanceEditConfirmMessage(String name, String amount) {
    return 'This sets the balance of \"$name\" to $amount.';
  }

  @override
  String get balanceEditRecord => 'Record as entry';

  @override
  String get balanceEditRecordDesc =>
      'Creates a balance-adjustment entry; if unchecked, the initial balance is changed directly without affecting statistics.';

  @override
  String get accountNameEditTitle => 'Edit account name';

  @override
  String get cardLast4EditTitle => 'Edit last 4 digits';

  @override
  String get pickDueDay => 'Choose due day';

  @override
  String get pickStatementDay => 'Choose statement day';

  @override
  String get accountNoteEditTitle => 'Edit account note';

  @override
  String get accountReportTitle => 'Account report';

  @override
  String get thisMonth => 'This month';

  @override
  String get dueToday => 'due today';

  @override
  String dueInDays(int days) {
    return '$days days left';
  }

  @override
  String monthlyRepayLine(int day) {
    return 'Repay on day $day of each month';
  }
}
