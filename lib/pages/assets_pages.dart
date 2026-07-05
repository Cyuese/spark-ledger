import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app/account_icon_assets.dart';
import '../app/app_theme.dart';
import '../app/avatar_picker.dart';
import '../app/chart_painters.dart';
import '../app/common_widgets.dart';
import '../app/credit_card.dart';
import '../app/demo_data.dart';
import '../app/entry_sheets.dart';
import '../app/image_cropper.dart';
import '../app/image_sources.dart';
import '../app/ledger_math.dart';
import '../app/models.dart';
import '../app/series_math.dart';
import '../app/veri_fin_controller.dart';
import '../app/veri_fin_scope.dart';
import '../l10n/app_localizations.dart';
import 'entry_detail_page.dart';
import 'sheets.dart';
import 'transactions_pages.dart';

const double assetCoverAspectRatio = 1200 / 760;

const int assetCoverTargetWidth = 1200;

const int assetCoverTargetHeight = 760;

class AssetsPage extends StatefulWidget {
  const AssetsPage({super.key});

  @override
  State<AssetsPage> createState() => _AssetsPageState();
}

class _AssetsPageState extends State<AssetsPage> {
  static const List<_AssetCoverPreset> _coverPresets = <_AssetCoverPreset>[
    _AssetCoverPreset(
      id: 'blue_city',
      url:
          'https://images.unsplash.com/photo-1480714378408-67cf0d13bc1f?auto=format&fit=crop&w=1200&q=80',
    ),
    _AssetCoverPreset(
      id: 'aurora',
      url:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
    ),
    _AssetCoverPreset(
      id: 'finance_office',
      url:
          'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=1200&q=80',
    ),
    _AssetCoverPreset(
      id: 'deep_blue',
      url:
          'https://images.unsplash.com/photo-1557682250-33bd709cbe85?auto=format&fit=crop&w=1200&q=80',
    ),
  ];

  bool _sortingSections = false;
  // 当前可见分组数，供「资产操作」菜单里的「排序分组」判断能否进入排序模式
  // （<2 个分组无从排序）。在 build 中同步。
  int _visibleSectionCount = 0;

  @override
  Widget build(BuildContext context) {
    final controller = VeriFinScope.of(context);
    final accounts = _sortedAccounts(controller.accounts);
    final groups = controller.accountGroups;
    final balances = <Account, double>{
      for (final account in accounts)
        account: controller.accountBalance(account),
    };
    final assetBalances = balances.entries
        .where((entry) => entry.key.includeInAssets && !entry.key.hidden)
        .map((entry) => entry.value);
    final assets = assetBalances
        .where((value) => value > 0)
        .fold<double>(0, (sum, value) => sum + value);
    final liabilities = assetBalances
        .where((value) => value < 0)
        .fold<double>(0, (sum, value) => sum + value);
    final assetTrendValues = monthlyNetAssetSeries(
      accounts,
      controller.entries,
    );
    final hasAssetCover = controller.assetCoverUrl.isNotEmpty;
    final assetCardTextColor = hasAssetCover
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;
    final assetCardMutedColor = assetCardTextColor.withValues(
      alpha: hasAssetCover ? 0.72 : 0.54,
    );
    final hiddenAccounts = accounts
        .where((account) => account.hidden)
        .toList(growable: false);
    final viewMode = controller.assetAccountViewMode;
    final visibleGroups = <AccountGroup>[
      ...groups,
      AccountGroup(
        id: 'ungrouped',
        bookId: controller.activeBook.id,
        name: AppLocalizations.of(context).assetsUngrouped,
        iconCode: 'folder',
        sortOrder: 999,
      ),
    ];
    final assetSections = controller.sortedAssetSections<_AssetAccountSection>(
      mode: viewMode,
      sections: viewMode == AssetAccountViewMode.group
          ? visibleGroups
                .map(
                  (group) => _AssetAccountSection(
                    id: group.id,
                    title: group.name,
                    accounts: controller.sortedAccountsForAssetSection(
                      mode: viewMode,
                      sectionId: group.id,
                      accounts: accounts.where(
                        (account) =>
                            _effectiveGroupId(account) == group.id &&
                            !account.hidden,
                      ),
                    ),
                  ),
                )
                .toList()
          : AccountType.values
                .map(
                  (type) => _AssetAccountSection(
                    id: type.name,
                    title: type.label(AppLocalizations.of(context)),
                    accounts: controller.sortedAccountsForAssetSection(
                      mode: viewMode,
                      sectionId: type.name,
                      accounts: accounts.where(
                        (account) => account.type == type && !account.hidden,
                      ),
                    ),
                  ),
                )
                .toList(),
      idOf: (section) => section.id,
    );
    final visibleAssetSections = assetSections
        .where((section) => section.accounts.isNotEmpty)
        .toList(growable: false);
    final canSortSections = visibleAssetSections.length >= 2;
    final sortingSections = _sortingSections && canSortSections;
    _visibleSectionCount = visibleAssetSections.length;

    return VeriPage(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 82),
        children: <Widget>[
          PageHeader(
            title: AppLocalizations.of(context).tabAssets,
            subtitle: AppLocalizations.of(context).netAssets,
            trailing: HeaderAction(
              icon: Icons.add,
              tooltip: AppLocalizations.of(context).assetsActions,
              onPressed: () => _showAssetActions(context),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            key: const Key('asset_cover_card'),
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: hasAssetCover
                  ? null
                  : Theme.of(context).brightness == Brightness.dark
                  ? veriSurfaceDark
                  : veriSurfaceLight,
              borderRadius: BorderRadius.circular(veriRadiusMd),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: 0.10)
                    : veriLine,
              ),
              image: !hasAssetCover
                  ? null
                  : DecorationImage(
                      image: imageProviderForSource(controller.assetCoverUrl),
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
              boxShadow: <BoxShadow>[
                if (Theme.of(context).brightness == Brightness.light)
                  BoxShadow(
                    color: const Color(0xFF0F172A).withValues(alpha: 0.045),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
              ],
            ),
            child: Stack(
              children: <Widget>[
                if (hasAssetCover)
                  Positioned.fill(
                    child: ColoredBox(
                      color: Colors.black.withValues(alpha: 0.28),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context).netAssets,
                              style: TextStyle(color: assetCardMutedColor),
                            ),
                          ),
                          IconButton(
                            tooltip: AppLocalizations.of(
                              context,
                            ).assetsChangeCover,
                            onPressed: () =>
                                _changeAssetCover(context, controller),
                            style: IconButton.styleFrom(
                              fixedSize: const Size(32, 32),
                              minimumSize: const Size(32, 32),
                              padding: EdgeInsets.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            icon: Icon(
                              Icons.photo_size_select_actual_outlined,
                              color: assetCardMutedColor,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatAmount(assets + liabilities),
                        style: Theme.of(context).textTheme.displaySmall
                            ?.copyWith(
                              color: assetCardTextColor,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            AppLocalizations.of(
                              context,
                            ).assetsAmount(formatAmount(assets)),
                            style: TextStyle(color: assetCardTextColor),
                          ),
                          Text(
                            AppLocalizations.of(context).liabilitiesAmount(
                              formatAmount(liabilities.abs()),
                            ),
                            style: TextStyle(color: assetCardTextColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 112,
                        child: InteractiveTrendChart(
                          color: assetCardTextColor,
                          values: assetTrendValues,
                          xLabels: evenMonthAxisLabels(),
                          labelColor: assetCardMutedColor,
                          tooltipOf: (index) => ChartTooltip(
                            title: AppLocalizations.of(
                              context,
                            ).monthNumber(index + 1),
                            lines: <ChartTooltipLine>[
                              ChartTooltipLine(
                                text: AppLocalizations.of(context)
                                    .netAssetsAmount(
                                      formatAmount(assetTrendValues[index]),
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (visibleAssetSections.isEmpty) ...[
            VeriCard(
              child: EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: AppLocalizations.of(context).assetsEmptyTitle,
                description: AppLocalizations.of(context).assetsEmptyDesc,
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (visibleAssetSections.isNotEmpty) ...<Widget>[
            // 「排序」按钮常驻分组列表上方（就算只有 1 个分组也显示，保证可发现，
            // 点击时不足 2 个分组会提示）；「资产操作」菜单里保留同一入口。
            // 进入排序模式后变为提示 + 「完成」。
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: sortingSections
                        ? Text(
                            AppLocalizations.of(context).assetsSortHint,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.52),
                                  fontWeight: FontWeight.w700,
                                ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  _SectionSortButton(
                    sorting: sortingSections,
                    onTap: sortingSections
                        ? () => setState(() => _sortingSections = false)
                        : () => _enterSectionSorting(context),
                  ),
                ],
              ),
            ),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              proxyDecorator: (_, index, _) {
                final section = visibleAssetSections[index];
                return Material(
                  color: Colors.transparent,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(veriRadiusMd),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.14),
                          blurRadius: 18,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: AccountGroupCard(
                      title: section.title,
                      accounts: section.accounts,
                      balances: balances,
                      collapsed: true,
                      sectionDragIndex: index,
                      hapticsEnabled: controller.hapticsEnabled,
                    ),
                  ),
                );
              },
              onReorderStart: (_) => _triggerSelectionHaptic(controller),
              onReorderEnd: (_) => _triggerSelectionHaptic(controller),
              onReorderItem: (oldIndex, newIndex) {
                _triggerSelectionHaptic(controller);
                controller.reorderAssetSections<_AssetAccountSection>(
                  mode: viewMode,
                  sections: visibleAssetSections,
                  idOf: (section) => section.id,
                  oldIndex: oldIndex,
                  newIndex: newIndex,
                );
              },
              itemCount: visibleAssetSections.length,
              itemBuilder: (context, index) {
                final section = visibleAssetSections[index];
                return Padding(
                  key: ValueKey<String>('asset_section_${section.id}'),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AccountGroupCard(
                    title: section.title,
                    accounts: section.accounts,
                    balances: balances,
                    collapsed:
                        sortingSections ||
                        controller.isAssetSectionCollapsed(
                          mode: viewMode,
                          sectionId: section.id,
                        ),
                    sectionDragIndex: sortingSections ? index : null,
                    sectionDragImmediate: true,
                    hapticsEnabled: controller.hapticsEnabled,
                    onToggleCollapsed: sortingSections
                        ? null
                        : () => controller.toggleAssetSectionCollapsed(
                            mode: viewMode,
                            sectionId: section.id,
                          ),
                    onReorderAccounts: (oldIndex, newIndex) =>
                        controller.reorderAssetAccounts(
                          mode: viewMode,
                          sectionId: section.id,
                          accounts: section.accounts,
                          oldIndex: oldIndex,
                          newIndex: newIndex,
                        ),
                    onAccountTap: sortingSections
                        ? null
                        : (account) {
                            Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (context) =>
                                    AccountDetailPage(account: account),
                              ),
                            );
                          },
                  ),
                );
              },
            ),
          ],
          if (hiddenAccounts.isNotEmpty) ...<Widget>[
            VeriCard(
              onTap: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder: (context) => const HiddenAccountsPage(),
                  ),
                );
              },
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.visibility_off_outlined,
                    size: 18,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.42),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      AppLocalizations.of(
                        context,
                      ).hiddenAccountsCount(hiddenAccounts.length),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.52),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.36),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  void _triggerSelectionHaptic(VeriFinController controller) {
    if (controller.hapticsEnabled) {
      HapticFeedback.selectionClick();
    }
  }

  Future<void> _changeAssetCover(
    BuildContext context,
    VeriFinController controller,
  ) async {
    final action = await showOptionSheet<String>(
      context: context,
      title: AppLocalizations.of(context).assetsCoverTitle,
      values: const <String>['online', 'custom_url', 'local', 'clear'],
      selected: 'online',
      labelOf: (value) {
        return switch (value) {
          'online' => AppLocalizations.of(context).coverUseOnline,
          'custom_url' => AppLocalizations.of(context).coverEnterUrl,
          'local' => AppLocalizations.of(context).coverPickLocal,
          'clear' => AppLocalizations.of(context).coverClear,
          _ => value,
        };
      },
    );
    if (action == null || !context.mounted) {
      return;
    }

    switch (action) {
      case 'online':
        final selected = await showOptionSheet<_AssetCoverPreset>(
          context: context,
          title: AppLocalizations.of(context).coverPickOnlineTitle,
          values: _coverPresets,
          selected: _coverPresets.firstWhere(
            (item) => item.url == controller.assetCoverUrl,
            orElse: () => _coverPresets.first,
          ),
          labelOf: (value) => value.label(AppLocalizations.of(context)),
        );
        if (selected != null) {
          controller.setAssetCoverUrl(selected.url);
        }
      case 'custom_url':
        final url = await showTextInputDialog(
          context: context,
          title: AppLocalizations.of(context).coverCustomTitle,
          label: AppLocalizations.of(context).coverUrlLabel,
          initialValue: controller.assetCoverUrl.startsWith('http')
              ? controller.assetCoverUrl
              : '',
        );
        if (url != null) {
          controller.setAssetCoverUrl(url);
        }
      case 'local':
        final rawImage = await pickRawImageDataUrl();
        if (rawImage == null || !context.mounted) {
          return;
        }
        final crop = await showImageCropper(
          context: context,
          imageDataUrl: rawImage,
          title: AppLocalizations.of(context).coverCropTitle,
          aspectRatio: assetCoverAspectRatio,
        );
        if (crop == null || !context.mounted) {
          return;
        }
        final dataUrl = await runWithLoadingDialog<String?>(
          context: context,
          message: AppLocalizations.of(context).coverGenerating,
          task: () => cropImageDataUrl(
            sourceDataUrl: rawImage,
            targetWidth: assetCoverTargetWidth,
            targetHeight: assetCoverTargetHeight,
            zoom: crop.zoom,
            offsetX: crop.offsetX,
            offsetY: crop.offsetY,
          ),
        );
        if (dataUrl != null) {
          controller.setAssetCoverUrl(dataUrl);
        }
      case 'clear':
        controller.setAssetCoverUrl('');
    }
  }

  Future<void> _showAssetActions(BuildContext context) async {
    final controller = VeriFinScope.of(context);
    final selected = await showOptionSheet<String>(
      context: context,
      title: AppLocalizations.of(context).assetsActions,
      values: const <String>[
        'add_account',
        'manage_groups',
        'switch_view',
        'sort_sections',
      ],
      selected: 'add_account',
      labelOf: (value) {
        return switch (value) {
          'add_account' => AppLocalizations.of(context).accountAdd,
          'manage_groups' => AppLocalizations.of(context).groupManage,
          'switch_view' => controller.assetAccountViewMode.toggleLabel(
            AppLocalizations.of(context),
          ),
          'sort_sections' => AppLocalizations.of(context).sectionSort,
          _ => value,
        };
      },
    );
    if (selected == null || !context.mounted) {
      return;
    }
    if (selected == 'add_account') {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(builder: (context) => const AddAccountPage()),
      );
    }
    if (selected == 'manage_groups') {
      Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (context) => const AccountGroupsPage(),
        ),
      );
    }
    if (selected == 'switch_view') {
      controller.toggleAssetAccountViewMode();
    }
    if (selected == 'sort_sections') {
      _enterSectionSorting(context);
    }
  }

  void _enterSectionSorting(BuildContext context) {
    if (_visibleSectionCount >= 2) {
      setState(() => _sortingSections = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).sectionSortNeedTwo),
        ),
      );
    }
  }
}

class _SectionSortButton extends StatelessWidget {
  const _SectionSortButton({required this.sorting, required this.onTap});

  final bool sorting;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(sorting ? Icons.check : Icons.swap_vert, size: 16),
      label: Text(
        sorting
            ? AppLocalizations.of(context).commonDone
            : AppLocalizations.of(context).sortLabel,
      ),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        foregroundColor: sorting
            ? veriRoyal
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
        textStyle: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _AssetAccountSection {
  const _AssetAccountSection({
    required this.id,
    required this.title,
    required this.accounts,
  });

  final String id;
  final String title;
  final List<Account> accounts;
}

class _AssetCoverPreset {
  const _AssetCoverPreset({required this.id, required this.url});

  final String id;
  final String url;

  String label(AppLocalizations l10n) {
    switch (id) {
      case 'blue_city':
        return l10n.coverBlueCity;
      case 'aurora':
        return l10n.coverAurora;
      case 'finance_office':
        return l10n.coverFinanceOffice;
      case 'deep_blue':
        return l10n.coverDeepBlue;
    }
    return id;
  }
}

String _effectiveGroupId(Account account) {
  return account.groupId ?? 'ungrouped';
}

List<Account> _sortedAccounts(Iterable<Account> accounts) {
  final sorted = accounts.toList();
  sorted.sort((a, b) {
    final hiddenCompare = (a.hidden ? 1 : 0).compareTo(b.hidden ? 1 : 0);
    if (hiddenCompare != 0) {
      return hiddenCompare;
    }
    final includeCompare = (b.includeInAssets ? 1 : 0).compareTo(
      a.includeInAssets ? 1 : 0,
    );
    if (includeCompare != 0) {
      return includeCompare;
    }
    final typeCompare = a.type.index.compareTo(b.type.index);
    if (typeCompare != 0) {
      return typeCompare;
    }
    return a.name.compareTo(b.name);
  });
  return sorted;
}

class HiddenAccountsPage extends StatelessWidget {
  const HiddenAccountsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = VeriFinScope.of(context);
    final accounts = controller.accounts
        .where((account) => account.hidden)
        .toList(growable: false);
    final balances = <Account, double>{
      for (final account in accounts)
        account: controller.accountBalance(account),
    };

    return Scaffold(
      body: SafeArea(
        child: VeriPage(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
            children: <Widget>[
              VeriHeader(
                title: AppLocalizations.of(context).hiddenAccountsTitle,
                showBack: true,
              ),
              const SizedBox(height: 10),
              if (accounts.isEmpty)
                VeriCard(
                  child: EmptyState(
                    icon: Icons.visibility_off_outlined,
                    title: AppLocalizations.of(
                      context,
                    ).hiddenAccountsEmptyTitle,
                    description: AppLocalizations.of(
                      context,
                    ).hiddenAccountsEmptyDesc,
                  ),
                )
              else
                AccountGroupCard(
                  title: AppLocalizations.of(context).hiddenAccountsTitle,
                  accounts: _sortedAccounts(accounts),
                  balances: balances,
                  onAccountTap: (account) {
                    Navigator.of(context).push<void>(
                      MaterialPageRoute<void>(
                        builder: (context) =>
                            AccountDetailPage(account: account),
                      ),
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class AccountGroupsPage extends StatefulWidget {
  const AccountGroupsPage({super.key});

  @override
  State<AccountGroupsPage> createState() => _AccountGroupsPageState();
}

class _AccountGroupsPageState extends State<AccountGroupsPage> {
  String? _selectedGroupId;

  @override
  Widget build(BuildContext context) {
    final controller = VeriFinScope.of(context);
    final groups = controller.accountGroups;
    final accounts = controller.accounts;

    return Scaffold(
      body: SafeArea(
        child: VeriPage(
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
                child: VeriHeader(
                  title: AppLocalizations.of(context).accountGroupsTitle,
                  showBack: true,
                  actions: <Widget>[
                    HeaderAction(
                      icon: Icons.add,
                      tooltip: AppLocalizations.of(context).groupAdd,
                      onPressed: () => _showGroupNameDialog(context),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: groups.isEmpty
                    ? ListView(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 86),
                        children: <Widget>[
                          VeriCard(
                            child: EmptyState(
                              icon: Icons.folder_open_outlined,
                              title: AppLocalizations.of(
                                context,
                              ).groupsEmptyTitle,
                              description: AppLocalizations.of(
                                context,
                              ).groupsEmptyDesc,
                            ),
                          ),
                        ],
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 86),
                        itemCount: groups.length,
                        // ignore: deprecated_member_use
                        onReorder: controller.reorderAccountGroup,
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          final groupAccounts = accounts
                              .where(
                                (account) =>
                                    _effectiveGroupId(account) == group.id,
                              )
                              .toList();
                          final total = groupAccounts.fold<double>(
                            0,
                            (sum, account) =>
                                sum + controller.accountBalance(account),
                          );
                          final selected = _selectedGroupId == group.id;

                          return Padding(
                            key: ValueKey(group.id),
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(veriRadiusMd),
                              onLongPress: () =>
                                  setState(() => _selectedGroupId = group.id),
                              onTap: () => setState(() {
                                _selectedGroupId = selected ? null : group.id;
                              }),
                              child: VeriCard(
                                child: Row(
                                  children: <Widget>[
                                    VeriIconBox(
                                      icon: iconForCode(group.iconCode),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: <Widget>[
                                          Text(
                                            group.name,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleMedium,
                                          ),
                                          const SizedBox(height: 5),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .surfaceContainerHighest,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                    veriRadiusSm,
                                                  ),
                                            ),
                                            child: Text(
                                              AppLocalizations.of(
                                                context,
                                              ).accountsCount(
                                                groupAccounts.length,
                                              ),
                                              style: Theme.of(
                                                context,
                                              ).textTheme.labelSmall,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      formatAmount(total),
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                    if (selected) const SizedBox(width: 6),
                                    if (selected)
                                      const Icon(
                                        Icons.check_circle,
                                        color: veriBlue,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _selectedGroupId == null
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => _showGroupNameDialog(
                          context,
                          groupId: _selectedGroupId,
                        ),
                        icon: const Icon(Icons.edit),
                        label: Text(AppLocalizations.of(context).commonRename),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => _showIconDialog(context),
                        icon: const Icon(Icons.palette_outlined),
                        label: Text(AppLocalizations.of(context).commonIcon),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () {
                          controller.deleteAccountGroup(_selectedGroupId!);
                          setState(() => _selectedGroupId = null);
                        },
                        icon: const Icon(Icons.delete_outline),
                        label: Text(AppLocalizations.of(context).commonDelete),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Future<void> _showGroupNameDialog(
    BuildContext context, {
    String? groupId,
  }) async {
    final controller = VeriFinScope.of(context);
    final editingGroup = groupId == null
        ? null
        : controller.accountGroups.firstWhere((group) => group.id == groupId);
    final textController = TextEditingController(
      text: editingGroup?.name ?? '',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          groupId == null
              ? AppLocalizations.of(context).groupAdd
              : AppLocalizations.of(context).groupRenameTitle,
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).groupNameLabel,
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).commonCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(textController.text),
            child: Text(AppLocalizations.of(context).commonConfirm),
          ),
        ],
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => textController.dispose(),
    );
    if (!context.mounted || name == null) {
      return;
    }
    if (groupId == null) {
      controller.addAccountGroup(name);
    } else {
      controller.renameAccountGroup(groupId, name);
    }
  }

  Future<void> _showIconDialog(BuildContext context) async {
    final controller = VeriFinScope.of(context);
    final groupId = _selectedGroupId;
    if (groupId == null) {
      return;
    }
    final current = controller.accountGroups
        .where((group) => group.id == groupId)
        .firstOrNull;
    final iconCode = await showOptionSheet<String>(
      context: context,
      title: AppLocalizations.of(context).groupIconPickerTitle,
      values: accountIconCodes,
      selected: current?.iconCode ?? 'folder',
      labelOf: (code) => iconLabelForCode(AppLocalizations.of(context), code),
    );
    if (iconCode != null) {
      controller.updateAccountGroupIcon(groupId, iconCode);
    }
  }
}

class AddAccountPage extends StatefulWidget {
  const AddAccountPage({super.key});

  @override
  State<AddAccountPage> createState() => _AddAccountPageState();
}

class _AccountIconSelectField extends StatelessWidget {
  const _AccountIconSelectField({
    super.key,
    required this.iconCode,
    required this.onTap,
  });

  final String iconCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(veriRadiusMd),
        onTap: onTap,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: AppLocalizations.of(context).accountIconLabel,
            suffixIcon: Icon(Icons.keyboard_arrow_down),
          ),
          child: Row(
            children: <Widget>[
              AccountIconBox(iconCode: iconCode, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  iconLabelForCode(AppLocalizations.of(context), iconCode),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddAccountPageState extends State<AddAccountPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _cardLast4Controller = TextEditingController();
  final _noteController = TextEditingController();
  AccountType _type = AccountType.onlinePayment;
  String _iconCode = 'wallet';
  String _groupId = 'ungrouped';
  bool _iconManuallySelected = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_suggestIconFromName);
  }

  @override
  void dispose() {
    _nameController.removeListener(_suggestIconFromName);
    _nameController.dispose();
    _balanceController.dispose();
    _cardLast4Controller.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = VeriFinScope.of(context);
    final groups = controller.accountGroups;

    return Scaffold(
      body: SafeArea(
        child: VeriPage(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
              children: <Widget>[
                VeriHeader(
                  title: AppLocalizations.of(context).accountAdd,
                  showBack: true,
                  actions: <Widget>[
                    HeaderAction(
                      icon: Icons.check,
                      tooltip: AppLocalizations.of(context).accountSaveTooltip,
                      onPressed: _save,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                SelectField(
                  label: AppLocalizations.of(context).accountTypeLabel,
                  value: _type.label(AppLocalizations.of(context)),
                  icon: Icons.category_outlined,
                  onTap: _pickAccountType,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).accountNameLabel,
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return AppLocalizations.of(context).accountNameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                if (_type.supportsCardLast4) ...<Widget>[
                  TextFormField(
                    controller: _cardLast4Controller,
                    maxLength: 4,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context).cardLast4Label,
                      counterText: '',
                    ),
                    validator: (value) {
                      final text = value?.trim() ?? '';
                      if (text.isEmpty) {
                        return null;
                      }
                      if (!RegExp(r'^\d{1,4}$').hasMatch(text)) {
                        return AppLocalizations.of(context).cardLast4Invalid;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                TextFormField(
                  controller: _balanceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).accountBalanceLabel,
                    hintText: AppLocalizations.of(context).accountBalanceHint,
                  ),
                ),
                const SizedBox(height: 10),
                _AccountIconSelectField(
                  key: const Key('account_icon_select_field'),
                  iconCode: _iconCode,
                  onTap: _pickAccountIcon,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _noteController,
                  maxLines: 1,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context).accountNoteLabel,
                  ),
                ),
                const SizedBox(height: 10),
                SelectField(
                  label: AppLocalizations.of(context).accountGroupLabel,
                  value: _groupLabel(groups),
                  icon: Icons.folder_outlined,
                  onTap: () => _pickAccountGroup(groups),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAccountType() async {
    final selected = await showOptionSheet<AccountType>(
      context: context,
      title: AppLocalizations.of(context).accountTypePickerTitle,
      values: AccountType.values,
      selected: _type,
      labelOf: (value) => value.label(AppLocalizations.of(context)),
    );
    if (selected != null) {
      setState(() {
        _type = selected;
        if (!_type.supportsCardLast4) {
          _cardLast4Controller.clear();
        }
      });
    }
  }

  Future<void> _pickAccountIcon() async {
    final selected = await showAccountIconSheet(
      context: context,
      selected: _iconCode,
    );
    if (selected != null) {
      setState(() {
        _iconCode = selected;
        _iconManuallySelected = true;
      });
    }
  }

  void _suggestIconFromName() {
    if (_iconManuallySelected) {
      return;
    }
    final suggested = suggestedAccountIconCode(_nameController.text);
    if (suggested == null || suggested == _iconCode) {
      return;
    }
    setState(() => _iconCode = suggested);
  }

  Future<void> _pickAccountGroup(List<AccountGroup> groups) async {
    final values = <String>['ungrouped', ...groups.map((group) => group.id)];
    final selected = await showOptionSheet<String>(
      context: context,
      title: AppLocalizations.of(context).accountGroupPickerTitle,
      values: values,
      selected: _groupId,
      labelOf: (value) {
        if (value == 'ungrouped') {
          return AppLocalizations.of(context).assetsUngrouped;
        }
        return groups
            .firstWhere(
              (group) => group.id == value,
              orElse: () => AccountGroup(
                id: 'ungrouped',
                bookId: defaultLedgerBookId,
                name: AppLocalizations.of(context).assetsUngrouped,
                iconCode: 'folder',
                sortOrder: 999,
              ),
            )
            .name;
      },
    );
    if (selected != null) {
      setState(() => _groupId = selected);
    }
  }

  String _groupLabel(List<AccountGroup> groups) {
    if (_groupId == 'ungrouped') {
      return AppLocalizations.of(context).assetsUngrouped;
    }
    return groups
        .firstWhere(
          (group) => group.id == _groupId,
          orElse: () => AccountGroup(
            id: 'ungrouped',
            bookId: defaultLedgerBookId,
            name: AppLocalizations.of(context).assetsUngrouped,
            iconCode: 'folder',
            sortOrder: 999,
          ),
        )
        .name;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final controller = VeriFinScope.of(context);
    controller.addAccount(
      Account(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        bookId: controller.activeBook.id,
        name: _nameController.text.trim(),
        type: _type,
        groupId: _groupId,
        initialBalance: double.tryParse(_balanceController.text.trim()) ?? 0,
        iconCode: _iconCode,
        note: _noteController.text.trim(),
        includeInAssets: true,
        hidden: false,
        cardLast4: _type.supportsCardLast4
            ? _cardLast4Controller.text.trim()
            : '',
      ),
    );
    Navigator.of(context).pop();
  }
}

class AccountDetailPage extends StatefulWidget {
  const AccountDetailPage({super.key, required this.account});

  final Account account;

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  bool _monthlyTrend = false;

  @override
  Widget build(BuildContext context) {
    final controller = VeriFinScope.of(context);
    final currentAccount = controller.accounts.firstWhere(
      (item) => item.id == widget.account.id,
      orElse: () => widget.account,
    );
    final balance = controller.accountBalance(currentAccount);
    final entries = controller.entries
        .where((entry) => entryTouchesAccount(entry, currentAccount.id))
        .toList();
    final balanceTrendValues = _monthlyTrend
        ? accountMonthlyBalanceSeries(currentAccount, entries)
        : accountBalanceSeries(currentAccount, entries);
    final matchingGroups = controller.accountGroups.where(
      (group) => group.id == currentAccount.groupId,
    );
    final groupName = matchingGroups.isEmpty
        ? AppLocalizations.of(context).assetsUngrouped
        : matchingGroups.first.name;

    return Scaffold(
      body: SafeArea(
        child: VeriPage(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
            children: <Widget>[
              VeriHeader(
                title: currentAccount.name,
                subtitle: currentAccount.type.label(
                  AppLocalizations.of(context),
                ),
                showBack: true,
                actions: <Widget>[
                  HeaderAction(
                    icon: Icons.edit_outlined,
                    tooltip: AppLocalizations.of(context).balanceAdjustTooltip,
                    onPressed: () => _editBalance(currentAccount, balance),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (currentAccount.type == AccountType.creditCard &&
                  currentAccount.dueDay != null) ...<Widget>[
                _CreditCardDueBanner(dueDay: currentAccount.dueDay!),
                const SizedBox(height: 10),
              ],
              VeriCard(
                onTap: () => _editBalance(currentAccount, balance),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(AppLocalizations.of(context).currentBalance),
                          const SizedBox(height: 6),
                          Text(
                            formatAmount(balance),
                            style: Theme.of(context).textTheme.displaySmall
                                ?.copyWith(
                                  color: veriBlue,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ],
                      ),
                    ),
                    VeriIconBox(icon: Icons.edit_outlined, size: 36),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              VeriCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context).balanceTrend,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        _MiniSegmentedToggle(
                          value: _monthlyTrend,
                          leftLabel: AppLocalizations.of(context).dayShort,
                          rightLabel: AppLocalizations.of(context).monthShort,
                          onChanged: (value) =>
                              setState(() => _monthlyTrend = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 148,
                      child: InteractiveTrendChart(
                        color: veriBlue,
                        values: balanceTrendValues,
                        xLabels: _monthlyTrend
                            ? evenMonthAxisLabels()
                            : monthAxisLabels(DateTime.now()),
                        yLabels: balanceAxisLabels(balanceTrendValues),
                        labelColor: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.50),
                        tooltipOf: (index) => ChartTooltip(
                          title: _monthlyTrend
                              ? AppLocalizations.of(
                                  context,
                                ).monthNumber(index + 1)
                              : AppLocalizations.of(context).dateMonthDay(
                                  DateTime(
                                    DateTime.now().year,
                                    DateTime.now().month,
                                    index + 1,
                                  ),
                                ),
                          lines: <ChartTooltipLine>[
                            ChartTooltipLine(
                              text: AppLocalizations.of(context).balanceAmount(
                                formatAmount(balanceTrendValues[index]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (context) =>
                                AccountReportPage(account: currentAccount),
                          ),
                        );
                      },
                      child: Text(AppLocalizations.of(context).viewReport),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              VeriCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            AppLocalizations.of(context).panelRecentLabel,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        VeriSectionAction(
                          icon: Icons.add,
                          tooltip: AppLocalizations.of(context).addEntryTooltip,
                          onPressed: () =>
                              _startEntryForAccount(context, currentAccount),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    if (entries.isEmpty)
                      EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: AppLocalizations.of(context).noEntriesTitle,
                        description: AppLocalizations.of(
                          context,
                        ).accountNoEntriesDesc,
                      )
                    else
                      ...entries
                          .take(3)
                          .map(
                            (entry) => TransactionTile(
                              entry,
                              accounts: controller.accounts,
                              categories: controller.categories,
                              onTap: () => openEntryDetail(context, entry),
                            ),
                          ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute<void>(
                            builder: (context) => TransactionsPage(
                              accountId: currentAccount.id,
                              title: AppLocalizations.of(
                                context,
                              ).accountEntriesTitle(currentAccount.name),
                            ),
                          ),
                        );
                      },
                      child: Text(AppLocalizations.of(context).allEntries),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              VeriCard(
                child: Column(
                  children: <Widget>[
                    CompactSwitchRow(
                      icon: Icons.account_balance_wallet_outlined,
                      title: Text(AppLocalizations.of(context).includeInAssets),
                      value: currentAccount.includeInAssets,
                      onChanged: (value) {
                        controller.updateAccount(
                          currentAccount.copyWith(includeInAssets: value),
                        );
                      },
                    ),
                    const Divider(height: 1),
                    CompactSwitchRow(
                      icon: Icons.visibility_off_outlined,
                      title: Text(AppLocalizations.of(context).accountHide),
                      value: currentAccount.hidden,
                      onChanged: (value) {
                        controller.updateAccount(
                          currentAccount.copyWith(hidden: value),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              VeriCard(
                child: Column(
                  children: <Widget>[
                    SettingsRow(
                      icon: Icons.category_outlined,
                      title: AppLocalizations.of(context).commonType,
                      trailing: currentAccount.type.label(
                        AppLocalizations.of(context),
                      ),
                      trailingIcon: Icons.chevron_right,
                      onTap: () => _pickAccountType(currentAccount),
                    ),
                    const Divider(),
                    SettingsRow(
                      icon: Icons.badge_outlined,
                      title: AppLocalizations.of(context).commonName,
                      trailing: currentAccount.name,
                      trailingIcon: Icons.chevron_right,
                      onTap: () => _editAccountName(currentAccount),
                    ),
                    const Divider(),
                    if (currentAccount.type.supportsCardLast4) ...<Widget>[
                      SettingsRow(
                        icon: Icons.credit_card,
                        title: AppLocalizations.of(context).cardLast4Label,
                        trailing: currentAccount.cardLast4.isEmpty
                            ? AppLocalizations.of(context).notSet
                            : currentAccount.cardLast4,
                        trailingIcon: Icons.chevron_right,
                        onTap: () => _editCardLast4(currentAccount),
                      ),
                      const Divider(),
                    ],
                    if (currentAccount.type ==
                        AccountType.creditCard) ...<Widget>[
                      SettingsRow(
                        icon: Icons.event_note_outlined,
                        title: AppLocalizations.of(context).statementDay,
                        trailing: currentAccount.statementDay == null
                            ? AppLocalizations.of(context).notSet
                            : AppLocalizations.of(
                                context,
                              ).monthlyDayLabel(currentAccount.statementDay!),
                        trailingIcon: Icons.chevron_right,
                        onTap: () => _pickBillingDay(currentAccount, false),
                      ),
                      const Divider(),
                      SettingsRow(
                        icon: Icons.event_available_outlined,
                        title: AppLocalizations.of(context).dueDay,
                        trailing: currentAccount.dueDay == null
                            ? AppLocalizations.of(context).notSet
                            : AppLocalizations.of(
                                context,
                              ).monthlyDayLabel(currentAccount.dueDay!),
                        trailingIcon: Icons.chevron_right,
                        onTap: () => _pickBillingDay(currentAccount, true),
                      ),
                      const Divider(),
                    ],
                    SettingsRow(
                      icon: Icons.image_outlined,
                      title: AppLocalizations.of(context).commonIcon,
                      trailing: iconLabelForCode(
                        AppLocalizations.of(context),
                        currentAccount.iconCode,
                      ),
                      trailingIcon: Icons.chevron_right,
                      onTap: () => _pickAccountIcon(currentAccount),
                    ),
                    const Divider(),
                    SettingsRow(
                      icon: Icons.currency_yuan,
                      title: AppLocalizations.of(context).commonCurrency,
                      trailing: AppLocalizations.of(context).currencyCny,
                    ),
                    const Divider(),
                    SettingsRow(
                      icon: Icons.notes,
                      title: AppLocalizations.of(context).commonNote,
                      trailing: currentAccount.note.isEmpty
                          ? AppLocalizations.of(context).commonNoneShort
                          : currentAccount.note,
                      trailingIcon: Icons.chevron_right,
                      onTap: () => _editAccountNote(currentAccount),
                    ),
                    const Divider(),
                    SettingsRow(
                      icon: Icons.folder_outlined,
                      title: AppLocalizations.of(context).commonGroup,
                      trailing: groupName,
                      trailingIcon: Icons.chevron_right,
                      onTap: () => _pickAccountGroup(currentAccount),
                    ),
                    const Divider(),
                    SettingsRow(
                      icon: Icons.delete_outline,
                      title: AppLocalizations.of(context).accountDelete,
                      trailing: entries.isEmpty
                          ? AppLocalizations.of(context).deletableLabel
                          : AppLocalizations.of(context).hasEntriesLabel,
                      trailingIcon: Icons.chevron_right,
                      onTap: () => confirmDeleteAccount(
                        context,
                        currentAccount,
                        entries,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editBalance(Account account, double balance) async {
    final amount = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => NumberPadSheet(
        title: AppLocalizations.of(context).balanceAdjustTooltip,
        initialAmount: balance,
        allowNegative: true,
        allowZero: true,
        hapticsEnabled: VeriFinScope.of(context).hapticsEnabled,
      ),
    );
    if (amount == null || !mounted) {
      return;
    }
    var recordEntry = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(AppLocalizations.of(context).balanceEditConfirmTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                AppLocalizations.of(
                  context,
                ).balanceEditConfirmMessage(account.name, formatAmount(amount)),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                value: recordEntry,
                onChanged: (value) =>
                    setDialogState(() => recordEntry = value ?? true),
                title: Text(AppLocalizations.of(context).balanceEditRecord),
                subtitle: Text(
                  AppLocalizations.of(context).balanceEditRecordDesc,
                ),
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(AppLocalizations.of(context).commonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(AppLocalizations.of(context).commonConfirm),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final controller = VeriFinScope.of(context);
    if (recordEntry) {
      controller.adjustAccountBalance(
        account,
        amount,
        note: AppLocalizations.of(context).balanceAdjustNote,
      );
    } else {
      controller.rebaseAccountBalance(account, amount);
    }
  }

  Future<void> _startEntryForAccount(
    BuildContext context,
    Account account,
  ) async {
    final amount = await showModalBottomSheet<double>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => NumberPadSheet(
        title: AppLocalizations.of(context).quickEntry,
        hapticsEnabled: VeriFinScope.of(context).hapticsEnabled,
      ),
    );
    if (!context.mounted || amount == null || amount <= 0) {
      return;
    }
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (context) => EntryDetailPage(
          initialAmount: amount,
          initialAccountId: account.id,
        ),
      ),
    );
  }

  Future<void> _pickAccountType(Account account) async {
    final selected = await showOptionSheet<AccountType>(
      context: context,
      title: AppLocalizations.of(context).accountTypePickerTitle,
      values: AccountType.values,
      selected: account.type,
      labelOf: (value) => value.label(AppLocalizations.of(context)),
    );
    if (selected != null && mounted) {
      VeriFinScope.of(context).updateAccount(
        account.copyWith(
          type: selected,
          cardLast4: selected.supportsCardLast4 ? account.cardLast4 : '',
        ),
      );
    }
  }

  Future<void> _editAccountName(Account account) async {
    final name = await showTextInputDialog(
      context: context,
      title: AppLocalizations.of(context).accountNameEditTitle,
      label: AppLocalizations.of(context).accountNameLabel,
      initialValue: account.name,
    );
    if (name != null && mounted) {
      final suggested = suggestedAccountIconCode(name);
      VeriFinScope.of(context).updateAccount(
        account.copyWith(name: name, iconCode: suggested ?? account.iconCode),
      );
    }
  }

  Future<void> _editCardLast4(Account account) async {
    final cardLast4 = await showTextInputDialog(
      context: context,
      title: AppLocalizations.of(context).cardLast4EditTitle,
      label: AppLocalizations.of(context).cardLast4Label,
      initialValue: account.cardLast4,
      allowEmpty: true,
      keyboardType: TextInputType.number,
    );
    if (cardLast4 == null || !mounted) {
      return;
    }
    final normalized = cardLast4.replaceAll(RegExp(r'\D'), '');
    VeriFinScope.of(context).updateAccount(
      account.copyWith(
        cardLast4: normalized.length > 4
            ? normalized.substring(normalized.length - 4)
            : normalized,
      ),
    );
  }

  Future<void> _pickAccountIcon(Account account) async {
    final selected = await showAccountIconSheet(
      context: context,
      selected: account.iconCode,
    );
    if (selected != null && mounted) {
      VeriFinScope.of(
        context,
      ).updateAccount(account.copyWith(iconCode: selected));
    }
  }

  /// 选择信用卡账单日 / 还款日（1–28 或不设置）。
  Future<void> _pickBillingDay(Account account, bool isDue) async {
    const clearValue = 0;
    final current =
        (isDue ? account.dueDay : account.statementDay) ?? clearValue;
    final selected = await showOptionSheet<int>(
      context: context,
      title: isDue
          ? AppLocalizations.of(context).pickDueDay
          : AppLocalizations.of(context).pickStatementDay,
      values: <int>[clearValue, for (var d = 1; d <= 28; d++) d],
      selected: current,
      labelOf: (value) => value == clearValue
          ? AppLocalizations.of(context).clearOption
          : AppLocalizations.of(context).monthlyDayLabel(value),
    );
    if (selected == null || !mounted) {
      return;
    }
    final controller = VeriFinScope.of(context);
    if (isDue) {
      controller.updateAccount(
        account.copyWith(
          dueDay: selected == clearValue ? null : selected,
          clearDueDay: selected == clearValue,
        ),
      );
    } else {
      controller.updateAccount(
        account.copyWith(
          statementDay: selected == clearValue ? null : selected,
          clearStatementDay: selected == clearValue,
        ),
      );
    }
  }

  Future<void> _editAccountNote(Account account) async {
    final note = await showTextInputDialog(
      context: context,
      title: AppLocalizations.of(context).accountNoteEditTitle,
      label: AppLocalizations.of(context).commonNote,
      initialValue: account.note,
      allowEmpty: true,
    );
    if (note != null && mounted) {
      VeriFinScope.of(context).updateAccount(account.copyWith(note: note));
    }
  }

  Future<void> _pickAccountGroup(Account account) async {
    final controller = VeriFinScope.of(context);
    final groups = controller.accountGroups;
    final values = <String>['ungrouped', ...groups.map((group) => group.id)];
    final selected = await showOptionSheet<String>(
      context: context,
      title: AppLocalizations.of(context).accountGroupPickerTitle,
      values: values,
      selected: account.groupId ?? 'ungrouped',
      labelOf: (value) {
        if (value == 'ungrouped') {
          return AppLocalizations.of(context).assetsUngrouped;
        }
        return groups.firstWhere((group) => group.id == value).name;
      },
    );
    if (selected != null && mounted) {
      controller.updateAccount(account.copyWith(groupId: selected));
    }
  }
}

class _MiniSegmentedToggle extends StatelessWidget {
  const _MiniSegmentedToggle({
    required this.value,
    required this.leftLabel,
    required this.rightLabel,
    required this.onChanged,
  });

  final bool value;
  final String leftLabel;
  final String rightLabel;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(veriRadiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _MiniSegmentButton(
            label: leftLabel,
            selected: !value,
            onTap: () => onChanged(false),
          ),
          _MiniSegmentButton(
            label: rightLabel,
            selected: value,
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }
}

class _MiniSegmentButton extends StatelessWidget {
  const _MiniSegmentButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected
          ? Theme.of(context).colorScheme.surface
          : Colors.transparent,
      borderRadius: BorderRadius.circular(veriRadiusSm - 2),
      child: InkWell(
        borderRadius: BorderRadius.circular(veriRadiusSm - 2),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: selected ? 0.88 : 0.48),
            ),
          ),
        ),
      ),
    );
  }
}

class AccountReportPage extends StatelessWidget {
  const AccountReportPage({super.key, required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final controller = VeriFinScope.of(context);
    final currentAccount = controller.accounts.firstWhere(
      (item) => item.id == account.id,
      orElse: () => account,
    );
    final entries = controller.entries
        .where((entry) => entryTouchesAccount(entry, currentAccount.id))
        .toList();
    final expense = sumByType(entries, EntryType.expense);
    final income = sumByType(entries, EntryType.income);
    final balance = controller.accountBalance(currentAccount);
    final reportBalanceValues = accountBalanceSeries(currentAccount, entries);

    return Scaffold(
      body: SafeArea(
        child: VeriPage(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 28),
            children: <Widget>[
              VeriHeader(
                title: AppLocalizations.of(context).accountReportTitle,
                subtitle: currentAccount.name,
                showBack: true,
              ),
              const SizedBox(height: 10),
              VeriCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 16,
                ),
                child: Row(
                  children: <Widget>[
                    SummaryMetric(
                      label: AppLocalizations.of(context).currentBalance,
                      value: formatAmount(balance),
                      color: balance < 0 ? veriExpense : veriRoyal,
                    ),
                    SummaryMetric(
                      label: AppLocalizations.of(context).entryTypeIncome,
                      value: formatAmount(income),
                      color: veriIncome,
                    ),
                    SummaryMetric(
                      label: AppLocalizations.of(context).entryTypeExpense,
                      value: formatExpenseAmount(expense),
                      color: isZeroAmount(expense)
                          ? Theme.of(
                              context,
                            ).colorScheme.onSurface.withValues(alpha: 0.48)
                          : veriExpense,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              VeriCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SectionTitle(
                      title: AppLocalizations.of(context).balanceTrend,
                      trailing: AppLocalizations.of(context).thisMonth,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 156,
                      child: InteractiveTrendChart(
                        color: veriRoyal,
                        values: reportBalanceValues,
                        xLabels: monthAxisLabels(DateTime.now()),
                        yLabels: balanceAxisLabels(reportBalanceValues),
                        labelColor: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.50),
                        tooltipOf: (index) => ChartTooltip(
                          title: AppLocalizations.of(context).dateMonthDay(
                            DateTime(
                              DateTime.now().year,
                              DateTime.now().month,
                              index + 1,
                            ),
                          ),
                          lines: <ChartTooltipLine>[
                            ChartTooltipLine(
                              text: AppLocalizations.of(context).balanceAmount(
                                formatAmount(reportBalanceValues[index]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              VeriCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SectionTitle(
                      title: AppLocalizations.of(context).panelRecentLabel,
                      trailing: null,
                    ),
                    const SizedBox(height: 6),
                    if (entries.isEmpty)
                      EmptyState(
                        icon: Icons.receipt_long_outlined,
                        title: AppLocalizations.of(context).noEntriesTitle,
                        description: AppLocalizations.of(
                          context,
                        ).accountNoEntriesDesc,
                      )
                    else
                      ...entries
                          .take(6)
                          .map(
                            (entry) => TransactionTile(
                              entry,
                              accounts: controller.accounts,
                              categories: controller.categories,
                              onTap: () => openEntryDetail(context, entry),
                            ),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 信用卡还款提醒条：展示下一个还款日与剩余天数。
class _CreditCardDueBanner extends StatelessWidget {
  const _CreditCardDueBanner({required this.dueDay});

  final int dueDay;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final due = nextDueDate(dueDay, now);
    final days = daysUntilDue(dueDay, now);
    final urgent = days <= 3;
    final color = urgent ? veriExpense : veriRoyal;
    final l10n = AppLocalizations.of(context);
    final daysText = days == 0 ? l10n.dueToday : l10n.dueInDays(days);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(veriRadiusMd),
      ),
      child: Row(
        children: <Widget>[
          Icon(Icons.event_available_outlined, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${l10n.dueDay} ${l10n.dateMonthDay(due)} · $daysText',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.monthlyRepayLine(dueDay),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
