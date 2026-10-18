import 'dart:async';
import 'dart:ui' show Locale;

import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/ai/ai_agent_engine.dart';
import 'package:verifin/app/ai/ai_agent_step.dart';
import 'package:verifin/app/ai/ai_chat_session_controller.dart';
import 'package:verifin/app/ai/ai_completion_event.dart';
import 'package:verifin/app/ai/ai_ledger_snapshot.dart';
import 'package:verifin/app/ai/ai_query_tool.dart';
import 'package:verifin/app/ai/ai_settings.dart';
import 'package:verifin/app/models.dart';
import 'package:verifin/l10n/app_localizations.dart';

AiChatRequest _request(
  AiAgentStreamTransport stream, {
  AiAgentCompleteTransport? complete,
}) {
  return AiChatRequest(
    text: '本月花了多少',
    ledger: AiLedgerSnapshot.forTesting(
      bookId: 'b',
      bookName: '日常',
      balanceOf: (_) => 0,
    ),
    l10n: lookupAppLocalizations(const Locale('zh')),
    moneyCodeDisplay: MoneyCodeDisplay.none,
    settings: const AiSettings(baseUrl: 'http://x/v1', model: 'm'),
    capability: null,
    mode: AiToolCallMode.native,
    streamTransport: stream,
    completeTransport:
        complete ??
        (_, _) async => throw UnimplementedError('unexpected fallback'),
  );
}

void main() {
  test('session records tool steps, provenance and final answer', () async {
    final controller = AiChatSessionController(
      engine: AiAgentEngine(tools: buildAiQueryTools()),
      onCapabilityDetected: (_) {},
      onError: (_, _, _) {},
    );
    addTearDown(controller.dispose);
    var round = 0;
    final finished = Completer<void>();
    controller.addListener(() {
      if (controller.messages.length == 2 && !controller.isStreaming) {
        if (!finished.isCompleted) finished.complete();
      }
    });
    controller.send(
      _request((_, _) async* {
        round += 1;
        if (round == 1) {
          yield const AiToolCallDelta(
            index: 0,
            id: 'call',
            name: 'summary',
            arguments: '{"range":"thisMonth"}',
          );
          yield const AiCompletionFinished(AiFinishReason.toolCalls);
          yield const AiStreamDone();
        } else {
          yield const AiContentDelta('本月支出 0 元。');
          yield const AiCompletionFinished(AiFinishReason.stop);
          yield const AiStreamDone();
        }
      }),
    );
    await finished.future.timeout(const Duration(seconds: 1));

    final assistant = controller.messages.last;
    expect(assistant.status, AiChatMessageStatus.done);
    expect(assistant.steps.single.status, AiAgentStepStatus.succeeded);
    expect(assistant.successfulToolCalls, 1);
    expect(assistant.provenance?.name, 'ledgerQueried');
    expect(assistant.text, '本月支出 0 元。');
  });

  test('stop keeps partial text and leaves the session idle', () async {
    final controller = AiChatSessionController(
      engine: AiAgentEngine(tools: buildAiQueryTools()),
      onCapabilityDetected: (_) {},
      onError: (_, _, _) {},
    );
    addTearDown(controller.dispose);
    final stream = StreamController<AiCompletionEvent>();
    controller.send(_request((_, _) => stream.stream));
    stream.add(const AiContentDelta('部分正文'));
    await Future<void>.delayed(const Duration(milliseconds: 70));

    controller.stop();

    expect(controller.isStreaming, isFalse);
    expect(controller.messages.last.text, '部分正文');
    expect(controller.messages.last.status, AiChatMessageStatus.done);
    await stream.close();
  });
}
