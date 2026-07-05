import '../l10n/app_localizations.dart';

class AccountIconOption {
  const AccountIconOption({
    required this.code,
    required this.label,
    required this.groupKey,
    required this.assetPath,
  });

  final String code;

  /// 品牌/银行名是专有名词，不随语言切换。
  final String label;

  /// 分组标识（credit/payment/bank），显示名经 [groupLabel] 从 ARB 解析。
  final String groupKey;
  final String assetPath;

  String groupLabel(AppLocalizations l10n) {
    switch (groupKey) {
      case 'credit':
        return l10n.iconGroupCredit;
      case 'payment':
        return l10n.iconGroupPayment;
      case 'bank':
        return l10n.iconGroupBank;
    }
    return groupKey;
  }
}

const List<AccountIconOption> accountAssetIconOptions = <AccountIconOption>[
  AccountIconOption(
    code: 'asset:credit_001',
    label: '白条',
    groupKey: 'credit',
    assetPath: 'assets/account_icons/credit_001.svg',
  ),
  AccountIconOption(
    code: 'asset:credit_002',
    label: '花呗',
    groupKey: 'credit',
    assetPath: 'assets/account_icons/credit_002.svg',
  ),
  AccountIconOption(
    code: 'asset:payment_001',
    label: 'Mastercard',
    groupKey: 'payment',
    assetPath: 'assets/account_icons/payment_001.svg',
  ),
  AccountIconOption(
    code: 'asset:payment_002',
    label: 'PayPal',
    groupKey: 'payment',
    assetPath: 'assets/account_icons/payment_002.svg',
  ),
  AccountIconOption(
    code: 'asset:payment_003',
    label: 'Stripe',
    groupKey: 'payment',
    assetPath: 'assets/account_icons/payment_003.svg',
  ),
  AccountIconOption(
    code: 'asset:payment_004',
    label: '微信支付',
    groupKey: 'payment',
    assetPath: 'assets/account_icons/payment_004.svg',
  ),
  AccountIconOption(
    code: 'asset:payment_005',
    label: '银联',
    groupKey: 'payment',
    assetPath: 'assets/account_icons/payment_005.svg',
  ),
  AccountIconOption(
    code: 'asset:payment_006',
    label: '支付宝',
    groupKey: 'payment',
    assetPath: 'assets/account_icons/payment_006.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_001',
    label: '上海银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_001.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_002',
    label: '上饶银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_002.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_003',
    label: '中信银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_003.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_004',
    label: '中国民生银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_004.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_005',
    label: '中国邮政储蓄银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_005.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_006',
    label: '中国银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_006.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_007',
    label: '乌鲁木齐市商业银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_007.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_008',
    label: '交通银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_008.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_009',
    label: '兴业银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_009.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_010',
    label: '农业银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_010.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_011',
    label: '北京银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_011.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_012',
    label: '华夏银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_012.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_013',
    label: '嘉兴银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_013.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_014',
    label: '四川天府银行南充市商业银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_014.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_015',
    label: '工商银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_015.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_016',
    label: '平安银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_016.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_017',
    label: '广发银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_017.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_018',
    label: '建设银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_018.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_019',
    label: '张家口市商业银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_019.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_020',
    label: '张家港农村商业银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_020.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_021',
    label: '招商银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_021.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_022',
    label: '江苏银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_022.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_023',
    label: '泰安银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_023.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_024',
    label: '浦发银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_024.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_025',
    label: '温州银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_025.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_026',
    label: '潍坊银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_026.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_027',
    label: '绍兴银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_027.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_028',
    label: '苏州银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_028.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_029',
    label: '营口银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_029.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_030',
    label: '邢台银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_030.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_031',
    label: '郑州银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_031.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_032',
    label: '青岛银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_032.svg',
  ),
  AccountIconOption(
    code: 'asset:bank_033',
    label: '顺德农村商业银行',
    groupKey: 'bank',
    assetPath: 'assets/account_icons/bank_033.svg',
  ),
];

AccountIconOption? accountAssetIconByCode(String code) {
  for (final option in accountAssetIconOptions) {
    if (option.code == code) {
      return option;
    }
  }
  return null;
}

bool isAssetAccountIcon(String code) => accountAssetIconByCode(code) != null;

String? suggestedAccountIconCode(String accountName) {
  final normalized = accountName.trim().toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }

  const aliases = <String, String>{
    '支付宝': 'asset:payment_006',
    'alipay': 'asset:payment_006',
    '微信': 'asset:payment_004',
    'wechat': 'asset:payment_004',
    '微信支付': 'asset:payment_004',
    '银联': 'asset:payment_005',
    '中信': 'asset:bank_003',
    '中信银行': 'asset:bank_003',
    '民生': 'asset:bank_004',
    '邮储': 'asset:bank_005',
    '中国银行': 'asset:bank_006',
    '交通': 'asset:bank_008',
    '交通银行': 'asset:bank_008',
    '兴业': 'asset:bank_009',
    '农业': 'asset:bank_010',
    '农行': 'asset:bank_010',
    '北京银行': 'asset:bank_011',
    '华夏': 'asset:bank_012',
    '工商': 'asset:bank_015',
    '工行': 'asset:bank_015',
    '平安': 'asset:bank_016',
    '广发': 'asset:bank_017',
    '建设': 'asset:bank_018',
    '建行': 'asset:bank_018',
    '招商': 'asset:bank_021',
    '招行': 'asset:bank_021',
    '江苏银行': 'asset:bank_022',
    '浦发': 'asset:bank_024',
    '苏州银行': 'asset:bank_028',
    '青岛银行': 'asset:bank_032',
  };

  for (final entry in aliases.entries) {
    if (normalized.contains(entry.key.toLowerCase())) {
      return entry.value;
    }
  }

  for (final option in accountAssetIconOptions) {
    final label = option.label.toLowerCase();
    if (normalized.contains(label) || label.contains(normalized)) {
      return option.code;
    }
  }
  return null;
}
