import 'dart:convert';

/// 一个已知的支付/银行来源 App：包名 + 展示名。展示名为品牌名，按仓库约定
/// 保留中文（银行/品牌名不进 ARB）。
class PaymentSource {
  const PaymentSource({
    required this.package,
    required this.label,
    this.defaultOn = false,
  });

  final String package;
  final String label;
  final bool defaultOn;
}

/// 内置的已知来源清单——只收录包名可确认的几个（支付宝/微信/云闪付）。
/// 银行 App 包名众多且各版本不一，不臆造；需要覆盖银行时用「监听全部来源」。
const List<PaymentSource> kKnownPaymentSources = <PaymentSource>[
  PaymentSource(
    package: 'com.eg.android.AlipayGphone',
    label: '支付宝',
    defaultOn: true,
  ),
  PaymentSource(package: 'com.tencent.mm', label: '微信', defaultOn: true),
  PaymentSource(package: 'com.unionpay', label: '云闪付', defaultOn: true),
];

/// 默认勾选的来源包名（首次开启时的白名单）。
List<String> defaultSourcePackages() => kKnownPaymentSources
    .where((source) => source.defaultOn)
    .map((source) => source.package)
    .toList();

/// 自动记账（通知监听 NLS）配置。**Alpha 功能，默认全关。**
///
/// 设备本地偏好，存 KV（`verifin.auto_capture.v1`），不进 JSON 备份、初始化保留。
/// 依赖 AI 解析：开启前需先配好 [AiSettings]（由 UI 层把关）。
class AutoCaptureSettings {
  const AutoCaptureSettings({
    this.notificationEnabled = false,
    this.listenAllSources = false,
    this.sourcePackages = const <String>[],
    this.idleText = '',
    this.detectingText = '',
    this.doneText = '',
  });

  /// 是否开启通知监听自动记账（总开关）。
  final bool notificationEnabled;

  /// 是否监听全部来源 App（忽略白名单）。开启后噪音更多、AI 调用更频繁（费 Token），
  /// 但能覆盖银行等未收录的 App。
  final bool listenAllSources;

  /// 监听的来源 App 包名白名单（`listenAllSources` 为 false 时生效）。
  final List<String> sourcePackages;

  /// 常驻通知文案模板（空串表示用内置默认，由 UI/无 context 层解析本地化默认值）。
  /// [detectingText] 支持 `{account}` 占位，[doneText] 支持 `{amount}` 占位，
  /// 由原生侧在渲染通知时替换。
  final String idleText;
  final String detectingText;
  final String doneText;

  static const AutoCaptureSettings disabled = AutoCaptureSettings();

  /// 某来源是否在监听范围内（监听全部时恒为 true）。
  bool isSourceEnabled(String package) =>
      listenAllSources || sourcePackages.contains(package);

  AutoCaptureSettings copyWith({
    bool? notificationEnabled,
    bool? listenAllSources,
    List<String>? sourcePackages,
    String? idleText,
    String? detectingText,
    String? doneText,
  }) {
    return AutoCaptureSettings(
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
      listenAllSources: listenAllSources ?? this.listenAllSources,
      sourcePackages: sourcePackages ?? this.sourcePackages,
      idleText: idleText ?? this.idleText,
      detectingText: detectingText ?? this.detectingText,
      doneText: doneText ?? this.doneText,
    );
  }

  /// 切换某来源包名的勾选状态。
  AutoCaptureSettings toggleSource(String package, bool enabled) {
    final next = List<String>.from(sourcePackages);
    if (enabled) {
      if (!next.contains(package)) {
        next.add(package);
      }
    } else {
      next.remove(package);
    }
    return copyWith(sourcePackages: next);
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'notificationEnabled': notificationEnabled,
    'listenAllSources': listenAllSources,
    'sourcePackages': sourcePackages,
    'idleText': idleText,
    'detectingText': detectingText,
    'doneText': doneText,
  };

  static AutoCaptureSettings fromJson(Map<String, Object?> json) {
    final rawPackages = json['sourcePackages'];
    final packages = rawPackages is List
        ? rawPackages.whereType<String>().toList()
        : <String>[];
    return AutoCaptureSettings(
      notificationEnabled: json['notificationEnabled'] as bool? ?? false,
      listenAllSources: json['listenAllSources'] as bool? ?? false,
      sourcePackages: packages,
      idleText: json['idleText'] as String? ?? '',
      detectingText: json['detectingText'] as String? ?? '',
      doneText: json['doneText'] as String? ?? '',
    );
  }

  String encode() => jsonEncode(toJson());

  static AutoCaptureSettings decode(String? raw) {
    if (raw == null || raw.isEmpty) {
      return disabled;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return AutoCaptureSettings.fromJson(Map<String, Object?>.from(decoded));
      }
    } catch (_) {
      // 损坏配置退回未开启。
    }
    return disabled;
  }

  @override
  bool operator ==(Object other) =>
      other is AutoCaptureSettings &&
      other.notificationEnabled == notificationEnabled &&
      other.listenAllSources == listenAllSources &&
      _listEquals(other.sourcePackages, sourcePackages) &&
      other.idleText == idleText &&
      other.detectingText == detectingText &&
      other.doneText == doneText;

  @override
  int get hashCode => Object.hash(
    notificationEnabled,
    listenAllSources,
    Object.hashAll(sourcePackages),
    idleText,
    detectingText,
    doneText,
  );
}

bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
