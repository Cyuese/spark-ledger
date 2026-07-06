import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/category_suggest.dart';
import 'package:verifin/app/models.dart';

LedgerEntry _e({
  required EntryType type,
  required String categoryId,
  required String note,
  double amount = 30,
  int hour = 12,
  List<String> tagIds = const <String>[],
}) {
  return LedgerEntry(
    id: 'e-$categoryId-$note-$hour-$amount-${tagIds.join()}',
    bookId: 'default',
    type: type,
    amount: amount,
    categoryId: categoryId,
    accountId: 'cash',
    note: note,
    occurredAt: DateTime(2026, 7, 5, hour, 0),
    tagIds: tagIds,
  );
}

const _expenseIds = <String>{'dining', 'transport', 'coffee', 'grocery'};
const _incomeIds = <String>{'salary', 'redpacket', 'interest'};

EntrySuggestion _suggest({
  required List<LedgerEntry> history,
  String note = '',
  required double amount,
  int hour = 12,
  EntryType? forcedType,
}) {
  return suggestEntry(
    history: history,
    expenseCategoryIds: _expenseIds,
    incomeCategoryIds: _incomeIds,
    note: note,
    amount: amount,
    hour: hour,
    forcedType: forcedType,
  );
}

void main() {
  group('suggestEntry', () {
    test('exact amount carries type, category, tags and note', () {
      final history = <LedgerEntry>[
        _e(
          type: EntryType.expense,
          categoryId: 'coffee',
          note: '水',
          amount: 2.8,
          tagIds: <String>['tag-drink'],
        ),
      ];
      // 再次输入 2.8：应带出支出 + 咖啡分类 + 标签 + 备注「水」。
      final s = _suggest(history: history, amount: 2.8);
      expect(s.type, EntryType.expense);
      expect(s.categoryId, 'coffee');
      expect(s.tagIds, <String>['tag-drink']);
      expect(s.note, '水');
    });

    test('tiny amount recorded as income is inferred as income', () {
      final history = <LedgerEntry>[
        _e(
          type: EntryType.income,
          categoryId: 'redpacket',
          note: '红包',
          amount: 0.01,
        ),
      ];
      final s = _suggest(history: history, amount: 0.01);
      expect(s.type, EntryType.income);
      expect(s.categoryId, 'redpacket');
    });

    test('note keyword drives the category', () {
      final history = <LedgerEntry>[
        _e(type: EntryType.expense, categoryId: 'transport', note: '打车回家'),
      ];
      final s = _suggest(history: history, note: '打车去公司', amount: 25);
      expect(s.type, EntryType.expense);
      expect(s.categoryId, 'transport');
    });

    test('no relevant history yields an empty suggestion', () {
      final history = <LedgerEntry>[
        _e(
          type: EntryType.expense,
          categoryId: 'dining',
          note: '午饭',
          amount: 40,
        ),
      ];
      // 金额与备注都对不上 → 不猜。
      final s = _suggest(history: history, amount: 7, note: '不相关');
      expect(s.isEmpty, isTrue);
    });

    test('a single non-exact loose amount match does not flip type', () {
      final history = <LedgerEntry>[
        // 唯一一笔 ~50 是收入，但金额并非精确复现（当前 55）。
        _e(type: EntryType.income, categoryId: 'salary', note: '', amount: 50),
      ];
      final s = _suggest(history: history, amount: 55);
      // 单笔且非精确 → 不敢定类型。
      expect(s.type, isNull);
    });

    test('forcedType keeps type and suggests category within it', () {
      final history = <LedgerEntry>[
        _e(type: EntryType.income, categoryId: 'salary', note: '', amount: 50),
        _e(type: EntryType.expense, categoryId: 'dining', note: '', amount: 50),
        _e(type: EntryType.expense, categoryId: 'dining', note: '', amount: 50),
      ];
      // 用户已选定支出：即便历史里也有 50 的收入，也只在支出内识别。
      final s = _suggest(
        history: history,
        amount: 50,
        forcedType: EntryType.expense,
      );
      expect(s.type, EntryType.expense);
      expect(s.categoryId, 'dining');
    });
  });
}
