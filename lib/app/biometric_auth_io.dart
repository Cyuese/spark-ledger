import 'dart:io';

import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

/// 生物识别系统弹窗的中文文案。不传时 `local_auth` 会用英文默认串（取消 / 指纹
/// 提示等），与中文 `localizedReason` 混在一起显示，故这里统一为中文。
const AndroidAuthMessages _androidAuthMessages = AndroidAuthMessages(
  signInTitle: '生物解锁',
  biometricHint: '验证身份',
  biometricNotRecognized: '未能识别，请重试',
  biometricRequiredTitle: '需要生物识别',
  biometricSuccess: '验证成功',
  cancelButton: '取消',
  deviceCredentialsRequiredTitle: '需要生物识别',
  deviceCredentialsSetupDescription: '请在系统设置中录入生物识别',
  goToSettingsButton: '前往设置',
  goToSettingsDescription: '尚未录入生物识别，请在系统设置中添加',
);

/// 移动平台的生物识别实现。只调用系统能力（`local_auth`），不保存任何生物特征
/// 数据；系统生物信息录入变化时系统会失效并要求重新验证。仅在 Android/iOS 生效，
/// 其它平台（含测试宿主）一律不可用，因此不会真正触碰平台通道。
class BiometricAuth {
  const BiometricAuth();

  static final LocalAuthentication _auth = LocalAuthentication();

  bool get _supported => Platform.isAndroid || Platform.isIOS;

  Future<bool> isAvailable() async {
    if (!_supported) {
      return false;
    }
    try {
      if (!await _auth.isDeviceSupported()) {
        return false;
      }
      if (!await _auth.canCheckBiometrics) {
        return false;
      }
      final available = await _auth.getAvailableBiometrics();
      return available.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<bool> authenticate({required String reason}) async {
    if (!_supported) {
      return false;
    }
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        authMessages: const <AuthMessages>[_androidAuthMessages],
        options: const AuthenticationOptions(
          // 只用系统生物识别，不回落到设备 PIN/图案。
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
