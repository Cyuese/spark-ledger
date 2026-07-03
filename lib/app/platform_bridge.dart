import 'package:flutter/services.dart';

class AppPlatformBridge {
  AppPlatformBridge._();

  static const MethodChannel _channel = MethodChannel('verifin/app');

  static void setQuickEntryHandler(Future<void> Function() handler) {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openQuickEntry') {
        await handler();
      }
    });
  }

  static void clearQuickEntryHandler() {
    _channel.setMethodCallHandler(null);
  }

  static Future<bool> consumeInitialQuickEntryIntent() async {
    try {
      return await _channel.invokeMethod<bool>('consumeQuickEntryIntent') ??
          false;
    } on MissingPluginException {
      return false;
    }
  }

  static Future<UpdateCheckResult> checkForUpdate() async {
    try {
      final result = await _channel.invokeMapMethod<String, Object?>(
        'checkForUpdate',
      );
      return UpdateCheckResult.fromMap(result ?? const <String, Object?>{});
    } on MissingPluginException {
      return const UpdateCheckResult(
        status: UpdateCheckStatus.unsupported,
        message: '当前预览环境不支持 Android 应用更新。',
      );
    } on PlatformException catch (error) {
      return UpdateCheckResult(
        status: UpdateCheckStatus.error,
        message: error.message ?? '检查更新失败，请稍后再试。',
      );
    }
  }
}

enum UpdateCheckStatus { installing, upToDate, noAsset, unsupported, error }

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.status,
    required this.message,
    this.currentVersion = '',
    this.latestVersion = '',
  });

  final UpdateCheckStatus status;
  final String message;
  final String currentVersion;
  final String latestVersion;

  static UpdateCheckResult fromMap(Map<String, Object?> map) {
    final statusName = map['status'] as String? ?? 'error';
    return UpdateCheckResult(
      status: UpdateCheckStatus.values.firstWhere(
        (status) => status.name == statusName,
        orElse: () => UpdateCheckStatus.error,
      ),
      message: map['message'] as String? ?? '检查更新失败，请稍后再试。',
      currentVersion: map['currentVersion'] as String? ?? '',
      latestVersion: map['latestVersion'] as String? ?? '',
    );
  }
}
