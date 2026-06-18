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

part 'home/dashboard_tab.dart';
part 'home/bills_tab.dart';
part 'home/assets_tab.dart';
part 'home/debt_tab.dart';
part 'home/dashboard_widgets.dart';
part 'home/bill_widgets.dart';
part 'home/asset_debt_widgets.dart';
part 'home/common_widgets.dart';
part 'home/distribution_painter.dart';

enum _SortMode { nameAsc, nameDesc, amountDesc, amountAsc }

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
            floatingActionButton: FloatingActionButton(
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
    await Get.to<void>(() => AssetFormPage(investmentDefault: investment, existing: existing));
  }

  Future<void> _openDebtForm({DebtItem? existing}) async {
    await Get.to<void>(() => DebtFormPage(existing: existing, initialDirection: existing?.direction ?? 'receivable'));
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
}
