import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/app_lock.dart';
import '../app/app_theme.dart';
import '../app/common_widgets.dart';
import '../app/veri_fin_controller.dart';
import '../app/veri_fin_scope.dart';

/// 6 位 PIN 输入视图：圆点指示 + 数字键盘。输满 [kAppLockPinLength] 位自动回调
/// [onCompleted] 并清空输入，由上层判定成功/失败并通过 [errorText] 反馈。
///
/// [footer] 用于在键盘左下角放置额外操作（如生物识别解锁按钮）。
class PinInputView extends StatefulWidget {
  const PinInputView({
    super.key,
    required this.onCompleted,
    this.errorText,
    this.hapticsEnabled = true,
    this.footer,
  });

  final ValueChanged<String> onCompleted;
  final String? errorText;
  final bool hapticsEnabled;
  final Widget? footer;

  @override
  State<PinInputView> createState() => _PinInputViewState();
}

class _PinInputViewState extends State<PinInputView> {
  String _input = '';

  void _press(String digit) {
    if (_input.length >= kAppLockPinLength) {
      return;
    }
    if (widget.hapticsEnabled) {
      HapticFeedback.lightImpact();
    }
    setState(() => _input += digit);
    if (_input.length == kAppLockPinLength) {
      final value = _input;
      setState(() => _input = '');
      widget.onCompleted(value);
    }
  }

  void _backspace() {
    if (_input.isEmpty) {
      return;
    }
    if (widget.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
    setState(() => _input = _input.substring(0, _input.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    final error = widget.errorText;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            for (var i = 0; i < kAppLockPinLength; i += 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _PinDot(filled: i < _input.length),
              ),
          ],
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 20,
          child: error == null
              ? null
              : Text(
                  error,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: veriExpense,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
        const SizedBox(height: 8),
        _Keypad(
          onDigit: _press,
          onBackspace: _backspace,
          footer: widget.footer,
        ),
      ],
    );
  }
}

class _PinDot extends StatelessWidget {
  const _PinDot({required this.filled});

  final bool filled;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.onSurface;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: filled ? veriRoyal : Colors.transparent,
        border: Border.all(
          color: filled ? veriRoyal : base.withValues(alpha: 0.32),
          width: 1.6,
        ),
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({
    required this.onDigit,
    required this.onBackspace,
    this.footer,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 300),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: <Widget>[
          for (var digit = 1; digit <= 9; digit += 1)
            _DigitKey(digit: '$digit', onTap: () => onDigit('$digit')),
          footer ?? const SizedBox.shrink(),
          _DigitKey(digit: '0', onTap: () => onDigit('0')),
          // 不用 IconButton 的 tooltip：锁屏覆盖在根 Navigator 之上，
          // Tooltip 找不到 Overlay 祖先会报错。
          Semantics(
            label: '删除',
            button: true,
            child: IconButton(
              key: const Key('pin_backspace'),
              onPressed: onBackspace,
              icon: const Icon(Icons.backspace_outlined),
            ),
          ),
        ],
      ),
    );
  }
}

class _DigitKey extends StatelessWidget {
  const _DigitKey({required this.digit, required this.onTap});

  final String digit;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      key: Key('pin_key_$digit'),
      color: isDark
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : const Color(0xFFEAF0F8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(veriRadiusMd),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(veriRadiusMd),
        onTap: onTap,
        child: Center(
          child: Text(
            digit,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

/// 全屏锁定界面（由 AppLockGate 覆盖在应用之上）。校验通过后回调 [onUnlocked]。
///
/// [biometricAction] 供 1.2.3 注入指纹快捷解锁按钮；为空时不展示。
class AppLockScreen extends StatefulWidget {
  const AppLockScreen({
    super.key,
    required this.onUnlocked,
    this.biometricAction,
  });

  final VoidCallback onUnlocked;
  final Widget? biometricAction;

  @override
  State<AppLockScreen> createState() => _AppLockScreenState();
}

class _AppLockScreenState extends State<AppLockScreen> {
  String? _error;

  void _submit(String pin) {
    final controller = VeriFinScope.of(context);
    if (controller.verifyAppLock(pin)) {
      widget.onUnlocked();
      return;
    }
    setState(() => _error = '密码错误，请重试');
  }

  @override
  Widget build(BuildContext context) {
    final controller = VeriFinScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.lock_outline, size: 40, color: veriRoyal),
                const SizedBox(height: 12),
                Text(
                  '输入密码',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  '请输入 6 位数字密码解锁',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                const SizedBox(height: 28),
                PinInputView(
                  onCompleted: _submit,
                  errorText: _error,
                  hapticsEnabled: controller.hapticsEnabled,
                  footer: widget.biometricAction,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 设置或修改 PIN：输入两遍确认后保存。保存成功 pop(true)。
class AppLockSetupPage extends StatefulWidget {
  const AppLockSetupPage({super.key});

  @override
  State<AppLockSetupPage> createState() => _AppLockSetupPageState();
}

class _AppLockSetupPageState extends State<AppLockSetupPage> {
  String? _firstPin;
  String? _error;

  void _onCompleted(String pin) {
    final first = _firstPin;
    if (first == null) {
      setState(() {
        _firstPin = pin;
        _error = null;
      });
      return;
    }
    if (pin != first) {
      setState(() {
        _firstPin = null;
        _error = '两次输入不一致，请重新设置';
      });
      return;
    }
    VeriFinScope.of(context).setAppLock(kind: AppLockKind.pin, secret: pin);
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final controller = VeriFinScope.of(context);
    final confirming = _firstPin != null;
    return Scaffold(
      body: SafeArea(
        child: VeriPage(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
            children: <Widget>[
              const VeriHeader(title: '设置密码', showBack: true),
              const SizedBox(height: 30),
              Text(
                confirming ? '再次输入以确认' : '设置 6 位数字密码',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 28),
              PinInputView(
                onCompleted: _onCompleted,
                errorText: _error,
                hapticsEnabled: controller.hapticsEnabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 验证当前应用锁密钥。验证通过 pop(true)。用于关闭应用锁、修改密码前的校验。
class AppLockVerifyPage extends StatefulWidget {
  const AppLockVerifyPage({super.key, this.title = '验证密码'});

  final String title;

  @override
  State<AppLockVerifyPage> createState() => _AppLockVerifyPageState();
}

class _AppLockVerifyPageState extends State<AppLockVerifyPage> {
  String? _error;

  void _onCompleted(String pin) {
    if (VeriFinScope.of(context).verifyAppLock(pin)) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => _error = '密码错误，请重试');
  }

  @override
  Widget build(BuildContext context) {
    final controller = VeriFinScope.of(context);
    return Scaffold(
      body: SafeArea(
        child: VeriPage(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
            children: <Widget>[
              VeriHeader(title: widget.title, showBack: true),
              const SizedBox(height: 30),
              Text(
                '请输入当前 6 位数字密码',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 28),
              PinInputView(
                onCompleted: _onCompleted,
                errorText: _error,
                hapticsEnabled: controller.hapticsEnabled,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 应用锁设置页：开关应用锁、修改密码。
class AppLockSettingsPage extends StatelessWidget {
  const AppLockSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = VeriFinScope.of(context);
    final enabled = controller.appLockEnabled;

    return Scaffold(
      body: SafeArea(
        child: VeriPage(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
            children: <Widget>[
              const VeriHeader(
                title: '应用锁',
                subtitle: '启动和回到前台时校验',
                showBack: true,
              ),
              const SizedBox(height: 10),
              VeriCard(
                child: Column(
                  children: <Widget>[
                    CompactSwitchRow(
                      icon: Icons.lock_outline,
                      title: const Text('数字密码'),
                      value: enabled,
                      onChanged: (value) => _toggle(context, controller, value),
                    ),
                    if (enabled) ...<Widget>[
                      const Divider(height: 1),
                      SettingsRow(
                        icon: Icons.password_outlined,
                        title: '修改密码',
                        trailing: '',
                        trailingIcon: Icons.chevron_right,
                        onTap: () => _changePin(context, controller),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                '密码仅以加盐哈希保存在本机，不会上传，也无法找回；忘记密码时可在设置页初始化数据后重新设置。',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggle(
    BuildContext context,
    VeriFinController controller,
    bool value,
  ) async {
    if (value) {
      await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(builder: (context) => const AppLockSetupPage()),
      );
      return;
    }
    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => const AppLockVerifyPage(title: '关闭应用锁'),
      ),
    );
    if (verified == true) {
      controller.disableAppLock();
    }
  }

  Future<void> _changePin(
    BuildContext context,
    VeriFinController controller,
  ) async {
    final verified = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (context) => const AppLockVerifyPage(title: '修改密码'),
      ),
    );
    if (verified != true || !context.mounted) {
      return;
    }
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(builder: (context) => const AppLockSetupPage()),
    );
    if (changed == true && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('密码已更新')));
    }
  }
}
