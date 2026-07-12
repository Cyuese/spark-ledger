import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../models.dart';
import 'raw_import.dart';
import 'text_format.dart';

/// Tally 记账「备份」：zip 内含 `backup_data.json`（Gson 全量数据）。取 records 数组逐条
/// 归一，assets 数组给出账户余额/类型（经 [ParsedImport.accounts] 交由 plan_builder 回推
/// 初始余额、补建无流水账户）。相较其 CSV「账单」导出无损——交易时间为 epoch 毫秒，直接
/// 构造 [DateTime]、金额本就是 double，全程不经字符串中转。基于用户真实样例。
ParsedImport parseTally(Uint8List bytes) {
  final Archive archive;
  try {
    archive = ZipDecoder().decodeBytes(bytes);
  } catch (_) {
    throw const FormatException('无法读取 Tally 备份（可能不是有效的 zip 文件）');
  }
  String? jsonText;
  for (final file in archive.files) {
    if (file.isFile &&
        (file.name == 'backup_data.json' ||
            file.name.endsWith('/backup_data.json'))) {
      jsonText = utf8.decode(file.content as List<int>);
      break;
    }
  }
  if (jsonText == null) {
    throw const FormatException(
      '未找到 Tally 备份数据 backup_data.json，请确认选择的是 Tally 导出的备份 zip',
    );
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(jsonText);
  } catch (_) {
    throw const FormatException('Tally 备份数据格式无效（JSON 解析失败）');
  }
  if (decoded is! Map) {
    throw const FormatException('Tally 备份数据格式无效');
  }

  // 资产 id → 名称（供交易账户解析），以及资产账户元数据（供余额/类型导入）。
  final assetNames = <int, String>{};
  final accounts = <RawImportAccount>[];
  // 同一份备份内可能有重名资产（如两个都叫「现金」的钱包），Tally 靠 assetId 区分。沿用
  // 同名会被 plan_builder 折叠成一个账户、余额相互覆盖，故对重名追加「 (n)」后缀，使全链路
  // （交易账户 / 建账户 / 余额回推）都当作各自独立的账户。
  final usedNames = <String>{};
  final assets = decoded['assets'];
  if (assets is List) {
    for (final asset in assets) {
      if (asset is! Map) {
        continue;
      }
      final id = (asset['id'] as num?)?.toInt();
      final rawName = asset['name']?.toString().trim() ?? '';
      if (rawName.isEmpty) {
        continue;
      }
      var name = rawName;
      var suffix = 2;
      while (usedNames.contains(name)) {
        name = '$rawName ($suffix)';
        suffix++;
      }
      usedNames.add(name);
      if (id != null) {
        assetNames[id] = name;
      }
      final rawType = (asset['type'] as num?)?.toInt() ?? 0;
      final amount = (asset['amount'] as num?)?.toDouble() ?? 0;
      // amount 恒为正，符号由 type 决定：负债(1)/分期(4)减少总资产、记负；资产(0)/借出(2)/
      // 理财(3)记正。isIncludedInTotal 缺省视为 true（兼容老数据）。
      final signed = (rawType == 1 || rawType == 4)
          ? -amount.abs()
          : amount.abs();
      accounts.add(
        RawImportAccount(
          name: name,
          signedBalance: signed,
          includeInAssets: asset['isIncludedInTotal'] as bool? ?? true,
          type: _tallyAccountType(rawType),
        ),
      );
    }
  }

  // records 可缺省 / 为空：允许「只有账户、没有流水」的备份也能导入账户余额。但一个既无
  // assets 又无 records 的文件基本不是 Tally 备份，视为格式错误。
  final records = decoded['records'];
  if (records is! List) {
    if (accounts.isEmpty) {
      throw const FormatException('Tally 备份不含交易记录（records）');
    }
    return ParsedImport(accounts: accounts);
  }

  final out = <RawImportRecord>[];
  for (final record in records) {
    if (record is! Map) {
      continue;
    }
    final millis = (record['date'] as num?)?.toInt();
    final amount = ((record['amount'] as num?)?.toDouble() ?? 0).abs();
    if (millis == null || amount == 0) {
      continue;
    }
    final type = (record['type'] as num?)?.toInt() ?? 0;
    final date = DateTime.fromMillisecondsSinceEpoch(millis);
    final assetId = (record['assetId'] as num?)?.toInt() ?? 0;
    final accountName = assetNames[assetId] ?? '';
    final noteRaw = record['note']?.toString().trim() ?? '';
    final remark = record['remark']?.toString().trim() ?? '';

    if (type == 2) {
      // 转账：从 note 拆出转出/转入账户；转出为空时回退到 assetId 对应账户。
      final transfer = _parseTallyTransferNote(noteRaw);
      out.add(
        RawImportRecord(
          date: date,
          type: EntryType.transfer,
          amount: amount,
          account: transfer.from.isNotEmpty ? transfer.from : accountName,
          toAccount: transfer.to,
          note: transfer.note,
        ),
      );
      continue;
    }

    final level1 = record['category']?.toString().trim() ?? '';
    final level2 = record['subCategory']?.toString().trim() ?? '';
    out.add(
      RawImportRecord(
        date: date,
        type: type == 1 ? EntryType.income : EntryType.expense,
        amount: amount,
        // 分类取二级（叶子）为空回退一级（Tally 不还原父子层级，直接落叶子）。
        category: level2.isNotEmpty ? level2 : level1,
        account: accountName,
        note: joinNote(<String>[noteRaw, remark]),
      ),
    );
  }
  return ParsedImport(records: out, accounts: accounts);
}

/// 把 Tally 的资产类型（0资产/1负债/2借出/3理财/4分期）映射到 Veri Fin 账户类型。
/// Veri Fin 无「负债/借出」独立类型（靠余额正负区分），故负债/分期只影响余额符号；理财归
/// investment，其余用 cash（与默认一致）。
AccountType _tallyAccountType(int type) =>
    type == 3 ? AccountType.investment : AccountType.cash;

/// Tally 转账 note 拆解结果：转出账户、转入账户、剩余用户备注。
class _TallyTransfer {
  const _TallyTransfer(this.from, this.to, this.note);

  final String from;
  final String to;
  final String note;
}

/// 解析 Tally 转账 note："转出 -> 转入" 可能尾随 " (账单:X 优惠:Y)" 与 " | 备注: 备注"。
/// 只剥离带明确关键字的优惠/账单尾注与用户备注，不动账户名内部的括号（如「招商(0966)」），
/// 宁可保留货币模式下的 "(¥100.00)" 由用户在预览里改，也不误删真实账户名的括号。
_TallyTransfer _parseTallyTransferNote(String raw) {
  var base = raw;
  var userNote = '';
  const marker = ' | 备注: ';
  final markerIndex = base.indexOf(marker);
  if (markerIndex >= 0) {
    userNote = base.substring(markerIndex + marker.length).trim();
    base = base.substring(0, markerIndex);
  }
  base = base.replaceAll(RegExp(r'\s*\((?:账单|优惠)[^)]*\)\s*$'), '').trim();
  final arrow = base.indexOf(' -> ');
  if (arrow < 0) {
    return _TallyTransfer('', '', userNote.isEmpty ? base.trim() : userNote);
  }
  return _TallyTransfer(
    base.substring(0, arrow).trim(),
    base.substring(arrow + 4).trim(),
    userNote,
  );
}
