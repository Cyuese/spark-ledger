/// 通知「可能是一笔交易」的廉价本地判断：文本必须包含数字（金额的必要条件）。
///
/// 用于在调用 AI 前过滤掉绝大多数噪音通知（聊天、系统提示等），省 Token——
/// 只有含数字的通知才值得花一次 AI 调用。真正「是不是交易」由 AI 的
/// `isTransaction` 判断兜底。宁可放过（false negative 少）也别滥调 AI。
bool notificationLikelyTransaction(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) {
    return false;
  }
  return RegExp(r'\d').hasMatch(trimmed);
}
