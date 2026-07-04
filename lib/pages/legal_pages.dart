import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../app/common_widgets.dart';
import '../app/legal_content.dart';
import '../app/veri_fin_scope.dart';

/// 展示单份法律文档（隐私政策 / 用户协议）。可再次查看，也用于首启动同意弹窗的详情。
class LegalDocumentPage extends StatelessWidget {
  const LegalDocumentPage({super.key, required this.document});

  final LegalDocument document;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: VeriPage(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
            children: <Widget>[
              VeriHeader(
                title: document.title,
                subtitle: '更新日期：$legalUpdatedAt',
                showBack: true,
              ),
              const SizedBox(height: 10),
              VeriCard(child: LegalBody(body: document.body)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 将法律文档正文按段落渲染，章节标题（如「一、…」）加粗。
class LegalBody extends StatelessWidget {
  const LegalBody({super.key, required this.body});

  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lines = body.trim().split('\n');
    final children = <Widget>[];
    for (final raw in lines) {
      final line = raw.trim();
      if (line.isEmpty) {
        children.add(const SizedBox(height: 10));
        continue;
      }
      final isHeading = _headingPattern.hasMatch(line);
      children.add(
        Padding(
          padding: EdgeInsets.only(top: isHeading ? 6 : 0, bottom: 4),
          child: Text(
            line,
            style: isHeading
                ? theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  )
                : theme.textTheme.bodyMedium?.copyWith(
                    height: 1.6,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.82),
                  ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }
}

final RegExp _headingPattern = RegExp(r'^[一二三四五六七八九十]+、');

/// 首启动的隐私政策 / 用户协议同意弹窗（不可通过返回键关闭）。
///
/// 返回 `true` 表示用户同意；用户点击「不同意并退出」时不会返回（直接退出应用）。
Future<bool?> showPrivacyConsentDialog(BuildContext context) {
  return showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => const _PrivacyConsentDialog(),
  );
}

class _PrivacyConsentDialog extends StatelessWidget {
  const _PrivacyConsentDialog();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: const Text('隐私政策与用户协议'),
        content: SizedBox(
          width: 360,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  legalConsentSummary,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 6,
                  children: <Widget>[
                    for (final document in LegalDocument.values)
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: const Size(0, 36),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        onPressed: () {
                          Navigator.of(context).push<void>(
                            MaterialPageRoute<void>(
                              builder: (context) =>
                                  LegalDocumentPage(document: document),
                            ),
                          );
                        },
                        child: Text('《${document.title}》'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(
              '不同意并退出',
              style: TextStyle(color: theme.colorScheme.onSurface),
            ),
          ),
          FilledButton(
            key: const Key('privacy_consent_accept'),
            style: FilledButton.styleFrom(backgroundColor: veriRoyal),
            onPressed: () {
              VeriFinScope.of(context).acceptPrivacyConsent();
              Navigator.of(context).pop(true);
            },
            child: const Text('同意并继续'),
          ),
        ],
      ),
    );
  }
}
