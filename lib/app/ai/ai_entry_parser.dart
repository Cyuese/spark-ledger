import 'dart:convert';

import '../models.dart';
import 'ai_client.dart';
import 'ai_settings.dart';

/// 一个可选项（分类或账户），供 AI 从中挑选并回传 id。
class AiOption {
  const AiOption({required this.id, required this.label});

  final String id;
  final String label;
}

/// 喂给 AI 的账本上下文：可选的分类/账户清单、今天日期、当前账本。
/// 由调用方（记账入口）从 controller 组装，保持解析逻辑纯净可测。
class AiEntryContext {
  const AiEntryContext({
    required this.expenseCategories,
    required this.incomeCategories,
    required this.accounts,
    required this.today,
    required this.bookId,
  });

  final List<AiOption> expenseCategories;
  final List<AiOption> incomeCategories;
  final List<AiOption> accounts;
  final DateTime today;
  final String bookId;
}

/// 解析降级提示的类型（UI 侧本地化展示）。
enum AiDraftWarning { categoryUnmatched, accountUnmatched }

/// 解析失败的可预期原因（UI 侧本地化展示）。
enum AiEntryError { emptyResult, noAmount }

/// 解析阶段（非网络）失败时抛出，UI 按 [error] 本地化提示。
class AiEntryException implements Exception {
  AiEntryException(this.error);

  final AiEntryError error;

  @override
  String toString() => 'AiEntryException($error)';
}

/// AI 解析出的交易草稿，落账前交给用户在记账页确认/修改。
class AiEntryDraft {
  const AiEntryDraft({
    required this.type,
    required this.amount,
    required this.categoryId,
    required this.accountId,
    required this.toAccountId,
    required this.note,
    required this.occurredAt,
    this.warnings = const <AiDraftWarning>[],
    this.isTransaction = true,
  });

  final EntryType type;
  final double amount;
  final String categoryId;

  /// 空串表示「无账户」。
  final String accountId;
  final String? toAccountId;
  final String note;
  final DateTime occurredAt;

  /// 解析过程中的降级提示（如分类未识别已用默认），供 UI 本地化展示，不阻断落账。
  final List<AiDraftWarning> warnings;

  /// 是否是一笔真实交易。手动/对话记账恒为 true；通知自动记账时由 AI 判断——
  /// 通知可能是营销/系统提示等非交易内容，此时为 false，调用方应丢弃、不落账。
  final bool isTransaction;
}

String _dateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// 构造系统提示词：说明任务、可选清单与严格 JSON 输出格式。
/// 提示词本身非用户可见文案，用中文书写并要求保留用户输入的原语言。
String buildAiEntryPrompt(AiEntryContext context) {
  String optionsBlock(List<AiOption> options) {
    if (options.isEmpty) {
      return '（无）';
    }
    return options.map((o) => '- ${o.id} | ${o.label}').join('\n');
  }

  final accountsBlock = context.accounts.isEmpty
      ? '（无）'
      : context.accounts.map((o) => '- ${o.id} | ${o.label}').join('\n');

  return '''
你是一个记账助手。请把用户用自然语言描述的一笔账，解析成一个 JSON 对象。
今天的日期是 ${_dateKey(context.today)}（用于解析「今天」「昨天」「前天」等相对日期）。

只能从下面给定的清单里选择 categoryId 和 accountId，必须原样回传清单中的 id，不要自造 id。

支出分类（categoryId 从这里选）：
${optionsBlock(context.expenseCategories)}

收入分类（categoryId 从这里选）：
${optionsBlock(context.incomeCategories)}

账户（accountId / toAccountId 从这里选）：
$accountsBlock

判断规则：
- type：支出用 "expense"，收入用 "income"，账户间转账用 "transfer"。默认为 "expense"。
- amount：正数金额（不带货币符号）。无法识别金额时置为 0。
- categoryId：按 type 从对应清单里选最贴切的一项；转账可留空字符串。
- accountId：从账户清单选最贴切的；用户没提到账户就留空字符串 ""（表示无账户）。
- toAccountId：仅转账时填转入账户 id，否则为 null。
- note：一句话备注，保留用户输入的原始语言；没有额外信息就留空字符串。
- date：形如 "YYYY-MM-DD"，默认今天。

只输出一个 JSON 对象，不要任何解释、不要 Markdown 代码块。格式：
{"type":"expense","amount":32,"categoryId":"transport","accountId":"","toAccountId":null,"note":"打车","date":"${_dateKey(context.today)}"}
''';
}

/// 从模型返回的文本里提取第一个 JSON 对象（容忍 ```json 代码块与多余文字）。
Map<String, Object?>? extractJsonObject(String content) {
  final start = content.indexOf('{');
  final end = content.lastIndexOf('}');
  if (start < 0 || end <= start) {
    return null;
  }
  final slice = content.substring(start, end + 1);
  try {
    final decoded = jsonDecode(slice);
    if (decoded is Map) {
      return Map<String, Object?>.from(decoded);
    }
  } catch (_) {
    return null;
  }
  return null;
}

EntryType _parseType(Object? raw) {
  final value = raw?.toString().trim().toLowerCase() ?? '';
  switch (value) {
    case 'income':
    case '收入':
      return EntryType.income;
    case 'transfer':
    case '转账':
      return EntryType.transfer;
    default:
      return EntryType.expense;
  }
}

double _parseAmount(Object? raw) {
  if (raw is num) {
    return raw.toDouble().abs();
  }
  if (raw is String) {
    final cleaned = raw.replaceAll(RegExp(r'[^0-9.\-]'), '');
    return (double.tryParse(cleaned) ?? 0).abs();
  }
  return 0;
}

DateTime _parseDate(Object? raw, DateTime fallback) {
  if (raw is String) {
    final match = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})').firstMatch(raw.trim());
    if (match != null) {
      final y = int.tryParse(match.group(1)!);
      final m = int.tryParse(match.group(2)!);
      final d = int.tryParse(match.group(3)!);
      if (y != null && m != null && d != null && m >= 1 && m <= 12) {
        return DateTime(y, m, d, fallback.hour, fallback.minute);
      }
    }
  }
  return fallback;
}

/// 把模型返回的文本解析成交易草稿，并把 id 校验到给定清单（未命中则降级 + 提示）。
/// 无法识别金额时抛 [AiException]（无金额无法记账）。
AiEntryDraft parseAiEntryDraft(String content, AiEntryContext context) {
  final json = extractJsonObject(content);
  if (json == null) {
    throw AiEntryException(AiEntryError.emptyResult);
  }

  final warnings = <AiDraftWarning>[];
  final type = _parseType(json['type']);
  final amount = _parseAmount(json['amount']);
  if (amount <= 0) {
    throw AiEntryException(AiEntryError.noAmount);
  }

  final categories = type == EntryType.income
      ? context.incomeCategories
      : context.expenseCategories;
  final categoryIds = categories.map((o) => o.id).toSet();
  var categoryId = (json['categoryId'] as String?)?.trim() ?? '';
  if (categoryId.isEmpty || !categoryIds.contains(categoryId)) {
    if (type == EntryType.transfer) {
      categoryId = '';
    } else if (categories.isNotEmpty) {
      final wasNonEmpty = categoryId.isNotEmpty;
      categoryId = categories.first.id;
      if (wasNonEmpty) {
        warnings.add(AiDraftWarning.categoryUnmatched);
      }
    } else {
      categoryId = '';
    }
  }

  final accountIds = context.accounts.map((o) => o.id).toSet();
  var accountId = (json['accountId'] as String?)?.trim() ?? '';
  if (accountId.isNotEmpty && !accountIds.contains(accountId)) {
    warnings.add(AiDraftWarning.accountUnmatched);
    accountId = '';
  }

  String? toAccountId;
  if (type == EntryType.transfer) {
    final raw = (json['toAccountId'] as String?)?.trim() ?? '';
    toAccountId = (raw.isNotEmpty && accountIds.contains(raw)) ? raw : null;
  }

  final note = (json['note'] as String?)?.trim() ?? '';
  final occurredAt = _parseDate(json['date'], context.today);

  return AiEntryDraft(
    type: type,
    amount: amount,
    categoryId: categoryId,
    accountId: accountId,
    toAccountId: toAccountId,
    note: note,
    occurredAt: occurredAt,
    warnings: warnings,
  );
}

/// 发起一次 AI 记账解析：请求 → 解析 → 校验，返回草稿。网络/解析异常抛 [AiException]。
Future<AiEntryDraft> requestAiEntryDraft({
  required AiSettings settings,
  required String input,
  required AiEntryContext context,
}) async {
  final content = await aiChatComplete(
    settings: settings,
    systemPrompt: buildAiEntryPrompt(context),
    userPrompt: input.trim(),
  );
  return parseAiEntryDraft(content, context);
}

/// 构造「通知/账单文本 → 交易」的系统提示词。与 [buildAiEntryPrompt] 的差别：
/// 输入是一条支付/银行通知原文（可能并非交易），要求模型先判断 `isTransaction`，
/// 再按需提取字段。用于自动记账（NLS/无障碍）通道。
String buildNotificationEntryPrompt(AiEntryContext context) {
  final base = buildAiEntryPrompt(context);
  return '''
$base

补充说明（自动记账场景）：
- 下面给你的不是用户主动描述，而是一条来自支付/银行 App 的通知原文，可能并不是一笔交易（如营销、活动、系统提示、验证码、聊天消息等）。
- 先判断它是否是一笔真实的收支或转账。是则 "isTransaction" 为 true 并正常填写各字段；不是则 "isTransaction" 为 false，其余字段可留默认。
- 银行「收款/入账」通常是收入或账户间转账，「支出/消费/付款」通常是支出——按文本判断，拿不准时按字面。
- 输出 JSON 需额外包含 "isTransaction" 布尔字段，例如：
{"isTransaction":true,"type":"expense","amount":12.5,"categoryId":"food","accountId":"","toAccountId":null,"note":"星巴克","date":"${_dateKey(context.today)}"}
''';
}

/// 解析通知自动记账的模型返回：容忍「非交易」（返回 `isTransaction:false` 的草稿，不抛错）。
/// 判为交易但金额无效时也按「非交易」处理，避免落一笔金额为 0 的脏数据。
AiEntryDraft parseNotificationEntryDraft(
  String content,
  AiEntryContext context,
) {
  final json = extractJsonObject(content);
  if (json == null) {
    throw AiEntryException(AiEntryError.emptyResult);
  }
  final isTransaction = _parseBool(json['isTransaction'], defaultValue: true);
  if (!isTransaction) {
    return _notATransaction(context);
  }
  final amount = _parseAmount(json['amount']);
  if (amount <= 0) {
    return _notATransaction(context);
  }
  // 金额有效则复用主解析路径（含 id 校验与降级提示）。
  final draft = parseAiEntryDraft(content, context);
  return AiEntryDraft(
    type: draft.type,
    amount: draft.amount,
    categoryId: draft.categoryId,
    accountId: draft.accountId,
    toAccountId: draft.toAccountId,
    note: draft.note,
    occurredAt: draft.occurredAt,
    warnings: draft.warnings,
    isTransaction: true,
  );
}

AiEntryDraft _notATransaction(AiEntryContext context) => AiEntryDraft(
  type: EntryType.expense,
  amount: 0,
  categoryId: '',
  accountId: '',
  toAccountId: null,
  note: '',
  occurredAt: context.today,
  isTransaction: false,
);

bool _parseBool(Object? raw, {required bool defaultValue}) {
  if (raw is bool) {
    return raw;
  }
  if (raw is String) {
    final value = raw.trim().toLowerCase();
    if (value == 'true' || value == '是' || value == '1') {
      return true;
    }
    if (value == 'false' || value == '否' || value == '0') {
      return false;
    }
  }
  if (raw is num) {
    return raw != 0;
  }
  return defaultValue;
}

/// 发起一次通知自动记账解析：请求 → 解析（含非交易判定）。网络/空结果异常抛 [AiEntryException]。
Future<AiEntryDraft> requestNotificationEntryDraft({
  required AiSettings settings,
  required String notificationText,
  required AiEntryContext context,
}) async {
  final content = await aiChatComplete(
    settings: settings,
    systemPrompt: buildNotificationEntryPrompt(context),
    userPrompt: notificationText.trim(),
  );
  return parseNotificationEntryDraft(content, context);
}
