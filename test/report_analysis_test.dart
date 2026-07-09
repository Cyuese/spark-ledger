import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/demo_data.dart';
import 'package:verifin/app/models.dart';
import 'package:verifin/app/report_analysis.dart';

LedgerEntry entry({
  required String id,
  required EntryType type,
  required double amount,
  required String categoryId,
  required DateTime occurredAt,
  double refundedAmount = 0,
}) {
  return LedgerEntry(
    id: id,
    bookId: 'default',
    type: type,
    amount: amount,
    categoryId: categoryId,
    accountId: 'cash',
    note: '',
    occurredAt: occurredAt,
    refundedAmount: refundedAmount,
  );
}

void main() {
  final categories = defaultCategories;

  group('ReportRange', () {
    test('month range covers whole natural month', () {
      final range = ReportRange.month(DateTime(2026, 2, 15));
      expect(range.start, DateTime(2026, 2, 1));
      expect(range.end, DateTime(2026, 2, 28));
      expect(range.dayCount, 28);
      expect(range.mode, ReportRangeMode.month);
    });

    test('year range covers whole year', () {
      final range = ReportRange.year(2026);
      expect(range.start, DateTime(2026, 1, 1));
      expect(range.end, DateTime(2026, 12, 31));
      expect(range.dayCount, 365);
    });

    test('custom range normalizes reversed bounds and strips time', () {
      final range = ReportRange.custom(
        DateTime(2026, 3, 10, 23, 59),
        DateTime(2026, 3, 1, 8),
      );
      expect(range.start, DateTime(2026, 3, 1));
      expect(range.end, DateTime(2026, 3, 10));
      expect(range.dayCount, 10);
    });
  });

  test('reportSummary nets income and expense, ignores transfer', () {
    final entries = <LedgerEntry>[
      entry(
        id: 'a',
        type: EntryType.income,
        amount: 1000,
        categoryId: 'salary',
        occurredAt: DateTime(2026, 5, 1),
      ),
      entry(
        id: 'b',
        type: EntryType.expense,
        amount: 300,
        categoryId: 'dining',
        occurredAt: DateTime(2026, 5, 2),
        refundedAmount: 100,
      ),
      LedgerEntry(
        id: 'c',
        bookId: 'default',
        type: EntryType.transfer,
        amount: 500,
        categoryId: 'transfer_out',
        accountId: 'cash',
        toAccountId: 'bank',
        note: '',
        occurredAt: DateTime(2026, 5, 3),
      ),
    ];
    final summary = reportSummary(entries);
    expect(summary.income, 1000);
    expect(summary.expense, 200); // 300 - 100 refunded
    expect(summary.net, 800);
    expect(summary.incomeCount, 1);
    expect(summary.expenseCount, 1);
    expect(summary.entryCount, 2);
  });

  test('reportCategoryStats aggregates by type and sorts desc', () {
    final entries = <LedgerEntry>[
      entry(
        id: 'e1',
        type: EntryType.expense,
        amount: 100,
        categoryId: 'dining',
        occurredAt: DateTime(2026, 5, 1),
      ),
      entry(
        id: 'e2',
        type: EntryType.expense,
        amount: 300,
        categoryId: 'transport',
        occurredAt: DateTime(2026, 5, 2),
      ),
      entry(
        id: 'i1',
        type: EntryType.income,
        amount: 5000,
        categoryId: 'salary',
        occurredAt: DateTime(2026, 5, 3),
      ),
    ];
    final expenseStats = reportCategoryStats(
      entries,
      categories,
      EntryType.expense,
    );
    expect(expenseStats.length, 2);
    expect(expenseStats.first.category.id, 'transport');
    expect(expenseStats.first.amount, 300);
    expect(expenseStats.first.percent, closeTo(0.75, 1e-9));

    final incomeStats = reportCategoryStats(
      entries,
      categories,
      EntryType.income,
    );
    expect(incomeStats.length, 1);
    expect(incomeStats.first.category.id, 'salary');
    expect(incomeStats.first.percent, closeTo(1.0, 1e-9));
  });

  group('子分类统计', () {
    // 餐饮(顶级) → 午餐 / 晚餐(子分类)，加一个 transport 顶级。
    const treeCategories = <Category>[
      Category(
        id: 'dining',
        label: '餐饮',
        type: EntryType.expense,
        iconCode: 'dining',
      ),
      Category(
        id: 'lunch',
        label: '午餐',
        type: EntryType.expense,
        iconCode: 'dining',
        parentId: 'dining',
      ),
      Category(
        id: 'dinner',
        label: '晚餐',
        type: EntryType.expense,
        iconCode: 'dining',
        parentId: 'dining',
      ),
      Category(
        id: 'transport',
        label: '交通',
        type: EntryType.expense,
        iconCode: 'transport',
      ),
    ];
    final treeEntries = <LedgerEntry>[
      entry(
        id: 'l1',
        type: EntryType.expense,
        amount: 30,
        categoryId: 'lunch',
        occurredAt: DateTime(2026, 5, 1),
      ),
      entry(
        id: 'd1',
        type: EntryType.expense,
        amount: 50,
        categoryId: 'dinner',
        occurredAt: DateTime(2026, 5, 2),
      ),
      entry(
        id: 'p1',
        type: EntryType.expense,
        amount: 20,
        categoryId: 'dining',
        occurredAt: DateTime(2026, 5, 3),
      ),
      entry(
        id: 't1',
        type: EntryType.expense,
        amount: 100,
        categoryId: 'transport',
        occurredAt: DateTime(2026, 5, 4),
      ),
    ];

    test('reportCategoryStats 顶级：餐饮汇总子分类，共 100', () {
      final stats = reportCategoryStats(
        treeEntries,
        treeCategories,
        EntryType.expense,
      );
      final dining = stats.firstWhere((s) => s.category.id == 'dining');
      expect(dining.amount, 100); // 30 + 50 + 20
      expect(dining.count, 3);
    });

    test('reportCategoryStatsByOwn 子分类：午餐/晚餐/餐饮各成一行', () {
      final stats = reportCategoryStatsByOwn(
        treeEntries,
        treeCategories,
        EntryType.expense,
      );
      final ids = stats.map((s) => s.category.id).toSet();
      expect(
        ids,
        containsAll(<String>['lunch', 'dinner', 'dining', 'transport']),
      );
      expect(stats.firstWhere((s) => s.category.id == 'lunch').amount, 30);
    });

    test('reportCategoryChildStats 下钻：只含餐饮下的拆分（含直接记在餐饮的）', () {
      final children = reportCategoryChildStats(
        treeEntries,
        treeCategories,
        'dining',
        EntryType.expense,
      );
      final ids = children.map((s) => s.category.id).toSet();
      expect(ids, <String>{'lunch', 'dinner', 'dining'});
      expect(ids.contains('transport'), isFalse);
      // 晚餐占餐饮合计 50/100。
      expect(
        children.firstWhere((s) => s.category.id == 'dinner').percent,
        closeTo(0.5, 1e-9),
      );
    });
  });

  group('标签统计', () {
    LedgerEntry tagged(String id, double amount, List<String> tagIds) {
      return LedgerEntry(
        id: id,
        bookId: 'default',
        type: EntryType.expense,
        amount: amount,
        categoryId: 'dining',
        accountId: 'cash',
        note: '',
        occurredAt: DateTime(2026, 5, 1),
        tagIds: tagIds,
      );
    }

    const tags = <Tag>[
      Tag(id: 'work', label: '工作'),
      Tag(id: 'food', label: '吃饭'),
    ];

    test('每笔计入其每个标签，占比相对维度总额（可重叠）', () {
      final entries = <LedgerEntry>[
        tagged('a', 100, <String>['work', 'food']),
        tagged('b', 100, <String>['work']),
        tagged('c', 100, <String>[]),
      ];
      final stats = reportTagStats(entries, tags, EntryType.expense);
      final work = stats.firstWhere((s) => s.tag.id == 'work');
      final food = stats.firstWhere((s) => s.tag.id == 'food');
      expect(work.amount, 200); // a + b
      expect(work.count, 2);
      // 维度总额 = 300（含无标签的 c）；work 占比 200/300。
      expect(work.percent, closeTo(200 / 300, 1e-9));
      expect(food.amount, 100);
      // 降序：work 在前。
      expect(stats.first.tag.id, 'work');
    });
  });

  group('reportMonthlyComparison & changeRatio', () {
    test('changeRatio uses base magnitude and guards zero base', () {
      expect(changeRatio(120, 100), closeTo(0.2, 1e-9));
      expect(changeRatio(80, 100), closeTo(-0.2, 1e-9));
      expect(changeRatio(50, 0), isNull);
    });

    test('formatChangeRatio renders sign and dash for null', () {
      expect(formatChangeRatio(0.123), '+12.3%');
      expect(formatChangeRatio(-0.08), '-8.0%');
      expect(formatChangeRatio(null), '—');
      expect(formatChangeRatio(0), '0%');
    });

    test('comparison pulls current, previous month and last year', () {
      final entries = <LedgerEntry>[
        entry(
          id: 'cur',
          type: EntryType.expense,
          amount: 300,
          categoryId: 'dining',
          occurredAt: DateTime(2026, 5, 10),
        ),
        entry(
          id: 'prev',
          type: EntryType.expense,
          amount: 200,
          categoryId: 'dining',
          occurredAt: DateTime(2026, 4, 10),
        ),
        entry(
          id: 'yoy',
          type: EntryType.expense,
          amount: 150,
          categoryId: 'dining',
          occurredAt: DateTime(2025, 5, 10),
        ),
      ];
      final cmp = reportMonthlyComparison(entries, DateTime(2026, 5, 20));
      expect(cmp.current.expense, 300);
      expect(cmp.previousMonth.expense, 200);
      expect(cmp.sameMonthLastYear.expense, 150);
      expect(
        changeRatio(cmp.current.expense, cmp.previousMonth.expense),
        closeTo(0.5, 1e-9),
      );
    });

    test('january previous month rolls into last december', () {
      final entries = <LedgerEntry>[
        entry(
          id: 'dec',
          type: EntryType.income,
          amount: 1000,
          categoryId: 'salary',
          occurredAt: DateTime(2025, 12, 5),
        ),
      ];
      final cmp = reportMonthlyComparison(entries, DateTime(2026, 1, 15));
      expect(cmp.previousMonth.income, 1000);
    });
  });

  group('reportTrend', () {
    test('short custom range is daily and buckets by day', () {
      final range = ReportRange.custom(
        DateTime(2026, 5, 1),
        DateTime(2026, 5, 5),
      );
      final entries = <LedgerEntry>[
        entry(
          id: 'e1',
          type: EntryType.expense,
          amount: 40,
          categoryId: 'dining',
          occurredAt: DateTime(2026, 5, 2, 10),
        ),
        entry(
          id: 'e2',
          type: EntryType.expense,
          amount: 60,
          categoryId: 'dining',
          occurredAt: DateTime(2026, 5, 2, 20),
        ),
        entry(
          id: 'skip',
          type: EntryType.income,
          amount: 999,
          categoryId: 'salary',
          occurredAt: DateTime(2026, 5, 2),
        ),
      ];
      final trend = reportTrend(entries, range, EntryType.expense);
      expect(trend.granularity, ReportTrendGranularity.daily);
      expect(trend.points.length, 5);
      expect(trend.values[1], 100); // May 2 = 40 + 60
      expect(trend.maxValue, 100);
    });

    test('year range is monthly with 12 buckets', () {
      final range = ReportRange.year(2026);
      final entries = <LedgerEntry>[
        entry(
          id: 'jan',
          type: EntryType.expense,
          amount: 200,
          categoryId: 'dining',
          occurredAt: DateTime(2026, 1, 15),
        ),
        entry(
          id: 'dec',
          type: EntryType.expense,
          amount: 500,
          categoryId: 'dining',
          occurredAt: DateTime(2026, 12, 31),
        ),
        entry(
          id: 'other-year',
          type: EntryType.expense,
          amount: 999,
          categoryId: 'dining',
          occurredAt: DateTime(2025, 12, 31),
        ),
      ];
      final trend = reportTrend(entries, range, EntryType.expense);
      expect(trend.granularity, ReportTrendGranularity.monthly);
      expect(trend.points.length, 12);
      expect(trend.values.first, 200);
      expect(trend.values.last, 500);
    });

    test('range spanning several months aggregates monthly', () {
      final range = ReportRange.custom(
        DateTime(2026, 1, 1),
        DateTime(2026, 4, 30),
      );
      final entries = <LedgerEntry>[
        entry(
          id: 'feb',
          type: EntryType.expense,
          amount: 80,
          categoryId: 'dining',
          occurredAt: DateTime(2026, 2, 10),
        ),
      ];
      final trend = reportTrend(entries, range, EntryType.expense);
      expect(trend.granularity, ReportTrendGranularity.monthly);
      expect(trend.points.length, 4);
      expect(trend.values[1], 80);
    });
  });
}
