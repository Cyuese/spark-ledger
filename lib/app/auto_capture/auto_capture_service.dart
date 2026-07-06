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

  /// 取出原生队列，逐条 AI 解析成交易草稿并**返回**（不落账）。落账交由调用方
  /// （`main.dart`）弹确认页由用户确认——**不再静默自动入账**。结束后常驻通知回 idle。
  Future<List<AiEntryDraft>> drainAndProcess() async {
    if (!_controller.autoCaptureSettings.notificationEnabled) {
      return const <AiEntryDraft>[];
    }
    final captures = await AppPlatformBridge.drainAutoCaptureQueue();
    if (captures.isEmpty) {
      return const <AiEntryDraft>[];
    }

    final drafts = <AiEntryDraft>[];
    final coordinator = AutoCaptureCoordinator(
      settingsOf: () => _controller.autoCaptureSettings,
      requestDraft: (notification) => requestNotificationEntryDraft(
        settings: _controller.aiSettings,
        notificationText: notification.text,
        context: _buildContext(),
      ),
      // 识别为交易的草稿只收集起来交给用户确认，不直接落账。
      commitDraft: (draft, _) => drafts.add(draft),
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

    // 落账要等用户确认，常驻通知回到等待态。
    await AppPlatformBridge.setAutoCaptureState('idle');
    return drafts;
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
