import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../app/auto_capture/auto_capture_settings.dart';
import '../app/common_widgets.dart';
import '../app/platform_bridge.dart';
import '../app/veri_fin_controller.dart';
import '../app/veri_fin_scope.dart';
import '../l10n/app_localizations.dart';
import 'ai_settings_page.dart';

/// 自动记账设置页（Alpha）：开启通知监听，读取支付通知交给 AI 解析后后台自动记一笔。
/// 依赖 AI 配置（开启前把关）；配置为设备本地偏好（存 KV），不进 JSON 备份、初始化保留。
class AutoCaptureSettingsPage extends StatefulWidget {
  const AutoCaptureSettingsPage({super.key});

  @override
  State<AutoCaptureSettingsPage> createState() =>
      _AutoCaptureSettingsPageState();
}

class _AutoCaptureSettingsPageState extends State<AutoCaptureSettingsPage> {
  final TextEditingController _idleController = TextEditingController();
  final TextEditingController _detectingController = TextEditingController();
  final TextEditingController _doneController = TextEditingController();
  bool _seeded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_seeded) {
      final settings = VeriFinScope.of(context).autoCaptureSettings;
      _idleController.text = settings.idleText;
      _detectingController.text = settings.detectingText;
      _doneController.text = settings.doneText;
      _seeded = true;
    }
  }

  @override
  void dispose() {
    _idleController.dispose();
    _detectingController.dispose();
    _doneController.dispose();
    super.dispose();
  }

  void _update(
    VeriFinController controller,
    AutoCaptureSettings Function(AutoCaptureSettings) change,
  ) {
    controller.setAutoCaptureSettings(change(controller.autoCaptureSettings));
  }

  Future<void> _toggleMaster(VeriFinController controller, bool enabled) async {
    if (enabled && !controller.aiSettings.isConfigured) {
      await _promptConfigureAi();
      return;
    }
    final settings = controller.autoCaptureSettings;
    // 首次开启且未选任何来源时，写入默认来源，避免开了却什么都不监听。
    final needsDefaults =
        enabled &&
        !settings.listenAllSources &&
        settings.sourcePackages.isEmpty;
    _update(
      controller,
      (current) => current.copyWith(
        notificationEnabled: enabled,
        sourcePackages: needsDefaults
            ? defaultSourcePackages()
            : current.sourcePackages,
      ),
    );
    // 开启后若尚未授予「通知使用权」，引导去系统设置授权。
    if (enabled) {
      final granted = await AppPlatformBridge.isNotificationAccessGranted();
      if (!granted) {
        await AppPlatformBridge.openNotificationAccessSettings();
      }
    }
  }

  Future<void> _promptConfigureAi() async {
    final l10n = AppLocalizations.of(context);
    final goToSettings = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.autoCaptureNeedAiTitle),
        content: Text(l10n.autoCaptureNeedAiBody),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.aiEntryGoToSettings),
          ),
        ],
      ),
    );
    if (goToSettings == true && mounted) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (_) => const AiSettingsPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final controller = VeriFinScope.of(context);
    final settings = controller.autoCaptureSettings;
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    final enabled = settings.notificationEnabled;

    return Scaffold(
      body: SafeArea(
        child: VeriPage(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
            children: <Widget>[
              VeriHeader(title: l10n.autoCaptureTitle, showBack: true),
              const SizedBox(height: 10),
              _AlphaBanner(text: l10n.autoCaptureAlpha),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  l10n.autoCaptureIntro,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: muted,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              VeriCard(
                child: _SwitchRow(
                  title: l10n.autoCaptureEnableLabel,
                  subtitle: l10n.autoCaptureEnableDesc,
                  emphasize: true,
                  value: enabled,
                  onChanged: (value) => _toggleMaster(controller, value),
                ),
              ),
              if (enabled) ...<Widget>[
                const SizedBox(height: 12),
                _sourcesCard(context, controller, settings, muted),
                const SizedBox(height: 12),
                _notificationTextCard(context, controller, muted),
              ],
              const SizedBox(height: 14),
              _NoticeBox(
                icon: Icons.privacy_tip_outlined,
                text: l10n.autoCapturePrivacyNotice,
              ),
              const SizedBox(height: 10),
              _NoticeBox(
                icon: Icons.info_outline,
                text: l10n.autoCapturePermissionNote,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sourcesCard(
    BuildContext context,
    VeriFinController controller,
    AutoCaptureSettings settings,
    Color muted,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final listenAll = settings.listenAllSources;
    return VeriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.autoCaptureSourcesTitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.autoCaptureSourcesDesc,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 4),
          _SwitchRow(
            title: l10n.autoCaptureListenAll,
            subtitle: l10n.autoCaptureListenAllDesc,
            value: listenAll,
            onChanged: (value) => _update(
              controller,
              (current) => current.copyWith(listenAllSources: value),
            ),
          ),
          const Divider(height: 1),
          for (final source in kKnownPaymentSources)
            _SwitchRow(
              title: source.label,
              value:
                  listenAll || settings.sourcePackages.contains(source.package),
              onChanged: listenAll
                  ? null
                  : (value) => _update(
                      controller,
                      (current) => current.toggleSource(source.package, value),
                    ),
            ),
        ],
      ),
    );
  }

  Widget _notificationTextCard(
    BuildContext context,
    VeriFinController controller,
    Color muted,
  ) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return VeriCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            l10n.autoCaptureNotifTextTitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            l10n.autoCaptureNotifTextDesc,
            style: theme.textTheme.bodySmall?.copyWith(color: muted),
          ),
          const SizedBox(height: 10),
          _notifField(
            controller,
            _idleController,
            l10n.autoCaptureNotifIdleLabel,
            l10n.autoCaptureNotifIdleDefault,
            (settings, value) => settings.copyWith(idleText: value),
          ),
          const SizedBox(height: 10),
          _notifField(
            controller,
            _detectingController,
            l10n.autoCaptureNotifDetectingLabel,
            l10n.autoCaptureNotifDetectingDefault,
            (settings, value) => settings.copyWith(detectingText: value),
          ),
          const SizedBox(height: 10),
          _notifField(
            controller,
            _doneController,
            l10n.autoCaptureNotifDoneLabel,
            l10n.autoCaptureNotifDoneDefault,
            (settings, value) => settings.copyWith(doneText: value),
          ),
        ],
      ),
    );
  }

  Widget _notifField(
    VeriFinController controller,
    TextEditingController textController,
    String label,
    String hint,
    AutoCaptureSettings Function(AutoCaptureSettings, String) apply,
  ) {
    return TextField(
      controller: textController,
      decoration: InputDecoration(labelText: label, hintText: hint),
      onChanged: (value) => controller.setAutoCaptureSettings(
        apply(controller.autoCaptureSettings, value.trim()),
      ),
    );
  }
}

/// 紧凑开关行（标题 + 可选副标题 + Switch），不用 ListTile 以避免卡片内墨纹冲突，
/// 与本应用其余设置项的紧凑风格一致。
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.emphasize = false,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: muted,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch.adaptive(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// Alpha 功能警示条（醒目、非致命语气）。
class _AlphaBanner extends StatelessWidget {
  const _AlphaBanner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.tertiary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(veriRadiusMd),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.science_outlined, size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 灰底提示框（隐私说明 / 权限说明），与 AI 设置页保持一致的视觉。
class _NoticeBox extends StatelessWidget {
  const _NoticeBox({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.55);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(veriRadiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 16, color: muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: muted,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
