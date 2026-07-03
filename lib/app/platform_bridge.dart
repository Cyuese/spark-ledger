import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class AppPlatformBridge {
  AppPlatformBridge._();

  static const MethodChannel _channel = MethodChannel('verifin/app');
  static Future<void> Function()? _quickEntryHandler;
  static final ValueNotifier<UpdateDownloadProgress?> updateProgress =
      ValueNotifier<UpdateDownloadProgress?>(null);

  static void setQuickEntryHandler(Future<void> Function() handler) {
    _quickEntryHandler = handler;
    _ensureMethodHandler();
  }

  static void clearQuickEntryHandler() {
    _quickEntryHandler = null;
    _ensureMethodHandler();
  }

  static void _ensureMethodHandler() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'openQuickEntry') {
        await _quickEntryHandler?.call();
        return;
      }
      if (call.method == 'updateDownloadProgress') {
        final args = Map<String, Object?>.from(
          call.arguments as Map<dynamic, dynamic>? ?? <dynamic, dynamic>{},
        );
        updateProgress.value = UpdateDownloadProgress.fromMap(args);
      }
    });
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
        'checkLatestRelease',
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

  static Future<UpdateCheckResult> downloadLatestUpdate() async {
    updateProgress.value = const UpdateDownloadProgress(progress: 0);
    try {
      final result = await _channel.invokeMapMethod<String, Object?>(
        'downloadLatestUpdate',
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
        message: error.message ?? '下载更新失败，请稍后再试。',
      );
    }
  }

  static Future<bool> saveTextToDownloads({
    required String filename,
    required String content,
    required String mimeType,
  }) async {
    try {
      return await _channel.invokeMethod<bool>('saveTextToDownloads', {
            'filename': filename,
            'content': content,
            'mimeType': mimeType,
          }) ??
          false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (error) {
      throw Exception(error.message ?? '导出失败，请稍后再试。');
    }
  }
}

enum UpdateCheckStatus {
  available,
  installing,
  upToDate,
  noAsset,
  unsupported,
  error,
}

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

class UpdateDownloadProgress {
  const UpdateDownloadProgress({
    required this.progress,
    this.receivedBytes = 0,
    this.totalBytes = 0,
  });

  final double progress;
  final int receivedBytes;
  final int totalBytes;

  int get percent => (progress.clamp(0, 1) * 100).round();

  static UpdateDownloadProgress fromMap(Map<String, Object?> map) {
    return UpdateDownloadProgress(
      progress: (map['progress'] as num? ?? 0)
          .toDouble()
          .clamp(0, 1)
          .toDouble(),
      receivedBytes: (map['receivedBytes'] as num? ?? 0).toInt(),
      totalBytes: (map['totalBytes'] as num? ?? 0).toInt(),
    );
  }
}
