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
}
