import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/ledger_math.dart';
import 'package:verifin/app/models.dart';
import 'package:verifin/app/widgets/widget_catalog.dart';
import 'package:verifin/app/widgets/widget_projection.dart';

/// 投影性能护栏。
///
/// 旧实现按「每个账户 × 全部交易」重复扫描，净资产曲线更是每天算一次，
/// 20 账户 × 5000 笔实测 145.7 ms；改前的第一版优化（每条交易构造 `DateTime` 再算
/// 日历日差）仍有 135 ms。现在一次遍历 + 逐日前缀和，同机约 6 ms。
/// 上限取 40 ms：既不会在慢 CI 上抖动，又能在退化回按账户/按日重复扫描时失败。
void main() {
  test('20 账户 × 5000 笔账本的完整投影不退化', () {
    final book = LedgerBook(
      id: 'book',
      name: '个人',
      createdAt: DateTime(2026),
      isDefault: true,
    );
    const accountCount = 20;
    final accounts = List<Account>.generate(
      accountCount,
      (i) => Account(
        id: 'a$i',
        bookId: book.id,
        name: '账户$i',
        type: AccountType.cash,
        groupId: null,
        initialBalance: 1000,
        iconCode: 'wallet',
        note: '',
        includeInAssets: true,
        hidden: false,
      ),
    );
    final origin = DateTime(2024, 10, 12);
    final entries = List<LedgerEntry>.generate(
      5000,
      (i) => LedgerEntry(
        id: 'e$i',
        bookId: book.id,
        type: EntryType.expense,
        amount: 10 + (i % 37),
        categoryId: 'dining',
        accountId: 'a${i % accountCount}',
        note: '',
        occurredAt: addCalendarDays(origin, i % 700),
      ),
    );
    final snapshot = WidgetBookSnapshot(
      book: book,
      entries: entries,
      accounts: accounts,
      rates: const <ExchangeRate>[],
      budgetWindow: DateWindow(
        start: DateTime(2026, 10),
        end: DateTime(2026, 10, 31),
      ),
      budget: 5000,
      usesMultipleCurrencies: false,
    );
    final now = DateTime(2026, 10, 12);

    // 预热，避免把首次 JIT 编译算进耗时。
    buildWidgetBookProjection(snapshot: snapshot, now: now);
    final stopwatch = Stopwatch()..start();
    final projection = buildWidgetBookProjection(snapshot: snapshot, now: now);
    stopwatch.stop();

    expect(
      projection.templates[WidgetTemplate.trend]!.points!.length,
      widgetChartDays,
    );
    expect(projection.templates[WidgetTemplate.netWorth]!.points, isNotNull);
    expect(
      stopwatch.elapsedMilliseconds,
      lessThan(40),
      reason: '投影耗时 ${stopwatch.elapsedMilliseconds} ms，疑似退化回按账户重复扫描',
    );
  });
}
