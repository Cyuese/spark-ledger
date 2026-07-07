import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/backup/payment_import.dart';
import 'package:verifin/app/models.dart';
import 'package:verifin/app/veri_fin_scope.dart';
import 'package:verifin/pages/entry_detail_page.dart';
import 'package:verifin/pages/import_preview_page.dart';

import 'support/test_harness.dart';

Uint8List _csvBytes(String csv) => Uint8List.fromList(utf8.encode(csv));

const _csv =
    '日期,类型,金额,分类,账户,转入账户,备注\n'
    '2026-02-01,支出,12.5,测试餐饮,测试钱包A,,午饭\n'
    '2026-02-02,支出,30,测试交通,测试钱包B,,打车\n';

void main() {
  useTestDatabases();

  group('parsePlatformImport（只解析不落库）', () {
    test('解析返回计划但不修改账本', () async {
      final controller = await makeController();
      final beforeEntries = controller.entries.length;
      final beforeAccounts = controller.accounts.length;
      final plan = controller.parsePlatformImport(
        ImportPlatform.genericCsv,
        _csvBytes(_csv),
      );
      expect(plan.importedCount, 2);
      expect(
        plan.newAccounts.map((a) => a.name),
        containsAll(<String>['测试钱包A', '测试钱包B']),
      );
      // 未落库：账本不变。
      expect(controller.entries.length, beforeEntries);
      expect(controller.accounts.length, beforeAccounts);
    });
  });

  group('applyImportEntries（落库被引用子集）', () {
    test('全部保留：交易与其引用的新账户/分类都落地', () async {
      final controller = await makeController();
      final beforeEntries = controller.entries.length;
      final plan = controller.parsePlatformImport(
        ImportPlatform.genericCsv,
        _csvBytes(_csv),
      );
      controller.applyImportEntries(
        entries: plan.entries,
        candidateAccounts: plan.newAccounts,
        candidateCategories: plan.newCategories,
      );
      expect(controller.entries.length, beforeEntries + 2);
      expect(controller.accounts.any((a) => a.name == '测试钱包A'), isTrue);
      expect(controller.accounts.any((a) => a.name == '测试钱包B'), isTrue);
      expect(controller.categories.any((c) => c.label == '测试交通'), isTrue);
    });

    test('排除某笔后：只创建被保留交易引用到的账户/分类', () async {
      final controller = await makeController();
      final plan = controller.parsePlatformImport(
        ImportPlatform.genericCsv,
        _csvBytes(_csv),
      );
      final walletAId = plan.newAccounts
          .firstWhere((a) => a.name == '测试钱包A')
          .id;
      // 只保留第一笔（引用 测试钱包A / 测试餐饮）。
      final kept = plan.entries.where((e) => e.accountId == walletAId).toList();
      expect(kept, hasLength(1));
      controller.applyImportEntries(
        entries: kept,
        candidateAccounts: plan.newAccounts,
        candidateCategories: plan.newCategories,
      );
      expect(controller.accounts.any((a) => a.name == '测试钱包A'), isTrue);
      expect(controller.categories.any((c) => c.label == '测试餐饮'), isTrue);
      // 第二笔被排除：测试钱包B 与 测试交通 不应被创建。
      expect(controller.accounts.any((a) => a.name == '测试钱包B'), isFalse);
      expect(controller.categories.any((c) => c.label == '测试交通'), isFalse);
    });
  });

  group('ImportPreviewPage', () {
    testWidgets('渲染待导入交易，可排除后确认返回子集', (tester) async {
      final controller = await makeController();
      final plan = controller.parsePlatformImport(
        ImportPlatform.genericCsv,
        _csvBytes(_csv),
      );
      List<LedgerEntry>? result;
      await tester.pumpWidget(
        VeriFinScope(
          controller: controller,
          child: zhMaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      result = await Navigator.of(context)
                          .push<List<LedgerEntry>>(
                            MaterialPageRoute<List<LedgerEntry>>(
                              builder: (_) => ImportPreviewPage(
                                plan: plan,
                                sourceLabel: '其他 CSV',
                              ),
                            ),
                          );
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // 两笔交易都渲染。
      expect(find.text('测试餐饮'), findsOneWidget);
      expect(find.text('测试交通'), findsOneWidget);
      // 初始确认按钮：全部 2 笔。
      expect(find.text('确认导入（2）'), findsOneWidget);

      // 点第一笔（测试餐饮）排除 → 变 1 笔。
      await tester.tap(find.text('测试餐饮'));
      await tester.pumpAndSettle();
      expect(find.text('确认导入（1）'), findsOneWidget);

      // 确认导入，返回被保留的那一笔。
      await tester.tap(find.text('确认导入（1）'));
      await tester.pumpAndSettle();
      expect(result, isNotNull);
      expect(result, hasLength(1));
      expect(result!.single.note, '打车');
    });
  });

  group('EntryDetailPage.draft（草稿编辑不落库）', () {
    testWidgets('编辑后返回修改草稿，账本不变', (tester) async {
      final controller = await makeController();
      final account = Account(
        id: 'acc_x',
        bookId: controller.activeBook.id,
        name: '测试账户',
        type: AccountType.cash,
        groupId: null,
        initialBalance: 0,
        iconCode: 'wallet',
        note: '',
        includeInAssets: true,
        hidden: false,
      );
      controller.addAccount(account);
      // 临时（未落库）分类，经 extraCategories 传入草稿编辑页解析。
      const category = Category(
        id: 'cat_x',
        label: '测试类',
        type: EntryType.expense,
        iconCode: 'category',
      );
      final entry = LedgerEntry(
        id: 'draft_1',
        bookId: controller.activeBook.id,
        type: EntryType.expense,
        amount: 42,
        categoryId: category.id,
        accountId: account.id,
        note: '原备注',
        occurredAt: DateTime(2026, 2, 3, 9, 0),
      );
      final before = controller.entries.length;
      LedgerEntry? popped;
      await tester.pumpWidget(
        VeriFinScope(
          controller: controller,
          child: zhMaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      popped = await Navigator.of(context).push<LedgerEntry>(
                        MaterialPageRoute<LedgerEntry>(
                          builder: (_) => EntryDetailPage.draft(
                            entry: entry,
                            extraCategories: const <Category>[category],
                          ),
                        ),
                      );
                    },
                    child: const Text('open'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // 预填了原备注。
      expect(find.text('原备注'), findsOneWidget);
      await tester.enterText(find.byKey(const Key('entry_note_field')), '改后备注');
      await tester.tap(find.byKey(const Key('save_entry_button')));
      await tester.pumpAndSettle();

      expect(popped, isNotNull);
      expect(popped!.id, 'draft_1');
      expect(popped!.note, '改后备注');
      expect(popped!.amount, 42);
      // 未落库：账本交易数不变。
      expect(controller.entries.length, before);
    });
  });
}
