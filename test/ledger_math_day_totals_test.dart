import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/ledger_math.dart';
import 'package:verifin/app/models.dart';

LedgerEntry _entry({
  required String id,
  required EntryType type,
  required double amount,
  required DateTime occurredAt,
  double refundedAmount = 0,
}) {
  return LedgerEntry(
    id: id,
    bookId: 'default',
    type: type,
    amount: amount,
    categoryId: 'dining',
    accountId: 'cash',
    note: '',
    occurredAt: occurredAt,
    refundedAmount: refundedAmount,
  );
}

void main() {
  test('dayExpenseTotal sums only same-day expense net amounts', () {
    final today = DateTime(2026, 5, 10, 12);
    final entries = <LedgerEntry>[
      _entry(
        id: 'a',
        type: EntryType.expense,
        amount: 100,
        occurredAt: DateTime(2026, 5, 10, 8),
      ),
      _entry(
        id: 'b',
        type: EntryType.expense,
        amount: 50,
        occurredAt: DateTime(2026, 5, 10, 22),
        refundedAmount: 20,
      ),
      _entry(
        id: 'income-today',
        type: EntryType.income,
        amount: 999,
        occurredAt: DateTime(2026, 5, 10, 9),
      ),
      _entry(
        id: 'yesterday',
        type: EntryType.expense,
        amount: 999,
        occurredAt: DateTime(2026, 5, 9, 23),
      ),
    ];
    // 100 + (50 - 20 refunded) = 130.
    expect(dayExpenseTotal(entries, today), 130);
  });

  test('dayExpenseTotal returns 0 when nothing today', () {
    final entries = <LedgerEntry>[
      _entry(
        id: 'a',
        type: EntryType.expense,
        amount: 100,
        occurredAt: DateTime(2026, 5, 9),
      ),
    ];
    expect(dayExpenseTotal(entries, DateTime(2026, 5, 10)), 0);
  });
}
