import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'ai_error.dart';
import 'ai_settings.dart';

export 'ai_error.dart' show AiException, AiErrorCode, aiErrorMessage;

/// 向 OpenAI 兼容的聊天补全接口发一次请求，返回助手消息的文本内容。
///
/// [messages] 未指定时用 [systemPrompt]/[userPrompt] 组两条消息。请求体不带
/// `response_format`（不少自建/第三方端点不支持），靠提示词约束输出，由调用方
/// 从文本中提取 JSON，兼容性最好。[temperature] 默认 0 让解析结果稳定。
Future<String> aiChatComplete({
  required AiSettings settings,
  String? systemPrompt,
  String? userPrompt,
  List<Map<String, String>>? messages,
  double temperature = 0,
  Duration timeout = const Duration(seconds: 45),
}) async {
  if (!settings.isConfigured) {
    throw AiException(AiErrorCode.notConfigured);
  }
  final resolvedMessages =
      messages ??
      <Map<String, String>>[
        if (systemPrompt != null) {'role': 'system', 'content': systemPrompt},
        if (userPrompt != null) {'role': 'user', 'content': userPrompt},
      ];
  final body = jsonEncode(<String, Object?>{
    'model': settings.model.trim(),
    'messages': resolvedMessages,
    'temperature': temperature,
    'stream': false,
  });

  final client = HttpClient();
  client.connectionTimeout = timeout;
  try {
    final uri = Uri.parse(settings.chatCompletionsUrl);
    final request = await client.openUrl('POST', uri).timeout(timeout);
    request.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer ${settings.apiKey.trim()}',
    );
    request.headers.contentType = ContentType(
      'application',
      'json',
      charset: 'utf-8',
    );
    request.followRedirects = true;
    request.add(utf8.encode(body));

    final response = await request.close().timeout(timeout);
    final responseText = await response
        .transform(utf8.decoder)
        .join()
        .timeout(timeout);
    if (response.statusCode >= 400) {
      throw _statusException(response.statusCode, responseText);
    }
    return _extractContent(responseText);
  } on AiException {
    rethrow;
  } on TimeoutException {
    throw AiException(AiErrorCode.timeout);
  } on SocketException catch (error) {
    throw AiException(AiErrorCode.network, detail: error.message);
  } on HandshakeException {
    throw AiException(AiErrorCode.tls);
  } on FormatException {
    throw AiException(AiErrorCode.badUrl);
  } catch (error) {
    throw AiException(AiErrorCode.unknown, detail: '$error');
  } finally {
    client.close(force: true);
  }
}

/// 流式版聊天补全（SSE）：逐段 `yield` 助手消息文本增量（`choices[0].delta.content`）。
///
/// 对话主循环用它把最终答复逐字呈现给用户；工具调用轮次则在上层缓冲后解析。
/// 出错（配置缺失、鉴权失败、网络/TLS 等）抛 [AiException]，与非流式一致。
Stream<String> aiChatStream({
  required AiSettings settings,
  required List<Map<String, String>> messages,
  double temperature = 0,
  Duration timeout = const Duration(seconds: 60),
}) async* {
  if (!settings.isConfigured) {
    throw AiException(AiErrorCode.notConfigured);
  }
  final body = jsonEncode(<String, Object?>{
    'model': settings.model.trim(),
    'messages': messages,
    'temperature': temperature,
    'stream': true,
  });

  final client = HttpClient();
  client.connectionTimeout = timeout;
  try {
    final uri = Uri.parse(settings.chatCompletionsUrl);
    final request = await client.openUrl('POST', uri).timeout(timeout);
    request.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer ${settings.apiKey.trim()}',
    );
    request.headers.contentType = ContentType(
      'application',
      'json',
      charset: 'utf-8',
    );
    request.headers.set(HttpHeaders.acceptHeader, 'text/event-stream');
    request.followRedirects = true;
    request.add(utf8.encode(body));

    final response = await request.close().timeout(timeout);
    if (response.statusCode >= 400) {
      final errorText = await response.transform(utf8.decoder).join();
      throw _statusException(response.statusCode, errorText);
    }

    final lines = response
        .transform(utf8.decoder)
        .transform(const LineSplitter());
    await for (final line in lines) {
      if (!line.startsWith('data:')) {
        continue;
      }
      final data = line.substring(5).trim();
      if (data.isEmpty) {
        continue;
      }
      if (data == '[DONE]') {
        break;
      }
      final delta = _extractStreamDelta(data);
      if (delta != null && delta.isNotEmpty) {
        yield delta;
      }
    }
  } on AiException {
    rethrow;
  } on TimeoutException {
    throw AiException(AiErrorCode.timeout);
  } on SocketException catch (error) {
    throw AiException(AiErrorCode.network, detail: error.message);
  } on HandshakeException {
    throw AiException(AiErrorCode.tls);
  } on FormatException {
    throw AiException(AiErrorCode.badUrl);
  } catch (error) {
    throw AiException(AiErrorCode.unknown, detail: '$error');
  } finally {
    client.close(force: true);
  }
}

/// 从一条 SSE `data:` 负载里取出文本增量；解析失败返回 null（跳过该片段）。
String? _extractStreamDelta(String data) {
  try {
    final decoded = jsonDecode(data);
    if (decoded is Map) {
      final choices = decoded['choices'];
      if (choices is List && choices.isNotEmpty) {
        final first = choices.first;
        if (first is Map) {
          final delta = first['delta'];
          if (delta is Map && delta['content'] is String) {
            return delta['content'] as String;
          }
          // 兼容部分端点把增量放在 text 字段。
          if (first['text'] is String) {
            return first['text'] as String;
          }
        }
      }
    }
  } catch (_) {
    // 忽略非标准片段。
  }
  return null;
}

String _extractContent(String responseText) {
  final Object? decoded;
  try {
    decoded = jsonDecode(responseText);
  } catch (_) {
    throw AiException(AiErrorCode.badResponse, detail: 'non-JSON');
  }
  if (decoded is! Map) {
    throw AiException(AiErrorCode.badResponse);
  }
  final choices = decoded['choices'];
  if (choices is List && choices.isNotEmpty) {
    final first = choices.first;
    if (first is Map) {
      final message = first['message'];
      if (message is Map) {
        final content = message['content'];
        if (content is String && content.trim().isNotEmpty) {
          return content;
        }
      }
      // 兼容部分端点把文本放在 text 字段。
      final text = first['text'];
      if (text is String && text.trim().isNotEmpty) {
        return text;
      }
    }
  }
  // 上游透传的错误对象。
  final error = decoded['error'];
  if (error is Map && error['message'] is String) {
    throw AiException(AiErrorCode.upstream, detail: error['message'] as String);
  }
  throw AiException(AiErrorCode.badResponse, detail: 'empty content');
}

/// 把 HTTP 错误状态映射为错误码；优先把上游 error.message 作为 detail 透出。
AiException _statusException(int statusCode, String responseText) {
  String? detail;
  try {
    final decoded = jsonDecode(responseText);
    if (decoded is Map) {
      final error = decoded['error'];
      if (error is Map && error['message'] is String) {
        detail = error['message'] as String;
      } else if (decoded['message'] is String) {
        detail = decoded['message'] as String;
      }
    }
  } catch (_) {
    // 忽略，仅按状态码分类。
  }
  final code = switch (statusCode) {
    401 || 403 => AiErrorCode.authFailed,
    404 => AiErrorCode.notFound,
    429 => AiErrorCode.rateLimited,
    _ => AiErrorCode.serverError,
  };
  return AiException(code, detail: detail ?? '$statusCode');
}
