import 'dart:async';

import 'package:anchored_menu/anchored_menu.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_widget/home_widget.dart';

import '../app/app_theme.dart';
import '../app/app_lock.dart';
import '../app/common_widgets.dart';
import '../app/feedback.dart';
import '../app/logging/app_logger.dart';
import '../app/native_widget_preview.dart';
import '../app/platform_bridge.dart';
import '../app/widgets/widget_catalog.dart';
import '../app/widgets/widget_instance_config.dart';
import '../local_storage/local_storage.dart';
import '../l10n/app_localizations.dart';
import 'sheets.dart';
import 'app_lock_page.dart';

/// 桌面实例配置页的入口。独立引擎、独立会话，**不构造 Controller、不读数据库**：
/// 账本列表由主应用推送，这里只做选择与保存。
///
/// 页面主题跟随系统：这个引擎不读应用的主题偏好（那是主应用的 KV 状态）。
/// 组件的深/浅色由实例自己的外观设置决定，与这里显示的选项一致。
Future<void> runWidgetConfiguration() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await LocalKeyValueStore.create();
  final logger = AppLogger(store);
  final appLock = AppLockConfig.fromStorage(store.read(appLockStorageKey));
  final locale = await HomeWidget.getWidgetData<String>(widgetLocaleKey);
  runApp(
    WidgetConfigurationApp(logger: logger, locale: locale, appLock: appLock),
  );
}

class WidgetConfigurationApp extends StatefulWidget {
  const WidgetConfigurationApp({
    super.key,
    this.logger,
    this.locale,
    this.appLock = const AppLockConfig.none(),
  });

  final AppLogger? logger;
  final String? locale;
  final AppLockConfig appLock;

  @override
  State<WidgetConfigurationApp> createState() => _WidgetConfigurationAppState();
}

class _WidgetConfigurationAppState extends State<WidgetConfigurationApp> {
  final _feedback = VeriFeedbackController();

  @override
  void dispose() {
    _feedback.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    locale: widget.locale == null
        ? null
        : Locale(widget.locale!.split('_').first),
    supportedLocales: AppLocalizations.supportedLocales,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    theme: buildVeriFinTheme(Brightness.light),
    darkTheme: buildVeriFinTheme(Brightness.dark),
    themeMode: ThemeMode.system,
    builder: (context, child) =>
        VeriFeedbackHost(controller: _feedback, child: child!),
    home: _WidgetConfigurationLockGate(
      appLock: widget.appLock,
      child: WidgetConfigurationPage(logger: widget.logger),
    ),
  );
}

class _WidgetConfigurationLockGate extends StatefulWidget {
  const _WidgetConfigurationLockGate({
    required this.appLock,
    required this.child,
  });

  final AppLockConfig appLock;
  final Widget child;

  @override
  State<_WidgetConfigurationLockGate> createState() =>
      _WidgetConfigurationLockGateState();
}

class _WidgetConfigurationLockGateState
    extends State<_WidgetConfigurationLockGate> {
  late bool _locked = widget.appLock.enabled;

  @override
  Widget build(BuildContext context) {
    if (!_locked) {
      return widget.child;
    }
    return AppLockScreen(
      config: widget.appLock,
      onUnlocked: () => setState(() => _locked = false),
    );
  }
}

class WidgetConfigurationPage extends StatefulWidget {
  const WidgetConfigurationPage({super.key, this.logger});

  final AppLogger? logger;

  @override
  State<WidgetConfigurationPage> createState() =>
      _WidgetConfigurationPageState();
}

class _WidgetConfigurationPageState extends State<WidgetConfigurationPage> {
  WidgetSetupSession? _session;
  String _bookId = '';
  WidgetAppearance _appearance = WidgetAppearance.fallback;
  bool _loading = true, _failed = false, _saving = false;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  Future<void> _load() async {
    try {
      final session = await WidgetSetupSession.load();
      if (!mounted) return;
      setState(() {
        _session = session;
        _bookId = session.config?.bookId ?? '';
        _appearance = session.config?.appearance ?? WidgetAppearance.fallback;
        _loading = false;
      });
    } on Object catch (error) {
      widget.logger?.error(
        'Widget configuration load failed',
        source: 'widgets',
        error: error,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _save() async {
    final session = _session;
    if (_saving || session == null || !_canSave(session)) return;
    setState(() => _saving = true);
    try {
      await session.save(
        WidgetInstanceConfig(bookId: _bookId, appearance: _appearance),
      );
      // 成功时由原生 finishHomeWidgetConfigure 关闭本页。
    } on Object catch (error) {
      widget.logger?.error(
        'Widget configuration save failed',
        source: 'widgets',
        error: error,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      unawaited(
        VeriFeedbackHost.of(context).showMessage(
          message: AppLocalizations.of(context).saveFailed,
          tone: VeriFeedbackTone.error,
        ),
      );
    }
  }

  /// 账本必选：没有可选账本、或用户还没选账本时都不允许保存。
  bool _canSave(WidgetSetupSession session) =>
      session.books.isNotEmpty && session.books.containsKey(_bookId);

  Future<void> _pickBook(WidgetSetupSession session) async {
    final selected = await showOptionSheet<String>(
      context: context,
      title: AppLocalizations.of(context).widgetBook,
      values: session.books.keys.toList(growable: false),
      // 未选账本时不标记任何一项：刻意不给「默认账本」，避免静默替用户决定。
      selected: _bookId,
      labelOf: (id) => session.books[id] ?? id,
    );
    if (selected != null && mounted && !_saving) {
      setState(() => _bookId = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final session = _session;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        body: SafeArea(
          child: VeriPage(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
              children: <Widget>[
                VeriHeader(
                  title: l.widgetConfigTitle,
                  subtitle: session?.template.name(l),
                  showBack: true,
                  onBack: _saving ? () {} : () => SystemNavigator.pop(),
                ),
                if (_loading)
                  const Center(child: CircularProgressIndicator())
                else if (_failed || session == null)
                  Text(l.widgetConfigurationFailed)
                else if (session.books.isEmpty)
                  _EmptyLedgerNotice(
                    onOpenApp: () => unawaited(AppWidgetBridge.openApp()),
                  )
                else ...<Widget>[
                  _WidgetDraftPreview(
                    template: session.template,
                    bookId: _bookId,
                    appearance: _appearance,
                  ),
                  const SizedBox(height: 20),
                  VeriCard(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 4,
                    ),
                    child: Column(
                      children: <Widget>[
                        SettingsRow(
                          key: const Key('widget_book'),
                          icon: Icons.account_balance_wallet_outlined,
                          title: l.widgetBook,
                          trailing: _bookId.isEmpty
                              ? l.widgetBookPlaceholder
                              : session.books[_bookId] ?? _bookId,
                          onTap: _saving ? null : () => _pickBook(session),
                        ),
                        const Divider(height: 1),
                        AnchoredMenuChoice<WidgetAppearance>(
                          values: WidgetAppearance.values,
                          selected: _appearance,
                          idOf: (value) => 'widget_appearance_${value.key}',
                          labelOf: (value) => value.label(l),
                          iconOf: (value) => switch (value) {
                            WidgetAppearance.system => Icons.brightness_auto,
                            WidgetAppearance.light => Icons.light_mode_outlined,
                            WidgetAppearance.dark => Icons.dark_mode_outlined,
                          },
                          onSelected: _saving
                              ? (_) {}
                              : (value) => setState(() => _appearance = value),
                          semanticLabel: l.widgetAppearance,
                          builder: (context, openMenu, menuOpen) => SettingsRow(
                            key: const Key('widget_appearance'),
                            icon: Icons.dark_mode_outlined,
                            title: l.widgetAppearance,
                            trailing: _appearance.label(l),
                            trailingIcon: Icons.expand_more,
                            onTap: _saving ? null : openMenu,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    key: const Key('widget_save'),
                    onPressed: _saving || !_canSave(session) ? null : _save,
                    child: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(),
                          )
                        : Text(l.widgetSaveConfig),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 草稿预览：未选账本时用样例态，选了就显示该账本的真实数据与所选外观。
class _WidgetDraftPreview extends StatelessWidget {
  const _WidgetDraftPreview({
    required this.template,
    required this.bookId,
    required this.appearance,
  });

  final WidgetTemplate template;
  final String bookId;
  final WidgetAppearance appearance;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (template == WidgetTemplate.trend ? constraints.maxWidth : 180.0)
                .floor()
                .clamp(100, 560);
        final height = template == WidgetTemplate.quickEntry ? 72 : 180;
        return Center(
          child: NativeWidgetPreview(
            key: const Key('widget_draft_preview'),
            template: template.key,
            width: width,
            height: height,
            bookId: bookId,
            appearance: appearance,
            sample: bookId.isEmpty,
            semanticLabel: AppLocalizations.of(context).widgetPreview,
          ),
        );
      },
    );
  }
}

/// 应用从未推送过账本（全新安装、还没打开过应用）时的兜底：给出去向，
/// 而不是留下一个无法保存的空表单。
class _EmptyLedgerNotice extends StatelessWidget {
  const _EmptyLedgerNotice({required this.onOpenApp});

  final VoidCallback onOpenApp;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        const SizedBox(height: 12),
        Text(l.widgetNoLedgerYet),
        const SizedBox(height: 16),
        OutlinedButton(
          key: const Key('widget_open_app'),
          onPressed: onOpenApp,
          child: Text(l.widgetOpenApp),
        ),
      ],
    );
  }
}
