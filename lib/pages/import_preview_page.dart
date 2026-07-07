import 'package:flutter/material.dart';

import '../app/app_theme.dart';
import '../app/backup/transaction_import.dart';
import '../app/common_widgets.dart';
import '../app/models.dart';
import '../app/veri_fin_scope.dart';
import '../l10n/app_localizations.dart';
import 'entry_detail_page.dart';

/// 账单导入预览页：解析后、落库前展示即将导入的交易，用户可逐条排除 / 恢复，
/// 也可点进完整编辑（走 [EntryDetailPage] 草稿模式，不落库）。
///
/// 返回值（`Navigator.pop`）：
/// - `null`：用户取消（返回键 / 未确认）。
/// - `List<LedgerEntry>`：用户确认导入的交易（已按排除筛选、含编辑后的内容）。
class ImportPreviewPage extends StatefulWidget {
  const ImportPreviewPage({
    super.key,
    required this.plan,
    required this.sourceLabel,
  });

  final ImportPlan plan;

  /// 来源名称（如「支付宝」），用于副标题。
  final String sourceLabel;

  @override
  State<ImportPreviewPage> createState() => _ImportPreviewPageState();
}

class _ImportPreviewPageState extends State<ImportPreviewPage> {
  /// 可编辑的交易副本，按时间倒序展示（与交易列表一致）。
  late final List<LedgerEntry> _entries = List<LedgerEntry>.of(
    widget.plan.entries,
  )..sort((a, b) => b.occurredAt.compareTo(a.occurredAt));

  /// 被排除的交易 id（默认全部保留）。
  final Set<String> _excluded = <String>{};

  bool _isIncluded(LedgerEntry entry) => !_excluded.contains(entry.id);

  List<LedgerEntry> get _includedEntries =>
      _entries.where(_isIncluded).toList();

  void _toggle(LedgerEntry entry) {
    setState(() {
      if (_excluded.contains(entry.id)) {
        _excluded.remove(entry.id);
      } else {
        _excluded.add(entry.id);
      }
    });
  }

  void _selectAll() => setState(_excluded.clear);

  void _deselectAll() => setState(() {
    _excluded
      ..clear()
      ..addAll(_entries.map((entry) => entry.id));
  });

  Future<void> _edit(
    LedgerEntry entry,
    List<Account> accounts,
    List<Category> categories,
  ) async {
    final edited = await Navigator.of(context).push<LedgerEntry>(
      MaterialPageRoute<LedgerEntry>(
        builder: (_) => EntryDetailPage.draft(
          entry: entry,
          extraAccounts: widget.plan.newAccounts,
          extraCategories: widget.plan.newCategories,
        ),
      ),
    );
    if (edited == null || !mounted) {
      return;
    }
    setState(() {
      final index = _entries.indexWhere((item) => item.id == edited.id);
      if (index != -1) {
        _entries[index] = edited;
      }
    });
  }

  Future<void> _showSkippedRows() {
    final l10n = AppLocalizations.of(context);
    final lines = widget.plan.errors
        .take(20)
        .map((error) => l10n.lineError(error.line, error.message))
        .join('\n');
    final more = widget.plan.errorCount > 20
        ? '\n${l10n.moreLines(widget.plan.errorCount - 20)}'
        : '';
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.importPreviewSkippedTitle),
        content: SingleChildScrollView(child: Text('$lines$more')),
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.gotIt),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final controller = VeriFinScope.of(context);
    // 合并账本现有与本次将新建的账户/分类，供条目按 id 正确解析名称。
    final accounts = <Account>[
      ...controller.accounts,
      ...widget.plan.newAccounts,
    ];
    final categories = <Category>[
      ...controller.categories,
      ...widget.plan.newCategories,
    ];

    final included = _includedEntries;
    final referencedAccountIds = <String>{};
    final referencedCategoryIds = <String>{};
    for (final entry in included) {
      if (entry.accountId.isNotEmpty) {
        referencedAccountIds.add(entry.accountId);
      }
      final toAccountId = entry.toAccountId;
      if (toAccountId != null && toAccountId.isNotEmpty) {
        referencedAccountIds.add(toAccountId);
      }
      if (entry.categoryId.isNotEmpty) {
        referencedCategoryIds.add(entry.categoryId);
      }
    }
    final newAccountCount = widget.plan.newAccounts
        .where((account) => referencedAccountIds.contains(account.id))
        .length;
    final newCategoryCount = widget.plan.newCategories
        .where((category) => referencedCategoryIds.contains(category.id))
        .length;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
              child: VeriHeader(
                title: l10n.importPreviewTitle,
                subtitle: widget.sourceLabel,
                showBack: true,
                actions: <Widget>[
                  HeaderTextAction(
                    label: included.length == _entries.length
                        ? l10n.importPreviewDeselectAll
                        : l10n.importPreviewSelectAll,
                    onPressed: included.length == _entries.length
                        ? _deselectAll
                        : _selectAll,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 6),
              child: VeriCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      l10n.importPreviewSelectedOf(
                        included.length,
                        _entries.length,
                      ),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        if (newAccountCount > 0)
                          _SummaryChip(
                            icon: Icons.account_balance_wallet_outlined,
                            text: l10n.importPreviewNewAccounts(
                              newAccountCount,
                            ),
                          ),
                        if (newCategoryCount > 0)
                          _SummaryChip(
                            icon: Icons.category_outlined,
                            text: l10n.importPreviewNewCategories(
                              newCategoryCount,
                            ),
                          ),
                        if (widget.plan.errorCount > 0)
                          ActionChip(
                            avatar: Icon(
                              Icons.error_outline,
                              size: 16,
                              color: veriExpense,
                            ),
                            label: Text(
                              l10n.importPreviewSkipped(widget.plan.errorCount),
                            ),
                            onPressed: _showSkippedRows,
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.importPreviewHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(10, 4, 10, 12),
                itemCount: _entries.length,
                itemBuilder: (context, index) {
                  final entry = _entries[index];
                  final included = _isIncluded(entry);
                  return Opacity(
                    opacity: included ? 1 : 0.42,
                    child: TransactionTile(
                      entry,
                      accounts: accounts,
                      categories: categories,
                      selectionMode: true,
                      selected: included,
                      onTap: () => _toggle(entry),
                      onLongPress: () => _edit(entry, accounts, categories),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  onPressed: included.isEmpty
                      ? null
                      : () => Navigator.of(context).pop(included),
                  child: Text(l10n.importPreviewConfirm(included.length)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 汇总区的小胶囊（新建账户 / 新建分类计数）。
class _SummaryChip extends StatelessWidget {
  const _SummaryChip({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: 0.66);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}
