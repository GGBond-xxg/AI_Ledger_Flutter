import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/app_theme.dart';
import '../core/formatters.dart';
import '../l10n/translation_service.dart';
import '../models/asset_item.dart';
import '../models/bill_item.dart';
import '../models/debt_item.dart';
import '../services/ledger_store.dart';
import '../widgets/common_cards.dart';
import '../widgets/summary_card.dart';
import '../widgets/tile_widgets.dart';
import 'asset_form_page.dart';
import 'bill_form_page.dart';
import 'debt_detail_page.dart';
import 'debt_form_page.dart';
import 'exchange_form_page.dart';
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
    _timer = Timer.periodic(const Duration(minutes: 15),
        (_) => store.refreshValuation(source: 'timer15m'));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final navBackground = AppTheme.cardColor(context);

    return Obx(() {
      final lastError = store.lastError;
      final failedAssets = store.failedAssets;

      return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            if (store.selectedMainTab.value == 0) {
              _openBillForm();
              return;
            }
            final assetTab = store.selectedAssetTab.value;
            if (assetTab == 0) {
              _openFundActions();
            } else if (assetTab == 1) {
              _openAssetForm(true);
            } else {
              _openDebtForm();
            }
          },
          child: const Icon(Icons.add_rounded, size: 30),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: NavigationBar(
                selectedIndex: store.selectedMainTab.value,
                height: 66,
                elevation: 0,
                backgroundColor: navBackground,
                indicatorColor: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.13),
                onDestinationSelected: store.setMainTab,
                destinations: [
                  NavigationDestination(
                      icon: const Icon(Icons.receipt_long_outlined),
                      selectedIcon: const Icon(Icons.receipt_long_rounded),
                      label: 'bills'.tr),
                  NavigationDestination(
                      icon: const Icon(Icons.account_balance_wallet_outlined),
                      selectedIcon:
                          const Icon(Icons.account_balance_wallet_rounded),
                      label: 'assets'.tr),
                ],
              ),
            ),
          ),
        ),
        body: SafeArea(
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Header(store: store),
                      const SizedBox(height: 18),
                      if (store.selectedMainTab.value == 0)
                        _BillsPage(store: store, onAdd: _openBillForm)
                      else ...[
                        SummaryCard(store: store),
                        const SizedBox(height: 14),
                        if (lastError != null) ...[
                          ErrorBanner(message: lastError),
                          const SizedBox(height: 14),
                        ],
                        if (failedAssets.isNotEmpty) ...[
                          ErrorBanner(
                              message: trPartialQuoteFailed(failedAssets
                                  .map((e) =>
                                      e['name'] ?? e['symbol'] ?? e['id'])
                                  .join('listSeparator'.tr))),
                          const SizedBox(height: 14),
                        ],
                        _AssetsPage(store: store),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Future<void> _openBillForm({BillItem? existing}) async {
    await Get.to<void>(() => BillFormPage(existing: existing));
  }

  Future<void> _openAssetForm(bool investment, {AssetItem? existing}) async {
    await Get.to<void>(
        () => AssetFormPage(investmentDefault: investment, existing: existing));
  }

  void _openFundActions() {
    Get.bottomSheet<void>(
      SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
          decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 5,
                decoration: BoxDecoration(
                  color: AppTheme.textSubtle(context).withValues(alpha: 0.28),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 14),
              _FundActionTile(
                icon: Icons.account_balance_wallet_rounded,
                title: 'addAsset'.tr,
                subtitle: 'addCashSubtitle'.tr,
                onTap: () {
                  Get.back<void>();
                  _openAssetForm(false);
                },
              ),
              const SizedBox(height: 10),
              _FundActionTile(
                icon: Icons.swap_horiz_rounded,
                title: 'exchangeBill'.tr,
                subtitle: 'exchangeActionSubtitle'.tr,
                onTap: () {
                  Get.back<void>();
                  Get.to<void>(() => const ExchangeFormPage());
                },
              ),
            ],
          ),
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> _openDebtForm({DebtItem? existing}) async {
    await Get.to<void>(() => DebtFormPage(existing: existing));
  }
}

class _FundActionTile extends StatelessWidget {
  const _FundActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.inputColor(context),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: Theme.of(context).colorScheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(color: AppTheme.textSubtle(context), fontSize: 13)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: AppTheme.textSubtle(context)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.store});

  final LedgerStore store;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('appTitle'.tr,
                  style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8)),
              const SizedBox(height: 4),
              Text(
                  '${'localLedger'.tr} · ${trEstimateIn(store.settings.defaultCurrency)}',
                  style: TextStyle(color: AppTheme.textSubtle(context))),
            ],
          ),
        ),
        Obx(
          () => _CircleButton(
            icon: Icons.sync_rounded,
            onTap: () =>
                store.refreshValuation(force: true, source: 'headerButton'),
            loading: store.showRefreshSpinner,
          ),
        ),
        const SizedBox(width: 8),
        _CircleButton(
          icon: Icons.settings_rounded,
          onTap: () => Get.to<void>(() => const SettingsPage()),
        ),
      ],
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton(
      {required this.icon, required this.onTap, this.loading = false});

  final IconData icon;
  final VoidCallback onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(18)),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child: loading
              ? const Padding(
                  key: ValueKey('refresh-loading'),
                  padding: EdgeInsets.all(13),
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Icon(icon, key: ValueKey(icon)),
        ),
      ),
    );
  }
}

class _BillsPage extends StatelessWidget {
  const _BillsPage({required this.store, required this.onAdd});

  final LedgerStore store;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // 明确监听账单列表和月份版本，避免保存账单/切换月份后需要手动刷新页面。
      store.billsVersion.value;
      store.selectedBillMonth.value;
      final bills = store.monthlyBills;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MonthSelector(store: store),
          const SizedBox(height: 12),
          _BillSummaryCard(store: store),
          const SizedBox(height: 18),
          SectionHeader(title: 'bills'.tr, description: 'billsDesc'.tr),
          if (bills.isEmpty)
            EmptyCard(
              title: 'emptyBillsTitle'.tr,
              subtitle: 'emptyBillsSubtitle'.tr,
              icon: Icons.receipt_long_rounded,
              tips: 'emptyBillsTips'.trList,
              actionText: 'addBill'.tr,
              onTap: onAdd,
            )
          else
            ...bills.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: BillTile(
                    item: item,
                    onDelete: () => store.removeBill(item.id),
                    onEdit: () => item.isExchangeBill
                        ? Get.to<void>(() => ExchangeFormPage(existing: item))
                        : Get.to<void>(() => BillFormPage(existing: item)),
                  ),
                )),
        ],
      );
    });
  }
}

class _MonthSelector extends StatelessWidget {
  const _MonthSelector({required this.store});

  final LedgerStore store;

  @override
  Widget build(BuildContext context) {
    final month = store.selectedBillMonth.value;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: month,
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
          helpText: 'selectMonth'.tr,
        );
        if (picked != null) {
          store.setBillMonth(DateTime(picked.year, picked.month));
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
            color: AppTheme.cardColor(context),
            borderRadius: BorderRadius.circular(18)),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(
                child: Text(monthText(month),
                    style: const TextStyle(
                        fontWeight: FontWeight.w900, fontSize: 18))),
            Text('tapToSwitchMonth'.tr,
                style: TextStyle(
                    color: AppTheme.textSubtle(context), fontSize: 12)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded,
                color: AppTheme.textSubtle(context)),
          ],
        ),
      ),
    );
  }
}

class _BillSummaryCard extends StatelessWidget {
  const _BillSummaryCard({required this.store});

  final LedgerStore store;

  @override
  Widget build(BuildContext context) {
    final currency = store.settings.defaultCurrency;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child: _BillTotal(
                        label: 'expense'.tr,
                        value: store.monthlyExpenseTotal,
                        currency: currency,
                        color: const Color(0xFFD64545))),
                const SizedBox(width: 14),
                Expanded(
                    child: _BillTotal(
                        label: 'income'.tr,
                        value: store.monthlyIncomeTotal,
                        currency: currency,
                        color: const Color(0xFF248B5D))),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              height: 1,
              color: AppTheme.textSubtle(context).withValues(alpha: 0.10),
            ),
            const SizedBox(height: 12),
            _BillTotal(
              label: 'monthNet'.tr,
              value: store.monthlyBillNet,
              currency: currency,
              large: true,
              color: store.monthlyBillNet < 0
                  ? const Color(0xFFD64545)
                  : const Color(0xFF248B5D),
            ),
          ],
        ),
      ),
    );
  }
}

class _BillTotal extends StatelessWidget {
  const _BillTotal(
      {required this.label,
      required this.value,
      required this.currency,
      this.color,
      this.large = false});

  final String label;
  final double value;
  final String currency;
  final Color? color;
  final bool large;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style:
                  TextStyle(color: AppTheme.textSubtle(context), fontSize: 12)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(money(value, currency),
                style: TextStyle(
                    fontSize: large ? 20 : 16,
                    fontWeight: FontWeight.w900,
                    color: color ?? AppTheme.textMain(context))),
          ),
        ],
      ),
    );
  }
}

class _AssetsPage extends StatelessWidget {
  const _AssetsPage({required this.store});

  final LedgerStore store;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final selected = store.selectedAssetTab.value;
      final normalAssets = store.displayAssets(investment: false);
      final investments = store.displayAssets(investment: true);
      final debts = store.displayDebts;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _AssetSegmentedTabs(store: store),
          const SizedBox(height: 12),
          _AssetCategoryTotalCard(store: store, selected: selected),
          const SizedBox(height: 16),
          if (selected == 0)
            _AssetSection(
              store: store,
              title: 'funds'.tr,
              description: 'fundsDesc'.tr,
              assets: normalAssets,
              investment: false,
              emptyText: 'emptyAssetsTitle'.tr,
              emptySubtitle: 'emptyAssetsSubtitle'.tr,
              emptyIcon: Icons.account_balance_wallet_rounded,
              emptyTips: 'emptyAssetsTips'.trList,
              emptyAction: () => Get.to<void>(
                  () => const AssetFormPage(investmentDefault: false)),
            )
          else if (selected == 1)
            _AssetSection(
              store: store,
              title: 'investment'.tr,
              description: 'investmentsDesc'.tr,
              assets: investments,
              investment: true,
              emptyText: 'emptyInvestmentsTitle'.tr,
              emptySubtitle: 'emptyInvestmentsSubtitle'.tr,
              emptyIcon: Icons.show_chart_rounded,
              emptyTips: const ['AAPL', 'QQQ', 'SOL', 'XAU'],
              emptyAction: () => Get.to<void>(
                  () => const AssetFormPage(investmentDefault: true)),
            )
          else
            _DebtSection(
                store: store,
                debts: debts,
                emptyAction: () => Get.to<void>(() => const DebtFormPage())),
        ],
      );
    });
  }
}

class _AssetSegmentedTabs extends StatelessWidget {
  const _AssetSegmentedTabs({required this.store});

  final LedgerStore store;

  @override
  Widget build(BuildContext context) {
    final labels = ['funds'.tr, 'investment'.tr, 'debt'.tr];
    return Container(
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: List.generate(labels.length, (index) {
          final selected = store.selectedAssetTab.value == index;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () => store.setAssetTab(index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: selected
                      ? Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.12)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  labels[index],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : AppTheme.textSubtle(context),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}


class _AssetCategoryTotalCard extends StatelessWidget {
  const _AssetCategoryTotalCard({required this.store, required this.selected});

  final LedgerStore store;
  final int selected;

  @override
  Widget build(BuildContext context) {
    final currency = store.settings.defaultCurrency;

    if (selected == 2) {
      final receivable = store.receivableTotal ?? 0;
      final payable = store.payableTotal ?? 0;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _DebtTotalBox(
                      label: 'receivable'.tr,
                      value: money(receivable, currency),
                      color: const Color(0xFF248B5D),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DebtTotalBox(
                      label: 'payable'.tr,
                      value: money(payable, currency),
                      color: const Color(0xFFD64545),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _DebtTotalBox(
                label: 'debtNet'.tr,
                value: money(receivable - payable, currency),
                wide: true,
              ),
            ],
          ),
        ),
      );
    }

    final isInvestment = selected == 1;
    final title = isInvestment ? 'investmentTotal'.tr : 'fundsTotal'.tr;
    final value = isInvestment ? store.investmentTotal : store.fundsTotal;
    final icon = isInvestment ? Icons.show_chart_rounded : Icons.account_balance_wallet_rounded;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppTheme.textSubtle(context),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  money(value, currency),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DebtTotalBox extends StatelessWidget {
  const _DebtTotalBox({
    required this.label,
    required this.value,
    this.color,
    this.wide = false,
  });

  final String label;
  final String value;
  final Color? color;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final content = wide
        ? Row(
            children: [
              Text(
                label,
                style: TextStyle(
                  color: AppTheme.textSubtle(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: color ?? AppTheme.textMain(context),
                    ),
                  ),
                ),
              ),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppTheme.textSubtle(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: color ?? AppTheme.textMain(context),
                  ),
                ),
              ),
            ],
          );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.055),
        borderRadius: BorderRadius.circular(18),
      ),
      child: content,
    );
  }
}

class _AssetSection extends StatelessWidget {
  const _AssetSection({
    required this.store,
    required this.title,
    required this.description,
    required this.assets,
    required this.investment,
    required this.emptyText,
    required this.emptySubtitle,
    required this.emptyIcon,
    required this.emptyTips,
    required this.emptyAction,
  });

  final LedgerStore store;
  final String title;
  final String description;
  final List<AssetItem> assets;
  final bool investment;
  final String emptyText;
  final String emptySubtitle;
  final IconData emptyIcon;
  final List<String> emptyTips;
  final VoidCallback emptyAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, description: description),
        if (assets.isEmpty)
          EmptyCard(
              title: emptyText,
              subtitle: emptySubtitle,
              icon: emptyIcon,
              tips: emptyTips,
              onTap: emptyAction)
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            proxyDecorator: _reorderProxyDecorator,
            itemCount: assets.length,
            onReorder: (oldIndex, newIndex) => store.reorderAssets(
                investment: investment, oldIndex: oldIndex, newIndex: newIndex),
            itemBuilder: (context, index) {
              final item = assets[index];
              return ReorderableDelayedDragStartListener(
                key: ValueKey(item.id),
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: AssetTile(
                    item: item,
                    defaultCurrency: store.settings.defaultCurrency,
                    valuation: store.valuationAsset(item.id),
                    onDelete: () => store.removeAsset(item.id),
                    onEdit: () => Get.to<void>(() => AssetFormPage(
                        investmentDefault: item.isInvestment, existing: item)),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

Widget _reorderProxyDecorator(
    Widget child, int index, Animation<double> animation) {
  return AnimatedBuilder(
    animation: animation,
    builder: (context, _) {
      final t = Curves.easeOutCubic.transform(animation.value);
      return Transform.scale(
        scale: 1 + t * 0.015,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black
                    .withValues(alpha: AppTheme.isDark(context) ? 0.28 : 0.10),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            clipBehavior: Clip.antiAlias,
            child: child,
          ),
        ),
      );
    },
  );
}

class _DebtSection extends StatelessWidget {
  const _DebtSection(
      {required this.store, required this.debts, required this.emptyAction});

  final LedgerStore store;
  final List<DebtItem> debts;
  final VoidCallback emptyAction;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: 'debt'.tr, description: 'debtsDesc'.tr),
        if (debts.isEmpty)
          EmptyCard(
            title: 'emptyDebtsTitle'.tr,
            subtitle: 'emptyDebtsSubtitle'.tr,
            icon: Icons.receipt_long_rounded,
            tips: 'emptyDebtsTips'.trList,
            actionText: 'addDebt'.tr,
            onTap: emptyAction,
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            proxyDecorator: _reorderProxyDecorator,
            itemCount: debts.length,
            onReorder: store.reorderDebts,
            itemBuilder: (context, index) {
              final item = debts[index];
              return ReorderableDelayedDragStartListener(
                key: ValueKey(item.id),
                index: index,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: DebtTile(
                    item: item,
                    defaultCurrency: store.settings.defaultCurrency,
                    valuation: store.valuationDebt(item.id),
                    onDelete: () => store.removeDebt(item.id),
                    onEdit: () =>
                        Get.to<void>(() => DebtDetailPage(debtId: item.id)),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}
