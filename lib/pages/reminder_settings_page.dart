import 'package:flutter/material.dart';

import '../app/common_widgets.dart';
import '../app/reminder/notification_scheduler.dart';
import '../app/veri_fin_scope.dart';
import '../l10n/app_localizations.dart';

/// 记账提醒设置页：开关每日提醒并选择提醒时刻。开启时向系统申请通知权限。
class ReminderSettingsPage extends StatefulWidget {
  const ReminderSettingsPage({super.key});

  @override
  State<ReminderSettingsPage> createState() => _ReminderSettingsPageState();
}

class _ReminderSettingsPageState extends State<ReminderSettingsPage> {
  final NotificationScheduler _scheduler = NotificationScheduler();

  Future<void> _toggle(bool enabled) async {
    final controller = VeriFinScope.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    var granted = true;
    if (enabled) {
      // 开启时先申请系统通知权限（Android 13+ / iOS）。
      granted = await _scheduler.requestPermission();
    }
    controller.setReminderSettings(
      controller.reminderSettings.copyWith(enabled: enabled),
    );
    // 权限被拒时明确提示：否则提醒会静默不显示，用户无从得知。
    if (enabled && _scheduler.supported && !granted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.reminderPermissionDenied)),
      );
    }
  }

  Future<void> _pickTime() async {
    final controller = VeriFinScope.of(context);
    final current = controller.reminderSettings;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: AppLocalizations.of(context).reminderPickTime,
    );
    if (picked != null && mounted) {
      controller.setReminderSettings(
        current.copyWith(hour: picked.hour, minute: picked.minute),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = VeriFinScope.of(context);
    final settings = controller.reminderSettings;
    final muted = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.55);

    return Scaffold(
      body: SafeArea(
        child: VeriPage(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
            children: <Widget>[
              VeriHeader(
                title: AppLocalizations.of(context).reminderTitle,
                showBack: true,
              ),
              const SizedBox(height: 10),
              VeriCard(
                child: Column(
                  children: <Widget>[
                    CompactSwitchRow(
                      icon: Icons.notifications_active_outlined,
                      title: Text(AppLocalizations.of(context).reminderDaily),
                      value: settings.enabled,
                      onChanged: _toggle,
                    ),
                    if (settings.enabled) ...<Widget>[
                      const Divider(height: 1),
                      SettingsRow(
                        icon: Icons.schedule_outlined,
                        title: AppLocalizations.of(context).reminderTimeLabel,
                        trailing: settings.timeLabel,
                        trailingIcon: Icons.chevron_right,
                        onTap: _pickTime,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  _scheduler.supported
                      ? AppLocalizations.of(context).reminderDescSupported
                      : AppLocalizations.of(context).reminderDescUnsupported,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: muted, height: 1.5),
                ),
              ),
              if (_scheduler.supported) ...<Widget>[
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _sendTest,
                  icon: const Icon(Icons.notifications_outlined, size: 18),
                  label: Text(AppLocalizations.of(context).reminderTestButton),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _sendTest() async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context);
    // 先确保有通知/精确闹钟权限（首次可能未申请过），再立即发一条测试通知。
    await _scheduler.requestPermission();
    await _scheduler.showTest(l10n: l10n);
    if (!mounted) {
      return;
    }
    messenger.showSnackBar(SnackBar(content: Text(l10n.reminderTestSent)));
  }
}
