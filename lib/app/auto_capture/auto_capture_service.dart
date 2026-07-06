import '../ai/ai_entry_parser.dart';
import '../models.dart';
import '../platform_bridge.dart';
import '../veri_fin_controller.dart';
import 'auto_capture_coordinator.dart';

/// 把自动记账的 Dart 逻辑（配置推送 + drain 队列 + AI 解析落账）与原生桥接、控制器
/// 串起来。由 `main.dart` 在开屏/回前台/配置变化时调用。
///
/// 说明：当前为「后台捕获入队 + 应用回前台时解析落账」。原生 NLS 在后台按白名单把
/// 支付通知原文入队并维护常驻通知；解析（AI）与落账在此处发生。真正「应用被杀时也
/// 自动落账」需后续引入无头引擎/WorkManager 触发（真机验证项）。
class AutoCaptureService {
  AutoCaptureService(this._controller);

  final VeriFinController _controller;

  /// 把当前配置（含解析后的通知文案默认值）推送到原生。
  Future<void> pushConfig({
    required String idleDefault,
    required String detectingDefault,
    required String doneDefault,
  }) async {
    final settings = _controller.autoCaptureSettings;
    await AppPlatformBridge.setAutoCaptureConfig(
      enabled: settings.notificationEnabled,
      listenAll: settings.listenAllSources,
      packages: settings.sourcePackages.join(','),
      idleText: settings.idleText.isNotEmpty ? settings.idleText : idleDefault,
      detectingText: settings.detectingText.isNotEmpty
          ? settings.detectingText
          : detectingDefault,
      doneText: settings.doneText.isNotEmpty ? settings.doneText : doneDefault,
    );
  }

  /// 取出原生队列，逐条 AI 解析并落账；结束后把常驻通知切到 done（有落账）或 idle。
  /// 返回本次落账笔数。
  Future<int> drainAndProcess() async {
    if (!_controller.autoCaptureSettings.notificationEnabled) {
      return 0;
    }
    final captures = await AppPlatformBridge.drainAutoCaptureQueue();
    if (captures.isEmpty) {
      return 0;
    }

    var committed = 0;
    double? lastAmount;
    final coordinator = AutoCaptureCoordinator(
      settingsOf: () => _controller.autoCaptureSettings,
      requestDraft: (notification) => requestNotificationEntryDraft(
        settings: _controller.aiSettings,
        notificationText: notification.text,
        context: _buildContext(),
      ),
      commitDraft: (draft, _) {
        if (_controller.addEntryFromAutoCapture(draft)) {
          committed++;
          lastAmount = draft.amount;
        }
      },
    );

    for (final raw in captures) {
      final capture = CapturedNotification(
        packageName: raw['packageName'] as String? ?? '',
        text: raw['text'] as String? ?? '',
        postedAt: DateTime.fromMillisecondsSinceEpoch(
          (raw['postedAt'] as num?)?.toInt() ?? 0,
        ),
      );
      await coordinator.process(capture);
    }

    if (committed > 0) {
      await AppPlatformBridge.setAutoCaptureState(
        'done',
        amount: lastAmount?.toStringAsFixed(2),
      );
    } else {
      await AppPlatformBridge.setAutoCaptureState('idle');
    }
    return committed;
  }

  AiEntryContext _buildContext() {
    List<AiOption> optionsFor(EntryType type) => _controller
        .categoriesForType(type)
        .map(
          (category) => AiOption(
            id: category.id,
            label: _controller.categoryPathLabel(category.id),
          ),
        )
        .toList();
    final accounts = _controller.accounts
        .where((account) => !account.hidden)
        .map((account) => AiOption(id: account.id, label: account.name))
        .toList();
    return AiEntryContext(
      expenseCategories: optionsFor(EntryType.expense),
      incomeCategories: optionsFor(EntryType.income),
      accounts: accounts,
      today: DateTime.now(),
      bookId: _controller.activeBook.id,
    );
  }
}
