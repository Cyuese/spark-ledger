import 'dart:io';

import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';

import '../l10n/app_localizations.dart';

/// 生物识别系统弹窗文案。不传时 `local_auth` 会用英文默认串，与
/// `localizedReason` 语言不一致，故按当前语言组装。
AndroidAuthMessages _androidAuthMessages(AppLocalizations l10n) {
  return AndroidAuthMessages(
    signInTitle: l10n.bioSignInTitle,
    biometricHint: l10n.bioHint,
    biometricNotRecognized: l10n.bioNotRecognized,
    biometricRequiredTitle: l10n.bioRequiredTitle,
    biometricSuccess: l10n.bioSuccess,
    cancelButton: l10n.commonCancel,
    deviceCredentialsRequiredTitle: l10n.bioRequiredTitle,
    deviceCredentialsSetupDescription: l10n.bioSetupDescription,
    goToSettingsButton: l10n.bioGoToSettings,
    goToSettingsDescription: l10n.bioGoToSettingsDesc,
  );
}

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

  Future<bool> authenticate({
    required String reason,
    required AppLocalizations l10n,
  }) async {
    if (!_supported) {
      return false;
    }
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        authMessages: <AuthMessages>[_androidAuthMessages(l10n)],
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
