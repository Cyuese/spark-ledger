import 'ai_error.dart';
import 'ai_settings.dart';

export 'ai_error.dart' show AiException, AiErrorCode, aiErrorMessage;

/// 测试宿主（无 dart:io）不支持网络请求。
Future<String> aiChatComplete({
  required AiSettings settings,
  String? systemPrompt,
  String? userPrompt,
  List<Map<String, String>>? messages,
  double temperature = 0,
  Duration timeout = const Duration(seconds: 45),
}) async {
  throw AiException(AiErrorCode.notSupported);
}

/// 测试宿主（无 dart:io）不支持流式网络请求。
Stream<String> aiChatStream({
  required AiSettings settings,
  required List<Map<String, String>> messages,
  double temperature = 0,
  Duration timeout = const Duration(seconds: 60),
}) async* {
  throw AiException(AiErrorCode.notSupported);
}
