import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/widgets/widget_catalog.dart';
import 'package:verifin/app/widgets/widget_instance_config.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const homeWidget = MethodChannel('home_widget');
  const app = MethodChannel('verifin/app');

  const booksJson = '[{"id":"book-1","name":"个人"},{"id":"book-2","name":"旅行"}]';

  void mockChannels({
    String? storedConfig,
    bool saveReturnsTrue = true,
    List<String>? calls,
  }) {
    var stored = storedConfig;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeWidget, (call) async {
          calls?.add(call.method);
          switch (call.method) {
            case 'initiallyLaunchedFromHomeWidgetConfigure':
              return '42';
            case 'getWidgetData':
              final key = (call.arguments as Map)['id'] as String;
              if (key == widgetBooksKey) return booksJson;
              if (key == '${widgetConfigPrefix}42') return stored;
              return null;
            case 'saveWidgetData':
              final args = call.arguments as Map;
              stored = args['data'] as String;
              return saveReturnsTrue;
            case 'finishHomeWidgetConfigure':
              return null;
          }
          return null;
        });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(app, (call) async {
          calls?.add('app:${call.method}');
          if (call.method == 'widgetConfigurationInfo') {
            return <String, Object?>{
              'template': 'net_worth',
              'provider': 'top.talyra42.verifin.NetWorthWidgetProvider',
            };
          }
          return null;
        });
  }

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(homeWidget, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(app, null);
  });

  test('读取已保存的实例配置：账本与外观', () async {
    mockChannels(
      storedConfig: jsonEncode(<String, String>{
        'bookId': 'book-2',
        'appearance': 'dark',
      }),
    );
    final session = await WidgetSetupSession.load();
    expect(session.widgetId, 42);
    expect(session.template, WidgetTemplate.netWorth);
    expect(session.books, <String, String>{'book-1': '个人', 'book-2': '旅行'});
    expect(session.config?.bookId, 'book-2');
    expect(session.config?.appearance, WidgetAppearance.dark);
  });

  test('未配置的实例不替用户挑账本，外观回退跟随系统', () async {
    mockChannels();
    final session = await WidgetSetupSession.load();
    expect(session.config, isNull);
    expect(WidgetAppearance.fallback, WidgetAppearance.system);
  });

  test('保存前必须选好本账本内的账本，写回后校验再刷新实例', () async {
    final calls = <String>[];
    mockChannels(calls: calls);
    final session = await WidgetSetupSession.load();

    await expectLater(
      session.save(
        const WidgetInstanceConfig(
          bookId: 'missing',
          appearance: WidgetAppearance.light,
        ),
      ),
      throwsA(isA<StateError>()),
    );
    expect(calls, isNot(contains('saveWidgetData')));

    await session.save(
      const WidgetInstanceConfig(
        bookId: 'book-1',
        appearance: WidgetAppearance.light,
      ),
    );
    expect(calls.where((call) => call == 'saveWidgetData').length, 1);
    expect(calls, contains('app:refreshWidgetInstance'));
    expect(calls, contains('finishHomeWidgetConfigure'));
  });

  test('配置编码可往返，损坏或缺失账本一律视为未配置', () {
    const config = WidgetInstanceConfig(
      bookId: 'book-1',
      appearance: WidgetAppearance.dark,
    );
    final decoded = WidgetInstanceConfig.decode(config.encode())!;
    expect(decoded.bookId, 'book-1');
    expect(decoded.appearance, WidgetAppearance.dark);

    expect(WidgetInstanceConfig.decode(null), isNull);
    expect(WidgetInstanceConfig.decode(''), isNull);
    expect(WidgetInstanceConfig.decode('not json'), isNull);
    expect(WidgetInstanceConfig.decode('{"bookId":""}'), isNull);
    expect(
      WidgetInstanceConfig.decode('{"bookId":"b"}')!.appearance,
      WidgetAppearance.system,
    );
  });
}
