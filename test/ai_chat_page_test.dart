import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/ai/ai_agent_engine.dart';
import 'package:verifin/app/ai/ai_completion_event.dart';
import 'package:verifin/app/ai/ai_error.dart';
import 'package:verifin/app/ai/ai_settings.dart';
import 'package:verifin/app/models.dart';
import 'package:verifin/app/veri_fin_scope.dart';
import 'package:verifin/pages/ai_chat_page.dart';
import 'package:verifin/pages/ai_settings_page.dart';

import 'support/test_harness.dart';

/// 按调用顺序返回结构化补全事件。
AiAgentStreamTransport _scripted(List<List<AiCompletionEvent>> responses) {
  var index = 0;
  return (messages, tools) async* {
    final events = index < responses.length
        ? responses[index]
        : const <AiCompletionEvent>[];
    index += 1;
    for (final event in events) {
      yield event;
    }
  };
}

List<AiCompletionEvent> _answer(String text) => <AiCompletionEvent>[
  AiContentDelta(text),
  const AiCompletionFinished(AiFinishReason.stop),
  const AiStreamDone(),
];

void main() {
  useTestDatabases();

  testWidgets('未配置 AI 时显示引导按钮', (tester) async {
    final controller = await makeController();
    await tester.pumpWidget(
      VeriFinScope(
        controller: controller,
        child: zhMaterialApp(home: const AiChatPage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('去配置 AI'), findsOneWidget);
    expect(find.text('对话只存本机，不含在备份内'), findsNothing);
    expect(find.byTooltip('AI 设置'), findsNothing);
    controller.dispose();
  });

  testWidgets('已配置 AI 时右上角设置按钮进入 AI 设置', (tester) async {
    final controller = await makeController()
      ..setAiSettings(
        const AiSettings(baseUrl: 'http://x/v1', apiKey: 'k', model: 'm'),
      );
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      VeriFinScope(
        controller: controller,
        child: zhMaterialApp(home: const AiChatPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byTooltip('AI 设置'), findsOneWidget);
    await tester.tap(find.byTooltip('AI 设置'));
    await tester.pumpAndSettle();

    expect(find.byType(AiSettingsPage), findsOneWidget);
    expect(find.text('AI 设置'), findsOneWidget);
  });

  testWidgets('已配置：发问 → 工具卡片 + 流式答复', (tester) async {
    final controller = await makeController();
    final bookId = controller.activeBook.id;
    controller
      ..setAiSettings(
        const AiSettings(baseUrl: 'http://x/v1', apiKey: 'k', model: 'm'),
      )
      ..addEntry(
        LedgerEntry(
          id: 'e1',
          bookId: bookId,
          type: EntryType.expense,
          amount: 300,
          categoryId: 'dining',
          accountId: 'cash',
          note: '',
          occurredAt: DateTime.now(),
        ),
      );

    final transport = _scripted(<List<AiCompletionEvent>>[
      <AiCompletionEvent>[
        const AiToolCallDelta(
          index: 0,
          id: 'call_1',
          name: 'summary',
          arguments: '{"range":"thisMonth"}',
        ),
        const AiCompletionFinished(AiFinishReason.toolCalls),
        const AiStreamDone(),
      ],
      _answer('本月支出合计 300 元。'),
    ]);

    await tester.pumpWidget(
      VeriFinScope(
        controller: controller,
        child: zhMaterialApp(home: AiChatPage(debugTransport: transport)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '本月花了多少');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();

    // 用户气泡
    expect(find.text('本月花了多少'), findsOneWidget);
    // summary 工具的结果卡（标题含「收支汇总」）
    expect(find.textContaining('收支汇总'), findsWidgets);
    expect(find.text('查询收支汇总'), findsOneWidget);
    expect(find.textContaining('{"tool"'), findsNothing);
    // 统计卡里的净额/支出行
    expect(find.text('支出'), findsWidgets);
    controller.dispose();
  });

  testWidgets('对话账本按页面选择，不改变全局活动账本', (tester) async {
    final controller = await makeController()
      ..setAiSettings(
        const AiSettings(baseUrl: 'http://x/v1', apiKey: 'k', model: 'm'),
      );
    final defaultBookId = controller.activeBook.id;
    final defaultBookName = controller.activeBook.name;
    controller.addLedgerBook('旅行账本', baseCurrencyCode: 'USD');
    final travelBookId = controller.activeBook.id;
    final expenseCategory = controller
        .categoriesForBook(travelBookId)
        .firstWhere((category) => category.type == EntryType.expense);
    controller.addEntry(
      LedgerEntry(
        id: 'travel-entry',
        bookId: travelBookId,
        type: EntryType.expense,
        amount: 25,
        categoryId: expenseCategory.id,
        accountId: '',
        note: '旅行午餐',
        occurredAt: DateTime.now(),
      ),
    );
    controller.switchLedgerBook(defaultBookId);
    addTearDown(controller.dispose);

    final transport = _scripted(<List<AiCompletionEvent>>[
      <AiCompletionEvent>[
        const AiToolCallDelta(
          index: 0,
          id: 'call_book',
          name: 'summary',
          arguments: '{"range":"thisMonth"}',
        ),
        const AiCompletionFinished(AiFinishReason.toolCalls),
        const AiStreamDone(),
      ],
      _answer('旅行账本支出 25。'),
    ]);
    await tester.pumpWidget(
      VeriFinScope(
        controller: controller,
        child: zhMaterialApp(home: AiChatPage(debugTransport: transport)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining(defaultBookName), findsWidgets);
    await tester.tap(find.byIcon(Icons.account_balance_wallet_outlined));
    await tester.pumpAndSettle();
    expect(find.text('选择对话账本'), findsOneWidget);
    await tester.tap(find.text('旅行账本'));
    await tester.pumpAndSettle();
    expect(find.textContaining('旅行账本'), findsWidgets);

    await tester.enterText(find.byType(TextField), '帮我汇总');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();

    expect(controller.activeBook.id, defaultBookId);
    expect(find.textContaining('25'), findsWidgets);
  });

  testWidgets('清空聊天记录', (tester) async {
    final controller = await makeController()
      ..setAiSettings(
        const AiSettings(baseUrl: 'http://x/v1', apiKey: 'k', model: 'm'),
      );
    await tester.pumpWidget(
      VeriFinScope(
        controller: controller,
        child: zhMaterialApp(
          home: AiChatPage(
            debugTransport: _scripted(<List<AiCompletionEvent>>[
              _answer('你好呀'),
            ]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '在吗');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();
    expect(find.text('在吗'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('清空'));
    await tester.pumpAndSettle();
    expect(find.text('在吗'), findsNothing);
    controller.dispose();
  });

  testWidgets('网络错误保留友好文案并提供重新回答', (tester) async {
    final controller = await makeController()
      ..setAiSettings(
        const AiSettings(baseUrl: 'http://x/v1', apiKey: 'k', model: 'm'),
      );
    await tester.pumpWidget(
      VeriFinScope(
        controller: controller,
        child: zhMaterialApp(
          home: AiChatPage(
            debugTransport: (messages, tools) async* {
              throw AiException(
                AiErrorCode.network,
                detail: 'HttpException: secret upstream detail',
              );
            },
            debugCompleteTransport: (messages, tools) async {
              throw AiException(
                AiErrorCode.network,
                detail: 'HttpException: secret upstream detail',
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '帮我查一下');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();

    expect(find.text('无法连接到服务器'), findsOneWidget);
    expect(find.text('重新回答'), findsOneWidget);
    expect(find.textContaining('HttpException'), findsNothing);
    expect(find.textContaining('secret upstream'), findsNothing);
    controller.dispose();
  });

  testWidgets('离开并重开页面后不恢复旧对话', (tester) async {
    final controller = await makeController()
      ..setAiSettings(
        const AiSettings(baseUrl: 'http://x/v1', apiKey: 'k', model: 'm'),
      );
    final transport = _scripted(<List<AiCompletionEvent>>[
      _answer('这次回答只在当前页面保留'),
    ]);

    await tester.pumpWidget(
      VeriFinScope(
        controller: controller,
        child: zhMaterialApp(home: AiChatPage(debugTransport: transport)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '分类排行');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();
    expect(find.text('这次回答只在当前页面保留'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await tester.pumpWidget(
      VeriFinScope(
        controller: controller,
        child: zhMaterialApp(home: AiChatPage(debugTransport: transport)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('分类排行'), findsNothing);
    expect(find.text('这次回答只在当前页面保留'), findsNothing);
    addTearDown(controller.dispose);
  });

  testWidgets('Markdown 远程图片不会触发网络加载', (tester) async {
    final controller = await makeController()
      ..setAiSettings(
        const AiSettings(baseUrl: 'http://x/v1', apiKey: 'k', model: 'm'),
      );
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      VeriFinScope(
        controller: controller,
        child: zhMaterialApp(
          home: AiChatPage(
            debugTransport: _scripted(<List<AiCompletionEvent>>[
              _answer('![remote](https://example.com/tracker.png)'),
            ]),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '看看图片');
    await tester.pump();
    await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
    await tester.pumpAndSettle();

    expect(find.text('出于隐私考虑，未加载图片'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) => widget is Image && widget.image is NetworkImage,
      ),
      findsNothing,
    );
  });
}
