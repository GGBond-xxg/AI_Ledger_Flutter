part of '../home_page.dart';

class _AssetsMd3Page extends StatefulWidget {
  const _AssetsMd3Page({required this.store});

  final LedgerStore store;

  @override
  State<_AssetsMd3Page> createState() => _AssetsMd3PageState();
}

class _AssetsMd3PageState extends State<_AssetsMd3Page> {
  int _selectedFilter = 0;
  _SortMode _sortMode = _SortMode.nameAsc;


  @override
  Widget build(BuildContext context) {
    final allFundAssets = widget.store.displayAssets(investment: false);
    final fundAccounts = _sortAssets(allFundAssets.where((e) => e.type != 'manual').toList());
    final deposits = _sortAssets(allFundAssets.where((e) => e.type == 'manual').toList());
    final investments = _sortAssets(widget.store.displayAssets(investment: true));
    final debts = _sortDebts(widget.store.displayDebts);

    return _PageScaffold(
      title: '资产',
      actions: [
        _SortIconButton(
          mode: _sortMode,
          onTap: () => setState(() => _sortMode = _nextSortMode(_sortMode)),
          onSelected: (mode) => setState(() => _sortMode = mode),
        ),
        _IconCircleButton(
          icon: Icons.add_rounded,
          onTap: () => _handleAdd(context),
        ),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MiniTotalCard(store: widget.store),
          const SizedBox(height: 12),
          _FilterRow(
            labels: const ['全部', '资金账户', '存款理财', '投资', '借贷'],
            selectedIndex: _selectedFilter,
            onSelected: (index) => setState(() => _selectedFilter = index),
          ),
          const SizedBox(height: 16),
          _AssetDistributionCard(store: widget.store, compact: false),
          const SizedBox(height: 18),
          if (_selectedFilter == 0) ...[
            ..._fundAccountSection(fundAccounts, showEmpty: false),
            ..._depositSection(deposits, showEmpty: false),
            ..._investmentSection(investments, showEmpty: false),
            ..._debtAssetSection(debts, showEmpty: false),
            if (fundAccounts.isEmpty && deposits.isEmpty && investments.isEmpty && debts.isEmpty)
              _EmptyState(
                icon: Icons.account_balance_wallet_outlined,
                title: '暂无资产',
                subtitle: '添加资金账户、存款理财、投资或借贷记录',
                actionText: '新增资产',
                onTap: () => _showAssetAddSheet(context),
              ),
          ] else if (_selectedFilter == 1) ...[
            ..._fundAccountSection(fundAccounts, showEmpty: true),
          ] else if (_selectedFilter == 2) ...[
            ..._depositSection(deposits, showEmpty: true),
          ] else if (_selectedFilter == 3) ...[
            ..._investmentSection(investments, showEmpty: true),
          ] else ...[
            ..._debtAssetSection(debts, showEmpty: true),
          ],
          const SizedBox(height: 96),
        ],
      ),
    );
  }

  List<AssetItem> _sortAssets(List<AssetItem> source) {
    final list = source.toList(growable: true);
    list.sort((a, b) {
      final result = switch (_sortMode) {
        _SortMode.nameAsc => _nameSortKey(a.name).compareTo(_nameSortKey(b.name)),
        _SortMode.nameDesc => _nameSortKey(b.name).compareTo(_nameSortKey(a.name)),
        _SortMode.amountDesc => _assetValue(widget.store, b).compareTo(_assetValue(widget.store, a)),
        _SortMode.amountAsc => _assetValue(widget.store, a).compareTo(_assetValue(widget.store, b)),
      };
      return result == 0 ? a.name.compareTo(b.name) : result;
    });
    return list;
  }

  List<DebtItem> _sortDebts(List<DebtItem> source) {
    final list = source.toList(growable: true);
    list.sort((a, b) {
      final result = switch (_sortMode) {
        _SortMode.nameAsc => _nameSortKey(a.name).compareTo(_nameSortKey(b.name)),
        _SortMode.nameDesc => _nameSortKey(b.name).compareTo(_nameSortKey(a.name)),
        _SortMode.amountDesc => _debtSortAmount(widget.store, b).compareTo(_debtSortAmount(widget.store, a)),
        _SortMode.amountAsc => _debtSortAmount(widget.store, a).compareTo(_debtSortAmount(widget.store, b)),
      };
      return result == 0 ? a.name.compareTo(b.name) : result;
    });
    return list;
  }

  void _handleAdd(BuildContext context) {
    switch (_selectedFilter) {
      case 0:
        _showAssetAddSheet(context);
        break;
      case 1:
        Get.to<void>(() => const AssetFormPage(investmentDefault: false));
        break;
      case 2:
        Get.to<void>(() => const AssetFormPage(investmentDefault: false, initialType: 'manual'));
        break;
      case 3:
        Get.to<void>(() => const InvestmentTradeFormPage(defaultSell: false));
        break;
      case 4:
        Get.to<void>(() => const DebtFormPage(initialDirection: 'receivable'));
        break;
    }
  }

  void _showAssetAddSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.sheetBackground(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeBottomSheet(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
        children: [
            _ActionSheetTile(
              icon: Icons.account_balance_wallet_rounded,
              title: '添加资金账户',
              subtitle: '现金、银行卡、微信、支付宝',
              onTap: () {
                Navigator.pop(context);
                Get.to<void>(() => const AssetFormPage(investmentDefault: false));
              },
            ),
            const SizedBox(height: 10),
            _ActionSheetTile(
              icon: Icons.account_balance_rounded,
              title: '添加存款理财',
              subtitle: '存款理财、大额存单、银行理财',
              onTap: () {
                Navigator.pop(context);
                Get.to<void>(() => const AssetFormPage(investmentDefault: false, initialType: 'manual'));
              },
            ),
            const SizedBox(height: 10),
            _ActionSheetTile(
              icon: Icons.show_chart_rounded,
              title: '买入基金 / 股票',
              subtitle: '基金、A 股、美股、ETF',
              onTap: () {
                Navigator.pop(context);
                Get.to<void>(() => const InvestmentTradeFormPage(defaultSell: false));
              },
            ),
            const SizedBox(height: 10),
            _ActionSheetTile(
              icon: Icons.swap_horiz_rounded,
              title: '换汇 / 转账',
              subtitle: '资金账户之间流转',
              onTap: () {
                Navigator.pop(context);
                Get.to<void>(() => const ExchangeFormPage());
              },
            ),
            const SizedBox(height: 10),
            _ActionSheetTile(
              icon: Icons.handshake_rounded,
              title: '新增借贷',
              subtitle: '借出款、欠款和还款',
              onTap: () {
                Navigator.pop(context);
                Get.to<void>(() => const DebtFormPage(initialDirection: 'receivable'));
              },
            ),
        ],
      ),
    );
  }

  List<Widget> _fundAccountSection(List<AssetItem> fundAccounts, {required bool showEmpty}) {
    return [
      _SectionTitle(
        title: '资金账户',
        trailing: Text(
          _fmt(_fundAccountsTotal(widget.store), widget.store.settings.defaultCurrency),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      if (fundAccounts.isEmpty && showEmpty)
        _EmptyState(
          icon: Icons.account_balance_wallet_outlined,
          title: '暂无资金账户',
          subtitle: '添加现金、银行卡、微信或支付宝账户',
          actionText: '添加账户',
          onTap: () => Get.to<void>(() => const AssetFormPage(investmentDefault: false)),
        )
      else if (fundAccounts.isNotEmpty)
        ...fundAccounts.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AssetRow(asset: item, store: widget.store),
            )),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _depositSection(List<AssetItem> deposits, {required bool showEmpty}) {
    final total = deposits.fold<double>(0, (sum, e) => sum + _assetValue(widget.store, e));
    return [
      _SectionTitle(
        title: '存款理财',
        trailing: Text(
          _fmt(total, widget.store.settings.defaultCurrency),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      if (deposits.isEmpty && showEmpty)
        _EmptyState(
          icon: Icons.account_balance_outlined,
          title: '暂无存款理财',
          subtitle: '添加存款理财、大额存单或银行理财',
          actionText: '添加存款理财',
          onTap: () => Get.to<void>(() => const AssetFormPage(investmentDefault: false, initialType: 'manual')),
        )
      else if (deposits.isNotEmpty)
        ...deposits.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AssetRow(asset: item, store: widget.store),
            )),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _investmentSection(List<AssetItem> investments, {required bool showEmpty}) {
    return [
      _SectionTitle(
        title: '基金股票',
        trailing: Text(
          _fmt(_investmentAssetsTotal(widget.store), widget.store.settings.defaultCurrency),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      if (investments.isEmpty && showEmpty)
        _EmptyState(
          icon: Icons.show_chart_rounded,
          title: '暂无投资资产',
          subtitle: '添加基金、A 股、美股、ETF 或加密资产',
          actionText: '买入投资',
          onTap: () => Get.to<void>(() => const InvestmentTradeFormPage(defaultSell: false)),
        )
      else if (investments.isNotEmpty)
        ...investments.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AssetRow(asset: item, store: widget.store),
            )),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _debtAssetSection(List<DebtItem> debts, {required bool showEmpty}) {
    return [
      _SectionTitle(
        title: '借贷',
        trailing: Text(
          _fmt(_receivableDebtsTotal(widget.store) - _payableDebtsTotal(widget.store), widget.store.settings.defaultCurrency),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      if (debts.isEmpty && showEmpty)
        _EmptyState(
          icon: Icons.handshake_outlined,
          title: '暂无借贷记录',
          subtitle: '记录借出款、欠款和还款',
          actionText: '新增借款',
          onTap: () => Get.to<void>(() => const DebtFormPage(initialDirection: 'receivable')),
        )
      else if (debts.isNotEmpty)
        ...debts.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _DebtRow(debt: item, store: widget.store),
            )),
      const SizedBox(height: 12),
    ];
  }
}
