import 'package:flutter/material.dart';

import '../app/common_widgets.dart';
import '../app/reminder/notification_scheduler.dart';
import '../app/veri_fin_scope.dart';

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
    if (enabled) {
      // 开启时先申请系统通知权限（Android 13+ / iOS）。
      await _scheduler.requestPermission();
    }
    controller.setReminderSettings(
      controller.reminderSettings.copyWith(enabled: enabled),
    );
  }

  Future<void> _pickTime() async {
    final controller = VeriFinScope.of(context);
    final current = controller.reminderSettings;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: current.hour, minute: current.minute),
      helpText: '选择提醒时间',
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
              const VeriHeader(title: '记账提醒', showBack: true),
              const SizedBox(height: 10),
              VeriCard(
                child: Column(
                  children: <Widget>[
                    CompactSwitchRow(
                      icon: Icons.notifications_active_outlined,
                      title: const Text('每日提醒'),
                      value: settings.enabled,
                      onChanged: _toggle,
                    ),
                    if (settings.enabled) ...<Widget>[
                      const Divider(height: 1),
                      SettingsRow(
                        icon: Icons.schedule_outlined,
                        title: '提醒时间',
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
                      ? '开启后每天到点会收到一条本地通知，提醒你记录当天收支。若长时间未收到，请在系统设置中确认已允许通知。'
                      : '当前平台不支持本地通知，此设置仅在 Android / iOS 手机上生效。',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: muted, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
