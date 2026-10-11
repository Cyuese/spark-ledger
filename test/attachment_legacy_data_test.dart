import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common/sqflite_logger.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:verifin/app/models.dart';
import 'package:verifin/data/app_database.dart';
import 'package:verifin/data/ledger_repository.dart';

/// Issue 45 的附件回归测试：旧库的 `attachments.data_url` 里可能内嵌几十~上百 MB 的
/// base64 图片。
///
/// 三条不变量在这里守住：
/// 1. 冷启动的 [LedgerRepository.loadAttachments] 只读元数据列，绝不整列取回 `data_url`；
/// 2. 迁移期可以按 id 逐条读/清 `data_url`；
/// 3. 整账本重建（导入/恢复/重置/删账本/启动自愈）不得丢掉尚未迁移的 `data_url`。
void main() {
  setUpAll(sqfliteFfiInit);

  late Directory tempDir;
  late DatabaseFactory loggingFactory;
  late List<String> sqlLog;
  final opened = <AppDatabase>[];

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp(
      'verifin_attachment_legacy',
    );
    sqlLog = <String>[];
    // sqflite 唯一的 SQL 日志入口仍标着 @experimental，这里只用于断言
    // [LedgerRepository.loadAttachments] 发出的 SELECT 不含 data_url——这是 Issue 45
    // 「冷启动不得整列读回旧版 base64」的回归护栏。该 API 万一变动，删掉本用例即可，
    // 不涉及生产代码。
    // ignore: experimental_member_use
    loggingFactory = SqfliteDatabaseFactoryLogger(
      databaseFactoryFfi,
      options: SqfliteLoggerOptions(
        type: SqfliteDatabaseFactoryLoggerType.all,
        log: (event) {
          if (event is SqfliteLoggerSqlEvent) {
            sqlLog.add(event.sql);
          }
        },
      ),
    );
  });

  tearDown(() async {
    for (final app in opened) {
      await app.close();
    }
    opened.clear();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  Future<AppDatabase> openApp() async {
    final app = await AppDatabase.open(
      factory: loggingFactory,
      path: '${tempDir.path}/legacy.db',
    );
    opened.add(app);
    return app;
  }

  /// 写入一条旧版行：只有内嵌 base64，还没有对应文件。
  Future<void> insertLegacyRow(
    AppDatabase app, {
    required String id,
    required String entryId,
    required int sortOrder,
    String dataUrl = 'data:image/jpeg;base64,/9j/4AAQSkZJRgABAQAAAQ==',
  }) async {
    await app.db.insert('attachments', <String, Object?>{
      'id': id,
      'entry_id': entryId,
      'sort_order': sortOrder,
      'mime_type': 'image/jpeg',
      'byte_size': 0,
      'data_url': dataUrl,
    });
  }

  test('loadAttachments 只读元数据列，不把 data_url 取回内存', () async {
    final app = await openApp();
    final repo = SqliteLedgerRepository(app);
    await insertLegacyRow(app, id: 'legacy-1', entryId: 'e1', sortOrder: 0);
    await insertLegacyRow(app, id: 'legacy-2', entryId: 'e1', sortOrder: 1);

    sqlLog.clear();
    final loaded = await repo.loadAttachments();

    expect(loaded.map((a) => a.id).toList(), <String>['legacy-1', 'legacy-2']);
    expect(loaded.first.mimeType, 'image/jpeg');

    final attachmentSelects = sqlLog
        .where((sql) => sql.startsWith('SELECT') && sql.contains('attachments'))
        .toList();
    expect(attachmentSelects, isNotEmpty, reason: '应至少发出一次附件 SELECT');
    for (final sql in attachmentSelects) {
      expect(
        sql,
        isNot(contains('data_url')),
        reason: '整列读回旧版 base64 会让冷启动内存随附件总量增长：$sql',
      );
      expect(
        sql,
        isNot(contains('*')),
        reason: 'SELECT * 同样会取回 data_url，必须显式列元数据列：$sql',
      );
    }
  });

  test('迁移期按 id 读、列待迁移、清空 data_url', () async {
    final app = await openApp();
    final repo = SqliteLedgerRepository(app);
    await insertLegacyRow(app, id: 'legacy-1', entryId: 'e1', sortOrder: 0);
    await insertLegacyRow(
      app,
      id: 'legacy-2',
      entryId: 'e1',
      sortOrder: 1,
      dataUrl: '',
    );

    expect(await repo.attachmentIdsWithLegacyData(), <String>['legacy-1']);
    expect(
      await repo.loadAttachmentDataUrl('legacy-1'),
      startsWith('data:image/jpeg;base64,'),
    );
    // 空串与 NULL 都表示「没有旧字节可迁移」。
    expect(await repo.loadAttachmentDataUrl('legacy-2'), '');

    await repo.clearAttachmentDataUrl('legacy-1');

    expect(await repo.attachmentIdsWithLegacyData(), isEmpty);
    expect(await repo.loadAttachmentDataUrl('legacy-1'), null);
    // 清空只是去掉旧字节，元数据仍在。
    expect((await repo.loadAttachments()).map((a) => a.id).toList(), <String>[
      'legacy-1',
      'legacy-2',
    ]);
  });

  test('replaceAllLedgerData 保留未被删除行的 data_url', () async {
    final app = await openApp();
    final repo = SqliteLedgerRepository(app);
    await insertLegacyRow(app, id: 'keep', entryId: 'e1', sortOrder: 0);
    await insertLegacyRow(app, id: 'drop', entryId: 'e1', sortOrder: 1);

    // 整账本重建：只保留 `keep`（模拟启动自愈 / 删账本 / 删条目等非导入场景）。
    await repo.replaceAllLedgerData(
      LedgerDataSnapshot(
        books: await repo.loadBooks(),
        accounts: await repo.loadAccounts(),
        accountGroups: await repo.loadAccountGroups(),
        categories: await repo.loadCategories(),
        tags: await repo.loadTags(),
        attachments: const <Attachment>[
          Attachment(id: 'keep', entryId: 'e1', byteSize: 0),
        ],
        entries: const <LedgerEntry>[],
        recurringRules: const <RecurringRule>[],
        monthlyBudgets: const <String, double>{},
        categoryBudgets: const <String, double>{},
        dailyBudgets: const <String, double>{},
      ),
    );

    expect((await repo.loadAttachments()).single.id, 'keep');
    expect(
      await repo.loadAttachmentDataUrl('keep'),
      startsWith('data:image/jpeg;base64,'),
      reason: '尚未迁移的旧图片不能因为整账本重建被静默删除',
    );
    expect(await repo.loadAttachmentDataUrl('drop'), null);
  });

  test('迁移完成后回收 data_url 列，元数据与后续写入不受影响', () async {
    final app = await openApp();
    final repo = SqliteLedgerRepository(app);
    await insertLegacyRow(app, id: 'a', entryId: 'e1', sortOrder: 0);
    await insertLegacyRow(
      app,
      id: 'b',
      entryId: 'e1',
      sortOrder: 1,
      dataUrl: '',
    );

    Future<List<String>> columns() async => (await app.db.rawQuery(
      'PRAGMA table_info(attachments)',
    )).map((row) => row['name']! as String).toList();

    expect(await columns(), contains('data_url'));
    // 还有没落盘的旧字节：拒绝回收，整列保留。
    expect(await repo.dropLegacyAttachmentData(), isFalse);
    expect(await columns(), contains('data_url'));

    await repo.clearAttachmentDataUrl('a');

    expect(await repo.dropLegacyAttachmentData(), isTrue);
    expect(await columns(), isNot(contains('data_url')));
    // 列删除后读取与清理都必须安全退化。
    expect(await repo.loadAttachmentDataUrl('a'), null);
    expect(await repo.attachmentIdsWithLegacyData(), isEmpty);
    await repo.clearAttachmentDataUrl('a');
    expect((await repo.loadAttachments()).map((a) => a.id).toList(), <String>[
      'a',
      'b',
    ]);
    // 幂等：第二次没有可回收的内容。
    expect(await repo.dropLegacyAttachmentData(), isFalse);

    // 回收后附件写入/删除仍然正常。
    await repo.saveAttachments(const <Attachment>[
      Attachment(id: 'c', entryId: 'e2', byteSize: 7),
    ]);
    expect((await repo.loadAttachments()).map((a) => a.id).toList(), <String>[
      'c',
    ]);
    await repo.saveAttachments(const <Attachment>[]);
    expect(await repo.loadAttachments(), isEmpty);
  });
}
