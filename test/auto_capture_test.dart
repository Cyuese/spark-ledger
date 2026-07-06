import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/ai/ai_entry_parser.dart';
import 'package:verifin/app/auto_capture/auto_capture_coordinator.dart';
import 'package:verifin/app/auto_capture/auto_capture_settings.dart';
import 'package:verifin/app/auto_capture/notification_prefilter.dart';
import 'package:verifin/app/models.dart';

AiEntryContext _context() => AiEntryContext(
  expenseCategories: const <AiOption>[
    AiOption(id: 'dining', label: '餐饮'),
    AiOption(id: 'transport', label: '交通'),
  ],
  incomeCategories: const <AiOption>[AiOption(id: 'salary', label: '工资')],
  accounts: const <AiOption>[AiOption(id: 'card', label: '招商银行')],
  today: DateTime(2026, 7, 6, 11, 43),
  bookId: 'default',
);

CapturedNotification _cap({
  String pkg = 'com.eg.android.AlipayGphone',
  String text = '你已成功付款 12.50 元',
}) => CapturedNotification(
  packageName: pkg,
  text: text,
  postedAt: DateTime(2026, 7, 6),
);

void main() {
  group('notificationLikelyTransaction', () {
    test('true when text contains a digit', () {
      expect(notificationLikelyTransaction('你已成功付款 12.50 元'), isTrue);
      expect(
        notificationLikelyTransaction('您账户0966与07月06日11:43收款人民币0.01'),
        isTrue,
      );
    });

    test('false when no digit or empty', () {
      expect(notificationLikelyTransaction('您有一条新消息'), isFalse);
      expect(notificationLikelyTransaction('   '), isFalse);
      expect(notificationLikelyTransaction(''), isFalse);
    });
  });

  group('AutoCaptureSettings', () {
    test('disabled default has nothing enabled', () {
      const settings = AutoCaptureSettings.disabled;
      expect(settings.notificationEnabled, isFalse);
      expect(settings.listenAllSources, isFalse);
      expect(settings.isSourceEnabled('com.tencent.mm'), isFalse);
    });

    test('listenAll makes every source enabled', () {
      const settings = AutoCaptureSettings(listenAllSources: true);
      expect(settings.isSourceEnabled('any.random.pkg'), isTrue);
    });

    test('toggleSource adds and removes from whitelist', () {
      var settings = const AutoCaptureSettings();
      settings = settings.toggleSource('com.tencent.mm', true);
      expect(settings.isSourceEnabled('com.tencent.mm'), isTrue);
      settings = settings.toggleSource('com.tencent.mm', false);
      expect(settings.isSourceEnabled('com.tencent.mm'), isFalse);
    });

    test('encode/decode round-trips', () {
      const settings = AutoCaptureSettings(
        notificationEnabled: true,
        sourcePackages: <String>['com.tencent.mm'],
        doneText: '已记账',
      );
      expect(AutoCaptureSettings.decode(settings.encode()), settings);
    });

    test('decode of null/garbage returns disabled', () {
      expect(AutoCaptureSettings.decode(null), AutoCaptureSettings.disabled);
      expect(
        AutoCaptureSettings.decode('not json'),
        AutoCaptureSettings.disabled,
      );
    });

    test('defaultSourcePackages covers the built-in on sources', () {
      expect(defaultSourcePackages(), contains('com.eg.android.AlipayGphone'));
      expect(defaultSourcePackages(), contains('com.tencent.mm'));
    });
  });

  group('buildNotificationEntryPrompt', () {
    test('asks for isTransaction and keeps category/account ids', () {
      final prompt = buildNotificationEntryPrompt(_context());
      expect(prompt, contains('isTransaction'));
      expect(prompt, contains('dining'));
      expect(prompt, contains('card'));
      expect(prompt, contains('2026-07-06'));
    });
  });

  group('parseNotificationEntryDraft', () {
    test('parses a transaction with isTransaction true', () {
      final draft = parseNotificationEntryDraft(
        '{"isTransaction":true,"type":"expense","amount":12.5,'
        '"categoryId":"dining","accountId":"","toAccountId":null,'
        '"note":"星巴克","date":"2026-07-06"}',
        _context(),
      );
      expect(draft.isTransaction, isTrue);
      expect(draft.amount, 12.5);
      expect(draft.categoryId, 'dining');
      expect(draft.note, '星巴克');
    });

    test(
      'non-transaction notification yields isTransaction false, no throw',
      () {
        final draft = parseNotificationEntryDraft(
          '{"isTransaction":false,"type":"expense","amount":0}',
          _context(),
        );
        expect(draft.isTransaction, isFalse);
        expect(draft.amount, 0);
      },
    );

    test(
      'claims transaction but zero amount is treated as non-transaction',
      () {
        final draft = parseNotificationEntryDraft(
          '{"isTransaction":true,"amount":0}',
          _context(),
        );
        expect(draft.isTransaction, isFalse);
      },
    );

    test('missing isTransaction defaults to true when amount valid', () {
      final draft = parseNotificationEntryDraft(
        '{"type":"income","amount":0.01,"categoryId":"salary","accountId":"card"}',
        _context(),
      );
      expect(draft.isTransaction, isTrue);
      expect(draft.type, EntryType.income);
      expect(draft.amount, 0.01);
    });
  });

  group('AutoCaptureCoordinator', () {
    AutoCaptureCoordinator make({
      required AutoCaptureSettings settings,
      Future<AiEntryDraft> Function(CapturedNotification)? requestDraft,
      void Function(AiEntryDraft, CapturedNotification)? commit,
    }) {
      return AutoCaptureCoordinator(
        settingsOf: () => settings,
        requestDraft:
            requestDraft ??
            (_) async => AiEntryDraft(
              type: EntryType.expense,
              amount: 12.5,
              categoryId: 'dining',
              accountId: '',
              toAccountId: null,
              note: '',
              occurredAt: DateTime(2026, 7, 6),
            ),
        commitDraft: commit ?? (_, _) {},
      );
    }

    test('skips when disabled', () async {
      final c = make(settings: AutoCaptureSettings.disabled);
      expect(await c.process(_cap()), AutoCaptureOutcome.disabledSkip);
    });

    test('skips when source not whitelisted', () async {
      final c = make(
        settings: const AutoCaptureSettings(
          notificationEnabled: true,
          sourcePackages: <String>['com.tencent.mm'],
        ),
      );
      expect(await c.process(_cap()), AutoCaptureOutcome.sourceSkip);
    });

    test('skips prefilter when no digit, without calling AI', () async {
      var called = false;
      final c = make(
        settings: const AutoCaptureSettings(
          notificationEnabled: true,
          listenAllSources: true,
        ),
        requestDraft: (_) async {
          called = true;
          throw StateError('AI should not be called');
        },
      );
      final outcome = await c.process(_cap(text: '您有一条新消息'));
      expect(outcome, AutoCaptureOutcome.prefilterSkip);
      expect(called, isFalse);
    });

    test('commits a recognized transaction', () async {
      AiEntryDraft? committed;
      final c = make(
        settings: const AutoCaptureSettings(
          notificationEnabled: true,
          listenAllSources: true,
        ),
        commit: (draft, _) => committed = draft,
      );
      expect(await c.process(_cap()), AutoCaptureOutcome.committed);
      expect(committed, isNotNull);
      expect(committed!.amount, 12.5);
    });

    test('drops when AI says not a transaction', () async {
      final c = make(
        settings: const AutoCaptureSettings(
          notificationEnabled: true,
          listenAllSources: true,
        ),
        requestDraft: (_) async => AiEntryDraft(
          type: EntryType.expense,
          amount: 0,
          categoryId: '',
          accountId: '',
          toAccountId: null,
          note: '',
          occurredAt: DateTime(2026, 7, 6),
          isTransaction: false,
        ),
      );
      expect(await c.process(_cap()), AutoCaptureOutcome.notTransactionSkip);
    });

    test('AI failure is reported as failed, not thrown', () async {
      final c = make(
        settings: const AutoCaptureSettings(
          notificationEnabled: true,
          listenAllSources: true,
        ),
        requestDraft: (_) async => throw Exception('network down'),
      );
      expect(await c.process(_cap()), AutoCaptureOutcome.failed);
    });
  });
}
