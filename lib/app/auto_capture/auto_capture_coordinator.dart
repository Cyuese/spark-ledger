import '../ai/ai_entry_parser.dart';
import 'auto_capture_settings.dart';
import 'notification_prefilter.dart';

/// 一条被原生 NLS/无障碍捕获的支付通知（原始文本 + 来源 + 时间）。
class CapturedNotification {
  const CapturedNotification({
    required this.packageName,
    required this.text,
    required this.postedAt,
  });

  final String packageName;
  final String text;
  final DateTime postedAt;
}

/// 一条捕获通知的处理结果。用于原生侧更新常驻通知状态、以及测试断言。
enum AutoCaptureOutcome {
  /// 自动记账未开启。
  disabledSkip,

  /// 来源 App 不在白名单。
  sourceSkip,

  /// 前置过滤未通过（不含数字，不像交易），未调用 AI。
  prefilterSkip,

  /// AI 判定并非交易（或金额无效），丢弃。
  notTransactionSkip,

  /// 已识别为交易并落账。
  committed,

  /// AI 调用/解析失败（网络等），调用方可存「待解析」草稿兜底。
  failed,
}

/// 把「捕获的通知」跑通「前置过滤 → AI 解析 → 落账」管线。依赖以回调注入，便于测试。
class AutoCaptureCoordinator {
  AutoCaptureCoordinator({
    required this.settingsOf,
    required this.requestDraft,
    required this.commitDraft,
  });

  /// 取当前自动记账配置（实时读取，避免持有过期快照）。
  final AutoCaptureSettings Function() settingsOf;

  /// 调 AI 把通知文本解析成草稿（含 isTransaction 判定）。失败抛异常。
  final Future<AiEntryDraft> Function(CapturedNotification notification)
  requestDraft;

  /// 把已确认为交易的草稿落账。
  final void Function(AiEntryDraft draft, CapturedNotification source)
  commitDraft;

  /// 处理一条捕获的通知，返回处理结果。不抛异常（AI 失败归为 [AutoCaptureOutcome.failed]）。
  Future<AutoCaptureOutcome> process(CapturedNotification notification) async {
    final settings = settingsOf();
    if (!settings.notificationEnabled) {
      return AutoCaptureOutcome.disabledSkip;
    }
    if (!settings.isSourceEnabled(notification.packageName)) {
      return AutoCaptureOutcome.sourceSkip;
    }
    if (!notificationLikelyTransaction(notification.text)) {
      return AutoCaptureOutcome.prefilterSkip;
    }
    final AiEntryDraft draft;
    try {
      draft = await requestDraft(notification);
    } catch (_) {
      return AutoCaptureOutcome.failed;
    }
    if (!draft.isTransaction || draft.amount <= 0) {
      return AutoCaptureOutcome.notTransactionSkip;
    }
    commitDraft(draft, notification);
    return AutoCaptureOutcome.committed;
  }
}
