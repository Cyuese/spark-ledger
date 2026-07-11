import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/local_storage/local_storage.dart';

import 'support/test_harness.dart';

void main() {
  useTestDatabases();

  test('聊天记录落库并在重启后恢复', () async {
    final store = LocalKeyValueStore();
    final controller = await makeController(store);
    controller.setAiChatHistory(<Map<String, String>>[
      <String, String>{'role': 'user', 'content': '本月花了多少'},
      <String, String>{'role': 'assistant', 'content': '本月支出 300 元'},
    ]);
    controller.dispose();

    // 同一 store 重新载入（模拟重启）。
    final reopened = await makeController(store);
    expect(reopened.aiChatHistory.length, 2);
    expect(reopened.aiChatHistory.first['content'], '本月花了多少');
    expect(reopened.aiChatHistory.last['role'], 'assistant');
    reopened.dispose();
  });

  test('清空聊天记录', () async {
    final store = LocalKeyValueStore();
    final controller = await makeController(store);
    controller.setAiChatHistory(<Map<String, String>>[
      <String, String>{'role': 'user', 'content': 'hi'},
    ]);
    controller.clearAiChatHistory();
    expect(controller.aiChatHistory, isEmpty);

    final reopened = await makeController(store);
    expect(reopened.aiChatHistory, isEmpty);
    controller.dispose();
    reopened.dispose();
  });

  test('初始化数据保留聊天记录（设备本地、不随数据清除）', () async {
    final controller = await makeController();
    controller.setAiChatHistory(<Map<String, String>>[
      <String, String>{'role': 'user', 'content': '记得我'},
    ]);
    controller.resetAllData();
    expect(controller.aiChatHistory.length, 1);
    expect(controller.aiChatHistory.first['content'], '记得我');
    controller.dispose();
  });
}
