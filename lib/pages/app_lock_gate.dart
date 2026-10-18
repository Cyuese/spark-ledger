import 'dart:async';

import 'package:flutter/material.dart';

import '../app/veri_fin_controller.dart';
import '../app/veri_fin_scope.dart';
import 'app_lock_page.dart';

/// 应用锁门卫：覆盖在整个应用（含已 push 的路由）之上。冷启动即锁定；应用退到
/// 后台后回到前台时重新锁定。放在 `MaterialApp.builder` 里以覆盖根 Navigator。
class AppLockGate extends StatefulWidget {
  const AppLockGate({super.key, required this.child});

  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  bool _locked = false;
  bool _initialized = false;
  VeriFinController? _controller;
  final ValueNotifier<bool> _lockedListenable = ValueNotifier<bool>(false);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller = VeriFinScope.of(context);
    if (!_initialized) {
      // 冷启动：已启用应用锁则初始锁定。
      _locked = _controller!.appLockEnabled;
      _lockedListenable.value = _locked;
      _initialized = true;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lockedListenable.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.appLockEnabled) {
      return;
    }
    // 退到后台时预置锁定，回到前台即呈现锁屏。
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (!_locked) {
        _lockedListenable.value = true;
        setState(() => _locked = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = VeriFinScope.of(context);
    final showLock = _locked && controller.appLockEnabled;
    return AppLockSessionScope(
      locked: _lockedListenable,
      child: Stack(
        children: <Widget>[
          // 半透明材质不能透出锁屏下方的账目；保留页面状态，但停止绘制、语义和焦点访问。
          ExcludeFocus(
            excluding: showLock,
            child: Offstage(offstage: showLock, child: widget.child),
          ),
          if (showLock)
            // 本门卫位于 `MaterialApp.builder`，即在根 Navigator 之上，自身没有
            // Navigator/Overlay 祖先。锁屏里的确认框要走 Navigator，因此必须像
            // PrivacyConsentGate / OnboardingGate 一样自带一个独立 Navigator；
            // 这里根 Navigator 仍在树中，需用 `HeroControllerScope.none` 避免两个
            // Navigator 共用同一个 HeroController。
            HeroControllerScope.none(
              child: Navigator(
                key: const ValueKey('app_lock_gate'),
                onGenerateRoute: (_) => MaterialPageRoute<void>(
                  builder: (_) => AppLockScreen(
                    onUnlocked: () {
                      _lockedListenable.value = false;
                      setState(() => _locked = false);
                    },
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 向主界面暴露当前是否处于锁屏状态；外部入口必须先通过 [waitUntilUnlocked]。
class AppLockSessionScope extends InheritedNotifier<ValueNotifier<bool>> {
  const AppLockSessionScope({
    super.key,
    required ValueNotifier<bool> locked,
    required super.child,
  }) : super(notifier: locked);

  static bool isLocked(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<AppLockSessionScope>()
            ?.notifier
            ?.value ??
        false;
  }

  /// 等待用户完成解锁；应用锁未启用或已经解锁时立即返回。
  static Future<void> waitUntilUnlocked(BuildContext context) {
    final notifier = context
        .dependOnInheritedWidgetOfExactType<AppLockSessionScope>()
        ?.notifier;
    if (notifier == null || !notifier.value) {
      return Future<void>.value();
    }
    final completer = Completer<void>();
    void listener() {
      if (notifier.value || completer.isCompleted) {
        return;
      }
      notifier.removeListener(listener);
      completer.complete();
    }

    notifier.addListener(listener);
    listener();
    return completer.future;
  }
}
