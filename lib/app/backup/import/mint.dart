import 'dart:typed_data';

import 'raw_import.dart';
import 'text_format.dart';

/// 薄荷记账 CSV：UTF-16LE 编码、**制表符分隔**，类型为 收入/支出/转账，支出金额为负
/// （方向由类型定，[parseImportAmount] 取绝对值）。转账带「付款/收款」两账户。基于用户
/// 真实导出样例。
ParsedImport parseMint(Uint8List bytes) {
  final rows = parseTsv(decodeUtf16Bytes(bytes));
  final headerIndex = findHeaderRow(
    rows,
    mustHave: const <String>['类型', '金额', '账户'],
  );
  if (headerIndex == null) {
    throw const FormatException('未找到薄荷记账表头（类型/金额/账户），请确认选择的是薄荷记账导出的 CSV');
  }
  final cols = columnIndex(rows[headerIndex]);
  final records = <RawImportRecord>[];
  final errors = <ImportRowError>[];
  for (var i = headerIndex + 1; i < rows.length; i++) {
    final row = rows[i];
    final type = cellAt(row, cols['类型']);
    final note = joinNote(<String>[
      cellAt(row, cols['备注']),
      cellAt(row, cols['项目']),
    ]);
    final line = i + 1;
    void onError(String message) =>
        errors.add(ImportRowError(line: line, message: message));
    final RawImportRecord? record;
    if (type == '转账') {
      record = buildRecordFromStrings(
        date: cellAt(row, cols['日期']),
        type: type,
        amount: cellAt(row, cols['金额']),
        account: cellAt(row, cols['付款']),
        toAccount: cellAt(row, cols['收款']),
        note: note,
        sourceLine: line,
        onError: onError,
      );
    } else {
      record = buildRecordFromStrings(
        date: cellAt(row, cols['日期']),
        type: type,
        amount: cellAt(row, cols['金额']),
        category: cellAt(row, cols['分类']),
        account: cellAt(row, cols['账户']),
        note: note,
        sourceLine: line,
        onError: onError,
      );
    }
    if (record != null) {
      records.add(record);
    }
  }
  return ParsedImport(records: records, errors: errors);
}
