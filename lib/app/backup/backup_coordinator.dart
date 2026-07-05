import '../veri_fin_controller.dart';
import 'backup_service.dart';
import 'webdav_client.dart';

/// 自动备份协调器：在应用打开与记账后按配置触发自动备份。真正的文件 I/O 在
/// [BackupService]（条件导入存储端口）；控制器只提供配置与数据，不做 I/O。
class BackupCoordinator {
  const BackupCoordinator._();

  static bool _running = false;

  /// 应用打开（冷启动 / 回前台）时调用。
  static Future<void> maybeBackupOnOpen(VeriFinController controller) {
    return _maybeRun(controller, afterEntry: false);
  }

  /// 新增交易后调用。
  static Future<void> maybeBackupAfterEntry(VeriFinController controller) {
    return _maybeRun(controller, afterEntry: true);
  }

  static Future<void> _maybeRun(
    VeriFinController controller, {
    required bool afterEntry,
  }) async {
    final settings = controller.backupSettings;
    final webdav = controller.webdavConfig;
    final now = DateTime.now();
    if (!settings.isFrequencyDue(now, afterEntry: afterEntry)) {
      return;
    }
    final toLocal = settings.hasDirectory;
    final toWebdav = webdav.isConfigured && webdav.autoUpload;
    if (!toLocal && !toWebdav) {
      return;
    }
    // 避免并发重入（打开与记账事件叠加）。
    if (_running) {
      return;
    }
    _running = true;
    var anySucceeded = false;
    try {
      // 准备一次备份内容（未加密→zip、加密→文本信封），本地与 WebDAV 共用同一份。
      final prepared = await BackupService.prepare(
        json: controller.exportDataJson(),
        passphrase: controller.backupPassphrase,
        now: now,
        auto: true,
      );
      if (toLocal) {
        try {
          await BackupService.writeAutoBackup(
            settings: settings,
            content: controller.exportDataJson(),
            now: now,
            passphrase: controller.backupPassphrase,
          );
          anySucceeded = true;
        } catch (_) {
          // 本地目录失败（授权失效等）不影响 WebDAV 尝试。
        }
      }
      if (toWebdav) {
        try {
          await webdavUpload(webdav, prepared.filename, prepared.bytes);
          anySucceeded = true;
        } catch (_) {
          // WebDAV 失败静默。
        }
      }
      if (anySucceeded) {
        controller.recordBackupTime(now);
      }
    } catch (_) {
      // 兜底：任何未预期错误都不打断用户操作。
    } finally {
      _running = false;
    }
  }
}
