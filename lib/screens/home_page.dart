import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/app_theme.dart';
import '../core/formatters.dart';
import '../models/asset_item.dart';
import '../models/bill_item.dart';
import '../models/debt_item.dart';
import '../services/ledger_store.dart';
import '../widgets/safe_bottom_sheet.dart';
import 'asset_form_page.dart';
import 'bill_form_page.dart';
import 'debt_detail_page.dart';
import 'debt_form_page.dart';
import 'exchange_form_page.dart';
import 'investment_trade_form_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  Timer? _timer;
  final LedgerStore store = Get.find<LedgerStore>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => store.refreshValuation(source: 'homeInit'));
    _timer = Timer.periodic(
      const Duration(minutes: 15),
      (_) => store.refreshValuation(source: 'timer15m'),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final tab = store.selectedMainTab.value;
      // These reactive reads make the IndexedStack refresh as soon as local data changes,
      // so newly added assets/bills/debts appear without switching tabs.
      store.assets.length;
      store.debts.length;
      store.billsVersion.value;
      store.valuation;
      store.settings;
      store.selectedBillMonth.value;
      return GetBuilder<LedgerStore>(
        builder: (_) {
          return Scaffold(
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            floatingActionButton: tab == 4
                ? null
                : FloatingActionButton(
                    onPressed: _handleAdd,
                    child: const Icon(Icons.add_rounded),
                  ),
            bottomNavigationBar: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                child: NavigationBar(
                  selectedIndex: tab,
                  height: 68,
                  labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                  onDestinationSelected: store.setMainTab,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.home_outlined),
                      selectedIcon: Icon(Icons.home_rounded),
                      label: '首页',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.receipt_long_outlined),
                      selectedIcon: Icon(Icons.receipt_long_rounded),
                      label: '账单',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.pie_chart_outline_rounded),
                      selectedIcon: Icon(Icons.pie_chart_rounded),
                      label: '资产',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.account_balance_wallet_outlined),
                      selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                      label: '借贷',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings_rounded),
                      label: '设置',
                    ),
                  ],
                ),
              ),
            ),
            body: SafeArea(
              bottom: false,
              child: IndexedStack(
                index: tab,
                children: [
                  _DashboardPage(store: store),
                  _BillsMd3Page(store: store, onAdd: _openBillForm),
                  _AssetsMd3Page(store: store),
                  _DebtMd3Page(store: store),
                  const SettingsPage(),
                ],
              ),
            ),
          );
        },
      );
    });
  }

  void _handleAdd() {
    switch (store.selectedMainTab.value) {
      case 0:
      case 1:
        _openBillForm();
        break;
      case 2:
        _showAssetAddSheet();
        break;
      case 3:
        _openDebtForm();
        break;
    }
  }

  Future<void> _openBillForm({BillItem? existing}) async {
    await Get.to<void>(() => BillFormPage(existing: existing));
  }

  Future<void> _openAssetForm(bool investment, {AssetItem? existing}) async {
    await Get.to<void>(
        () => AssetFormPage(investmentDefault: investment, existing: existing));
  }

  Future<void> _openDebtForm({DebtItem? existing}) async {
    await Get.to<void>(() => DebtFormPage(
        existing: existing,
        initialDirection: existing?.direction ?? 'receivable'));
  }

  void _showAssetAddSheet() {
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
              _openAssetForm(false);
            },
          ),
          const SizedBox(height: 10),
          _ActionSheetTile(
            icon: Icons.account_balance_rounded,
            title: '添加存款理财',
            subtitle: '存款理财、大额存单、银行理财',
            onTap: () {
              Navigator.pop(context);
              Get.to<void>(() => const AssetFormPage(
                  investmentDefault: false, initialType: 'manual'));
            },
          ),
          const SizedBox(height: 10),
          _ActionSheetTile(
            icon: Icons.show_chart_rounded,
            title: '买入基金 / 股票',
            subtitle: '基金、A 股、美股、ETF',
            onTap: () {
              Navigator.pop(context);
              Get.to<void>(
                  () => const InvestmentTradeFormPage(defaultSell: false));
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
              Get.to<void>(
                  () => const DebtFormPage(initialDirection: 'receivable'));
            },
          ),
        ],
      ),
    );
  }
}

class _DashboardPage extends StatelessWidget {
  const _DashboardPage({required this.store});

  final LedgerStore store;

  @override
  Widget build(BuildContext context) {
    return _PageScaffold(
      title: '首页',
      actions: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TotalAssetHeroCard(store: store),
          const SizedBox(height: 12),
          _TodayMetricGrid(store: store),
          const SizedBox(height: 20),
          _SectionTitle(
            title: '资产分布',
            trailing: TextButton(
              onPressed: () => store.setMainTab(2),
              child: const Text('更多'),
            ),
          ),
          _AssetDistributionCard(store: store, compact: true),
          const SizedBox(height: 20),
          const _SectionTitle(title: '快捷入口'),
          _QuickActionGrid(store: store),
          const SizedBox(height: 20),
          const _SectionTitle(title: '最近账单'),
          _RecentBills(store: store),
          const SizedBox(height: 96),
        ],
      ),
    );
  }
}

class _BillsMd3Page extends StatefulWidget {
  const _BillsMd3Page({required this.store, required this.onAdd});

  final LedgerStore store;
  final void Function({BillItem? existing}) onAdd;

  @override
  State<_BillsMd3Page> createState() => _BillsMd3PageState();
}

class _BillsMd3PageState extends State<_BillsMd3Page> {
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    final bills = _filteredBills(widget.store.monthlyBills, _selectedFilter);
    return _PageScaffold(
      title: '账单',
      actions: const [],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterRow(
            labels: const ['全部', '收入', '支出', '转账', '存款理财', '投资', '借贷'],
            selectedIndex: _selectedFilter,
            onSelected: (index) => setState(() => _selectedFilter = index),
          ),
          const SizedBox(height: 12),
          _BillMonthHeader(store: widget.store),
          const SizedBox(height: 12),
          _BillSummaryStrip(store: widget.store),
          const SizedBox(height: 16),
          if (bills.isEmpty)
            _EmptyState(
              icon: Icons.receipt_long_outlined,
              title: '暂无账单',
              subtitle: _selectedFilter == 0 ? '点击右下角 + 记录第一笔账单' : '当前分类下暂无账单',
              actionText: '记一笔',
              onTap: () => widget.onAdd(),
            )
          else
            ..._groupBills(bills).entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(4, 16, 4, 8),
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  ...entry.value.map(
                    (bill) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _BillRow(
                        bill: bill,
                        onTap: () {
                          if (bill.isExchangeBill) {
                            Get.to<void>(
                                () => ExchangeFormPage(existing: bill));
                          } else if (bill.isInvestmentBill) {
                            Get.to<void>(
                                () => InvestmentTradeFormPage(existing: bill));
                          } else if (bill.isDebtBill &&
                              bill.debtId.trim().isNotEmpty) {
                            Get.to<void>(
                                () => DebtDetailPage(debtId: bill.debtId));
                          } else {
                            Get.to<void>(() => BillFormPage(existing: bill));
                          }
                        },
                      ),
                    ),
                  ),
                ],
              );
            }),
          const SizedBox(height: 96),
        ],
      ),
    );
  }

  List<BillItem> _filteredBills(List<BillItem> source, int filter) {
    if (filter == 0) return source;
    return source.where((bill) {
      return switch (filter) {
        1 => bill.isIncome,
        2 => bill.isExpense,
        3 => bill.isExchangeBill,
        4 => bill.category == 'depositIn' ||
            bill.category == 'depositOut' ||
            bill.category.contains('deposit'),
        5 => bill.isInvestmentBill,
        6 => bill.isDebtBill,
        _ => true,
      };
    }).toList(growable: false);
  }
}

class _AssetsMd3Page extends StatefulWidget {
  const _AssetsMd3Page({required this.store});

  final LedgerStore store;

  @override
  State<_AssetsMd3Page> createState() => _AssetsMd3PageState();
}

class _AssetsMd3PageState extends State<_AssetsMd3Page> {
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    final allFundAssets = widget.store.displayAssets(investment: false);
    final fundAccounts =
        allFundAssets.where((e) => e.type != 'manual').toList();
    final deposits = allFundAssets.where((e) => e.type == 'manual').toList();
    final investments = widget.store.displayAssets(investment: true);
    final debts = widget.store.displayDebts;

    return _PageScaffold(
      title: '资产',
      actions: [
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
            if (fundAccounts.isEmpty &&
                deposits.isEmpty &&
                investments.isEmpty &&
                debts.isEmpty)
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

  void _handleAdd(BuildContext context) {
    switch (_selectedFilter) {
      case 0:
        _showAssetAddSheet(context);
        break;
      case 1:
        Get.to<void>(() => const AssetFormPage(investmentDefault: false));
        break;
      case 2:
        Get.to<void>(() => const AssetFormPage(
            investmentDefault: false, initialType: 'manual'));
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
              Get.to<void>(() => const AssetFormPage(
                  investmentDefault: false, initialType: 'manual'));
            },
          ),
          const SizedBox(height: 10),
          _ActionSheetTile(
            icon: Icons.show_chart_rounded,
            title: '买入基金 / 股票',
            subtitle: '基金、A 股、美股、ETF',
            onTap: () {
              Navigator.pop(context);
              Get.to<void>(
                  () => const InvestmentTradeFormPage(defaultSell: false));
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
              Get.to<void>(
                  () => const DebtFormPage(initialDirection: 'receivable'));
            },
          ),
        ],
      ),
    );
  }

  List<Widget> _fundAccountSection(List<AssetItem> fundAccounts,
      {required bool showEmpty}) {
    return [
      _SectionTitle(
        title: '资金账户',
        trailing: Text(
          _fmt(widget.store.fundsTotal, widget.store.settings.defaultCurrency),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      if (fundAccounts.isEmpty && showEmpty)
        _EmptyState(
          icon: Icons.account_balance_wallet_outlined,
          title: '暂无资金账户',
          subtitle: '添加现金、银行卡、微信或支付宝账户',
          actionText: '添加账户',
          onTap: () =>
              Get.to<void>(() => const AssetFormPage(investmentDefault: false)),
        )
      else if (fundAccounts.isNotEmpty)
        ...fundAccounts.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AssetRow(asset: item, store: widget.store),
            )),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _depositSection(List<AssetItem> deposits,
      {required bool showEmpty}) {
    final total = deposits.fold<double>(
        0, (sum, e) => sum + _assetValue(widget.store, e));
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
          onTap: () => Get.to<void>(() => const AssetFormPage(
              investmentDefault: false, initialType: 'manual')),
        )
      else if (deposits.isNotEmpty)
        ...deposits.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AssetRow(asset: item, store: widget.store),
            )),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _investmentSection(List<AssetItem> investments,
      {required bool showEmpty}) {
    return [
      _SectionTitle(
        title: '基金股票',
        trailing: Text(
          _fmt(widget.store.investmentTotal,
              widget.store.settings.defaultCurrency),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      if (investments.isEmpty && showEmpty)
        _EmptyState(
          icon: Icons.show_chart_rounded,
          title: '暂无投资资产',
          subtitle: '添加基金、A 股、美股、ETF 或加密资产',
          actionText: '买入投资',
          onTap: () => Get.to<void>(
              () => const InvestmentTradeFormPage(defaultSell: false)),
        )
      else if (investments.isNotEmpty)
        ...investments.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _AssetRow(asset: item, store: widget.store),
            )),
      const SizedBox(height: 12),
    ];
  }

  List<Widget> _debtAssetSection(List<DebtItem> debts,
      {required bool showEmpty}) {
    return [
      _SectionTitle(
        title: '借贷',
        trailing: Text(
          _fmt(
              (widget.store.receivableTotal ?? 0) -
                  (widget.store.payableTotal ?? 0),
              widget.store.settings.defaultCurrency),
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      if (debts.isEmpty && showEmpty)
        _EmptyState(
          icon: Icons.handshake_outlined,
          title: '暂无借贷记录',
          subtitle: '记录借出款、欠款和还款',
          actionText: '新增借款',
          onTap: () => Get.to<void>(
              () => const DebtFormPage(initialDirection: 'receivable')),
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

class _DebtMd3Page extends StatefulWidget {
  const _DebtMd3Page({required this.store});

  final LedgerStore store;

  @override
  State<_DebtMd3Page> createState() => _DebtMd3PageState();
}

class _DebtMd3PageState extends State<_DebtMd3Page> {
  int _selectedFilter = 0;

  @override
  Widget build(BuildContext context) {
    final receivables =
        widget.store.displayDebts.where((e) => e.isReceivable).toList();
    final payables =
        widget.store.displayDebts.where((e) => e.isPayable).toList();
    final currency = widget.store.settings.defaultCurrency;
    final currentList = _selectedFilter == 0 ? receivables : payables;
    return _PageScaffold(
      title: '借贷',
      actions: [
        _IconCircleButton(
            icon: Icons.add_rounded,
            onTap: () => Get.to<void>(() => DebtFormPage(
                initialDirection:
                    _selectedFilter == 0 ? 'receivable' : 'payable'))),
      ],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _DebtTopCard(
                  title: '借出给他人',
                  amount: _fmt(widget.store.receivableTotal ?? 0, currency),
                  subtitle: '${receivables.length} 笔',
                  positive: true,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _DebtTopCard(
                  title: '欠他人款项',
                  amount: _fmt(widget.store.payableTotal ?? 0, currency),
                  subtitle: '${payables.length} 笔',
                  positive: false,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _FilterRow(
            labels: const ['借出', '借入（欠款）'],
            selectedIndex: _selectedFilter,
            onSelected: (index) => setState(() => _selectedFilter = index),
          ),
          const SizedBox(height: 18),
          _SectionTitle(title: _selectedFilter == 0 ? '借出列表' : '欠款记录'),
          if (currentList.isEmpty)
            _EmptyState(
              icon: _selectedFilter == 0
                  ? Icons.handshake_outlined
                  : Icons.account_balance_wallet_outlined,
              title: _selectedFilter == 0 ? '暂无借出记录' : '暂无欠款记录',
              subtitle: _selectedFilter == 0 ? '记录别人欠你的钱' : '记录你欠别人的钱',
              actionText: _selectedFilter == 0 ? '新增借出' : '新增欠款',
              onTap: () => Get.to<void>(() => DebtFormPage(
                  initialDirection:
                      _selectedFilter == 0 ? 'receivable' : 'payable')),
            )
          else
            ...currentList.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DebtRow(debt: item, store: widget.store),
                )),
          const SizedBox(height: 96),
        ],
      ),
    );
  }
}

class _PageScaffold extends StatelessWidget {
  const _PageScaffold(
      {required this.title, required this.child, this.actions = const []});

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: false,
          floating: false,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          title: Text(title,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3)),
          actions: [
            ...actions,
            const SizedBox(width: 12),
          ],
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: child,
          ),
        ),
      ],
    );
  }
}

class _TotalAssetHeroCard extends StatelessWidget {
  const _TotalAssetHeroCard({required this.store});

  final LedgerStore store;

  @override
  Widget build(BuildContext context) {
    final currency = store.settings.defaultCurrency;
    final total = _totalAsset(store);
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [cs.primary, Color.lerp(cs.primary, Colors.indigo, 0.35)!],
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('总资产（$currency）',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.86),
                      fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _fmt(total, currency),
            style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.7),
          ),
        ],
      ),
    );
  }
}

class _TodayMetricGrid extends StatelessWidget {
  const _TodayMetricGrid({required this.store});

  final LedgerStore store;

  @override
  Widget build(BuildContext context) {
    final currency = store.settings.defaultCurrency;
    final todayIncome = _todayBillTotal(store, income: true);
    final todayExpense = _todayBillTotal(store, income: false);
    return Row(
      children: [
        Expanded(
            child: _MetricCard(
                title: '今日收入',
                value: _fmt(todayIncome, currency, signed: true),
                tone: _Tone.positive)),
        const SizedBox(width: 10),
        Expanded(
            child: _MetricCard(
                title: '今日支出',
                value: _fmt(-todayExpense, currency, signed: true),
                tone: _Tone.negative)),
      ],
    );
  }
}

enum _Tone { positive, negative, primary, neutral }

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.title, required this.value, required this.tone});

  final String title;
  final String value;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(context, tone);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value,
                style: TextStyle(
                    color: color, fontSize: 20, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _MiniTotalCard extends StatelessWidget {
  const _MiniTotalCard({required this.store});
  final LedgerStore store;

  @override
  Widget build(BuildContext context) {
    final currency = store.settings.defaultCurrency;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .primaryContainer
            .withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
            color: Theme.of(context)
                .colorScheme
                .outlineVariant
                .withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('总资产（$currency）',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _fmt(_totalAsset(store), currency),
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.6),
          ),
        ],
      ),
    );
  }
}

class _AssetDistributionCard extends StatelessWidget {
  const _AssetDistributionCard({required this.store, required this.compact});

  final LedgerStore store;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final currency = store.settings.defaultCurrency;
    final items = _distributionItems(context, store);
    final total = items.fold<double>(0, (sum, e) => sum + e.value.abs());
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _surfaceDecoration(context, radius: 22),
      child: Row(
        children: [
          SizedBox(
            width: compact ? 112 : 132,
            height: compact ? 112 : 132,
            child: CustomPaint(
              painter: _DonutPainter(items: items),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('总资产',
                        style: TextStyle(
                            fontSize: 11,
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant)),
                    Text(_fmt(_totalAsset(store), currency, compact: true),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: items.map((e) {
                final percent = total <= 0 ? 0 : e.value.abs() / total * 100;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              color: e.color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text(e.label,
                              style: const TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.w700))),
                      Text('${percent.toStringAsFixed(1)}%',
                          style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionGrid extends StatelessWidget {
  const _QuickActionGrid({required this.store});

  final LedgerStore store;

  @override
  Widget build(BuildContext context) {
    final actions = [
      _QuickAction(
          icon: Icons.edit_rounded,
          label: '记一笔',
          onTap: () => Get.to<void>(() => const BillFormPage())),
      _QuickAction(
          icon: Icons.business_center_rounded,
          label: '存款理财',
          onTap: () => Get.to<void>(() => const AssetFormPage(
              investmentDefault: false, initialType: 'manual'))),
      _QuickAction(
          icon: Icons.bar_chart_rounded,
          label: '买入投资',
          onTap: () => Get.to<void>(
              () => const InvestmentTradeFormPage(defaultSell: false))),
      _QuickAction(
          icon: Icons.person_add_alt_1_rounded,
          label: '新增借款',
          onTap: () => Get.to<void>(
              () => const DebtFormPage(initialDirection: 'receivable'))),
    ];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: actions.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.86,
      ),
      itemBuilder: (context, index) => actions[index],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
        decoration: BoxDecoration(
          color: cs.primaryContainer.withValues(alpha: 0.38),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.48)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: cs.primary, size: 23),
            const SizedBox(height: 8),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _RecentBills extends StatelessWidget {
  const _RecentBills({required this.store});
  final LedgerStore store;

  @override
  Widget build(BuildContext context) {
    final bills = store.monthlyBills.take(4).toList();
    if (bills.isEmpty) {
      return _EmptyState(
        icon: Icons.receipt_long_outlined,
        title: '暂无最近账单',
        subtitle: '记录收入、支出、投资和借贷流水',
        actionText: '记一笔',
        onTap: () => Get.to<void>(() => const BillFormPage()),
      );
    }
    return Column(
      children: bills
          .map((bill) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BillRow(bill: bill),
              ))
          .toList(),
    );
  }
}

class _BillMonthHeader extends StatelessWidget {
  const _BillMonthHeader({required this.store});

  final LedgerStore store;

  @override
  Widget build(BuildContext context) {
    final month = store.selectedBillMonth.value;
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: month,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          store.setBillMonth(DateTime(picked.year, picked.month));
        }
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: _surfaceDecoration(context, radius: 18),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
                child: Text(monthText(month),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 16))),
            Icon(Icons.chevron_right_rounded,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _BillSummaryStrip extends StatelessWidget {
  const _BillSummaryStrip({required this.store});

  final LedgerStore store;

  @override
  Widget build(BuildContext context) {
    final currency = store.settings.defaultCurrency;
    return Row(
      children: [
        Expanded(
            child: _SummaryCell(
                label: '收入',
                value: _fmt(store.monthlyIncomeTotal, currency, signed: true),
                tone: _Tone.positive)),
        const SizedBox(width: 8),
        Expanded(
            child: _SummaryCell(
                label: '支出',
                value: _fmt(-store.monthlyExpenseTotal, currency, signed: true),
                tone: _Tone.negative)),
        const SizedBox(width: 8),
        Expanded(
            child: _SummaryCell(
                label: '结余',
                value: _fmt(store.monthlyBillNet, currency, signed: true),
                tone: _Tone.primary)),
      ],
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell(
      {required this.label, required this.value, required this.tone});

  final String label;
  final String value;
  final _Tone tone;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(context, tone);
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          FittedBox(
              child: Text(value,
                  style: TextStyle(fontWeight: FontWeight.w900, color: color))),
        ],
      ),
    );
  }
}

class _BillRow extends StatelessWidget {
  const _BillRow({required this.bill, this.onTap});

  final BillItem bill;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isIncome = bill.isIncome ||
        bill.isInvestmentSell ||
        bill.category == 'debtCollection';
    final isExpense = bill.isExpense ||
        bill.isInvestmentBuy ||
        bill.category == 'debtRepayment' ||
        bill.category == 'debtReceivable';
    final color = isIncome
        ? _toneColor(context, _Tone.positive)
        : isExpense
            ? _toneColor(context, _Tone.negative)
            : Theme.of(context).colorScheme.primary;
    final sign = isIncome ? 1.0 : (isExpense ? -1.0 : 0.0);
    final title = _billTitle(bill);
    final account = bill.assetName.trim().isNotEmpty
        ? bill.assetName
        : (bill.toAssetName.trim().isNotEmpty
            ? bill.toAssetName
            : bill.currency);
    return _SurfaceInk(
      onTap: onTap,
      child: Row(
        children: [
          _TonalIcon(icon: _billIcon(bill), color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text('$account · ${_hm(bill.occurredAt)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            sign == 0
                ? _fmt(bill.amount, bill.currency)
                : _fmt(bill.amount * sign, bill.currency, signed: true),
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _AssetRow extends StatelessWidget {
  const _AssetRow({required this.asset, required this.store});

  final AssetItem asset;
  final LedgerStore store;

  @override
  Widget build(BuildContext context) {
    final value = _assetValue(store, asset);
    final subtitle = asset.isInvestment
        ? '${asset.symbol.isEmpty ? asset.type : asset.symbol} · ${trimNum(asset.quantity)} ${asset.unit.isEmpty ? '' : asset.unit}'
        : '${_assetTypeName(asset)} · ${asset.currency}';
    return _SurfaceInk(
      onTap: () => Get.to<void>(() => AssetFormPage(
          investmentDefault: asset.isInvestment, existing: asset)),
      child: Row(
        children: [
          _TonalIcon(
              icon: _assetIcon(asset),
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(asset.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_fmt(value, store.settings.defaultCurrency),
                  style: const TextStyle(fontWeight: FontWeight.w900)),
              if (asset.isInvestment)
                Text('市值',
                    style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DebtRow extends StatelessWidget {
  const _DebtRow({required this.debt, required this.store});

  final DebtItem debt;
  final LedgerStore store;

  @override
  Widget build(BuildContext context) {
    final color = debt.isReceivable
        ? _toneColor(context, _Tone.positive)
        : _toneColor(context, _Tone.negative);
    final total = debt.originalAmount;
    final paid = debt.settledAmount;
    return _SurfaceInk(
      onTap: () => Get.to<void>(() => DebtDetailPage(debtId: debt.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(debt.name,
                      style: const TextStyle(fontWeight: FontWeight.w900))),
              Text(_fmt(debt.amount, debt.currency),
                  style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '已还 ${_fmt(paid, debt.currency)}      剩余 ${_fmt(debt.amount, debt.currency)}',
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
              _StatusChip(
                  text: debt.isSettled ? '已结清' : (paid > 0 ? '部分已还' : '未还'),
                  color: color),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: total <= 0 ? 1 : (paid / total).clamp(0, 1),
              minHeight: 5,
              backgroundColor: color.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}

class _DebtTopCard extends StatelessWidget {
  const _DebtTopCard(
      {required this.title,
      required this.amount,
      required this.subtitle,
      required this.positive});

  final String title;
  final String amount;
  final String subtitle;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color =
        _toneColor(context, positive ? _Tone.positive : _Tone.negative);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          FittedBox(
              child: Text(amount,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: color))),
          const SizedBox(height: 6),
          Text(subtitle,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow(
      {required this.labels,
      required this.selectedIndex,
      required this.onSelected});

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: labels.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final selected = index == selectedIndex;
          return FilterChip(
            selected: selected,
            showCheckmark: false,
            label: Text(labels[index]),
            onSelected: (_) => onSelected(index),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
              child: Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900))),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _SurfaceInk extends StatelessWidget {
  const _SurfaceInk({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(13),
          decoration: _surfaceDecoration(context, radius: 18),
          child: child,
        ),
      ),
    );
  }
}

class _TonalIcon extends StatelessWidget {
  const _TonalIcon({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}

class _IconCircleButton extends StatelessWidget {
  const _IconCircleButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon),
        style: IconButton.styleFrom(
          backgroundColor: AppTheme.sheetBackground(context),
        ),
      ),
    );
  }
}

class _ActionSheetTile extends StatelessWidget {
  const _ActionSheetTile(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return _SurfaceInk(
      onTap: onTap,
      child: Row(
        children: [
          _TonalIcon(icon: icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState(
      {required this.icon,
      required this.title,
      required this.subtitle,
      this.actionText,
      this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: _surfaceDecoration(context, radius: 22),
      child: Column(
        children: [
          Icon(icon,
              size: 44, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(title,
              style:
                  const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
          const SizedBox(height: 4),
          Text(subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          if (actionText != null && onTap != null) ...[
            const SizedBox(height: 14),
            FilledButton.tonal(onPressed: onTap, child: Text(actionText!)),
          ],
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99)),
      child: Text(text,
          style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w900)),
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({required this.items});

  final List<_DistributionItem> items;

  @override
  void paint(Canvas canvas, Size size) {
    final total = items.fold<double>(0, (sum, e) => sum + e.value.abs());
    final rect = Offset.zero & size;
    final strokeWidth = size.width * 0.16;
    final bgPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = const Color(0xFFE8ECF7);
    canvas.drawArc(rect.deflate(strokeWidth / 2), -math.pi / 2, math.pi * 2,
        false, bgPaint);
    if (total <= 0) return;
    var start = -math.pi / 2;
    for (final item in items) {
      final sweep = item.value.abs() / total * math.pi * 2;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = item.color;
      canvas.drawArc(rect.deflate(strokeWidth / 2), start, sweep, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) =>
      oldDelegate.items != items;
}

class _DistributionItem {
  _DistributionItem(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

List<_DistributionItem> _distributionItems(
    BuildContext context, LedgerStore store) {
  final cs = Theme.of(context).colorScheme;
  return [
    _DistributionItem('资金账户', store.fundsTotal, cs.primary),
    _DistributionItem(
        '存款理财',
        store
            .displayAssets(investment: false)
            .where((e) => e.type == 'manual')
            .fold<double>(0, (s, e) => s + _assetValue(store, e)),
        const Color(0xFF4EA66A)),
    _DistributionItem('基金股票', store.investmentTotal, const Color(0xFFF2C14E)),
    _DistributionItem(
        '借出款项', store.receivableTotal ?? 0, const Color(0xFF5B7CFA)),
    _DistributionItem('欠款负债', store.payableTotal ?? 0, const Color(0xFFE75D5D)),
  ];
}

Map<String, List<BillItem>> _groupBills(List<BillItem> bills) {
  final map = <String, List<BillItem>>{};
  for (final bill in bills) {
    final key = dateText(bill.occurredAt);
    map.putIfAbsent(key, () => []).add(bill);
  }
  return map;
}

BoxDecoration _surfaceDecoration(BuildContext context,
    {required double radius}) {
  final cs = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: cs.surfaceContainerLow,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55)),
  );
}

Color _toneColor(BuildContext context, _Tone tone) {
  final cs = Theme.of(context).colorScheme;
  return switch (tone) {
    _Tone.positive => const Color(0xFF248B5D),
    _Tone.negative => const Color(0xFFD64545),
    _Tone.primary => cs.primary,
    _Tone.neutral => cs.onSurfaceVariant,
  };
}

double _todayBillTotal(LedgerStore store, {required bool income}) {
  final now = DateTime.now();
  final currency = store.settings.defaultCurrency.toUpperCase();
  return store.monthlyBills.where((bill) {
    final sameDay = bill.occurredAt.year == now.year &&
        bill.occurredAt.month == now.month &&
        bill.occurredAt.day == now.day;
    if (!sameDay || bill.currency.toUpperCase() != currency) return false;
    return income ? bill.isIncome : bill.isExpense;
  }).fold<double>(0, (sum, bill) => sum + bill.amount);
}

double _totalAsset(LedgerStore store) {
  return store.netWorth ??
      ((store.assetTotal ?? (store.fundsTotal + store.investmentTotal)) +
          (store.receivableTotal ?? 0) -
          (store.payableTotal ?? 0));
}

double _assetValue(LedgerStore store, AssetItem item) {
  final valued = store.valuationAsset(item.id);
  final v = valued?['value'];
  if (v is num && v.isFinite) return v.toDouble();
  if (item.type == 'cash') return item.quantity;
  if (item.type == 'manual') return item.quantity * item.manualPrice;
  return 0;
}

String _fmt(num value, String currency,
    {bool signed = false, bool compact = false}) {
  final absValue = value.abs();
  final symbol = switch (currency.toUpperCase()) {
    'CNY' => '¥',
    'USD' => r'$',
    'HKD' => 'HK\$',
    'SGD' => 'S\$',
    'EUR' => '€',
    'JPY' => '¥',
    _ => '$currency ',
  };
  if (compact && absValue >= 1000000) {
    final sign = value < 0 ? '-' : (signed && value > 0 ? '+' : '');
    return '$sign$symbol${(absValue / 10000).toStringAsFixed(1)}万';
  }
  final fixed = absValue.toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0]
      .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  final sign = value < 0 ? '-' : (signed && value > 0 ? '+' : '');
  return '$sign$symbol$intPart.${parts[1]}';
}

String _hm(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.hour)}:${two(date.minute)}';
}

String _billTitle(BillItem bill) {
  if (bill.isInvestmentBill) {
    return bill.isInvestmentSell
        ? '卖出 ${bill.investmentAssetName.isEmpty ? bill.category : bill.investmentAssetName}'
        : '买入 ${bill.investmentAssetName.isEmpty ? bill.category : bill.investmentAssetName}';
  }
  if (bill.isExchangeBill) return '换汇 / 转账';
  if (bill.isDebtBill) {
    return bill.debtName.isEmpty ? _categoryName(bill.category) : bill.debtName;
  }
  return _categoryName(bill.category);
}

String _categoryName(String category) {
  const map = {
    'salary': '工资收入',
    'food': '餐饮支出',
    'transport': '交通出行',
    'shopping': '购物消费',
    'housing': '住房',
    'medical': '医疗',
    'otherIncome': '其他收入',
    'otherExpense': '其他支出',
    'investmentBuy': '投资买入',
    'investmentSell': '投资卖出',
    'exchange': '换汇',
    'debtPayable': '欠款到账',
    'debtReceivable': '借出款项',
    'debtRepayment': '还款',
    'debtCollection': '收回借款',
    'debtBorrowAdd': '增加欠款',
    'debtLendAdd': '追加借出',
  };
  return map[category] ?? category;
}

IconData _billIcon(BillItem bill) {
  if (bill.isIncome) return Icons.savings_rounded;
  if (bill.isInvestmentBill) return Icons.show_chart_rounded;
  if (bill.isExchangeBill) return Icons.swap_horiz_rounded;
  if (bill.isDebtBill) return Icons.handshake_rounded;
  return switch (bill.category) {
    'food' => Icons.restaurant_rounded,
    'transport' => Icons.directions_subway_rounded,
    'shopping' => Icons.shopping_cart_rounded,
    _ =>
      bill.isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
  };
}

IconData _assetIcon(AssetItem asset) {
  if (asset.isInvestment) return Icons.show_chart_rounded;
  return switch (asset.type) {
    'cash' => Icons.account_balance_wallet_rounded,
    'manual' => Icons.account_balance_rounded,
    _ => Icons.account_balance_wallet_rounded,
  };
}

String _assetTypeName(AssetItem asset) {
  return switch (asset.type) {
    'cash' => '资金账户',
    'manual' => '存款理财',
    'stock' => '美股',
    'etf' => 'ETF',
    'cn_stock' => 'A股',
    'cn_etf' => 'A股 ETF',
    'crypto' => '加密资产',
    'metal' => '贵金属',
    _ => asset.type,
  };
}
