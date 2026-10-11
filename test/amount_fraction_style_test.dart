import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:verifin/app/models.dart';
import 'package:verifin/local_storage/local_storage.dart';

import 'support/test_harness.dart';

// 金额小数位风格从「强制两位小数」布尔改为 CurrencyFractionStyle 枚举后，设备 KV 与
// 旧备份的兼容读入仍必须生效（键名与字段名都换过）。
void main() {
  useTestDatabases();

  test('旧 KV 键（amount_format）在新键缺失时迁移到 currency_fraction_style', () async {
    final store = LocalKeyValueStore();
    store.write('verifin.amount_format.v1', 'true');
    final controller = await makeController(store);

    expect(controller.currencyFractionStyle, CurrencyFractionStyle.standard);
    await controller.waitForPendingWrites();
    expect(store.read('verifin.currency_fraction_style.v1'), 'standard');
    expect(store.read('verifin.amount_format.v1'), isNull);
    controller.dispose();
  });

  test('新键优先于旧键', () async {
    final store = LocalKeyValueStore();
    store
      ..write('verifin.amount_format.v1', 'true')
      ..write('verifin.currency_fraction_style.v1', 'compact');
    final controller = await makeController(store);
    expect(controller.currencyFractionStyle, CurrencyFractionStyle.compact);
    controller.dispose();
  });

  test('旧备份只有 amountForceTwoDecimals 字段时按标准精度读入', () async {
    final source = await makeController();
    final exported =
        jsonDecode(source.exportDataJson()) as Map<String, Object?>;
    source.dispose();

    final data = Map<String, Object?>.from(exported['data']! as Map);
    data
      ..remove('currencyFractionStyle')
      ..['amountForceTwoDecimals'] = true;
    final legacyJson = jsonEncode(<String, Object?>{...exported, 'data': data});

    final target = await makeController();
    await target.importDataJson(legacyJson);
    expect(target.currencyFractionStyle, CurrencyFractionStyle.standard);
    // 导出只写新字段，不再回写旧布尔别名。
    final reExported =
        jsonDecode(target.exportDataJson()) as Map<String, Object?>;
    final reData = reExported['data']! as Map;
    expect(reData.containsKey('amountForceTwoDecimals'), isFalse);
    expect(reData['currencyFractionStyle'], 'standard');
    target.dispose();
  });
}
