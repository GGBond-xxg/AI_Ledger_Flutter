import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/app_theme.dart';
import '../l10n/translation_service.dart';
import '../models/asset_item.dart';
import '../models/debt_item.dart';
import '../services/ledger_store.dart';
import '../widgets/add_action_sheet.dart';
import '../widgets/common_cards.dart';
import '../widgets/summary_card.dart';
import '../widgets/tile_widgets.dart';
import 'asset_form_page.dart';
import 'debt_form_page.dart';
import 'settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final RxInt _tab = 0.obs;
  Timer? _timer;
  final LedgerStore store = Get.find<LedgerStore>();

  @override
  void initState() {
    super.initState();
    Future.microtask(() => store.refreshValuation(source: 'homeInit'));
    _timer = Timer.periodic(const Duration(minutes: 15), (_) => store.refreshValuation(source: 'timer15m'));
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
      final normalAssets = store.assets.where((e) => e.isNormalAsset).toList();
      final investments = store.assets.where((e) => e.isInvestment).toList();
      final lastError = store.lastError;
      final failedAssets = store.failedAssets;

      return Scaffold(
        floatingActionButton: FloatingActionButton(
          onPressed: _showAddSheet,
          child: const Icon(Icons.add_rounded, size: 30),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: NavigationBar(
                selectedIndex: _tab.value,
                height: 66,
                elevation: 0,
                backgroundColor: navBackground,
                indicatorColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.13),
                onDestinationSelected: (index) => _tab.value = index,
                destinations: [
                  NavigationDestination(icon: const Icon(Icons.account_balance_wallet_outlined), selectedIcon: const Icon(Icons.account_balance_wallet_rounded), label: 'assets'.tr),
                  NavigationDestination(icon: const Icon(Icons.trending_up_outlined), selectedIcon: const Icon(Icons.trending_up_rounded), label: 'investment'.tr),
                  NavigationDestination(icon: const Icon(Icons.receipt_long_outlined), selectedIcon: const Icon(Icons.receipt_long_rounded), label: 'debt'.tr),
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
                      SummaryCard(store: store),
                      const SizedBox(height: 14),
                      if (lastError != null) ...[
                        ErrorBanner(message: lastError),
                        const SizedBox(height: 14),
                      ],
                      if (failedAssets.isNotEmpty) ...[
                        ErrorBanner(message: trPartialQuoteFailed(failedAssets.map((e) => e['name'] ?? e['symbol'] ?? e['id']).join('listSeparator'.tr))),
                        const SizedBox(height: 14),
                      ],
                      switch (_tab.value) {
                        0 => _AssetSection(
                            store: store,
                            title: 'assets'.tr,
                            description: 'assetsDesc'.tr,
                            assets: normalAssets,
                            emptyText: 'emptyAssetsTitle'.tr,
                            emptySubtitle: 'emptyAssetsSubtitle'.tr,
                            emptyIcon: Icons.account_balance_wallet_rounded,
                            emptyTips: 'emptyAssetsTips'.trList,
                            emptyAction: () => _openAssetForm(false),
                          ),
                        1 => _AssetSection(
                            store: store,
                            title: 'investment'.tr,
                            description: 'investmentsDesc'.tr,
                            assets: investments,
                            emptyText: 'emptyInvestmentsTitle'.tr,
                            emptySubtitle: 'emptyInvestmentsSubtitle'.tr,
                            emptyIcon: Icons.show_chart_rounded,
                            emptyTips: const ['AAPL', 'QQQ', 'SOL', 'XAU'],
                            emptyAction: () => _openAssetForm(true),
                          ),
                        _ => _DebtSection(
                            store: store,
                            debts: store.debts.toList(),
                            emptyAction: () => _openDebtForm(),
                          ),
                      },
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

  void _showAddSheet() {
    Get.bottomSheet(
      AddActionSheet(
        onAddAsset: () {
          Get.back<void>();
          _openAssetForm(false);
        },
        onAddInvestment: () {
          Get.back<void>();
          _openAssetForm(true);
        },
        onAddDebt: () {
          Get.back<void>();
          _openDebtForm();
        },
        onRefresh: () {
          Get.back<void>();
          store.refreshValuation(force: true, source: 'addSheetRefresh');
        },
      ),
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
    );
  }

  Future<void> _openAssetForm(bool investment, {AssetItem? existing}) async {
    await Get.to<void>(() => AssetFormPage(investmentDefault: investment, existing: existing));
  }

  Future<void> _openDebtForm({DebtItem? existing}) async {
    await Get.to<void>(() => DebtFormPage(existing: existing));
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
              Text('appTitle'.tr, style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w800, letterSpacing: -0.8)),
              const SizedBox(height: 4),
              Text('${'localLedger'.tr} · ${trEstimateIn(store.settings.defaultCurrency)}', style: TextStyle(color: AppTheme.textSubtle(context))),
            ],
          ),
        ),
        Obx(
          () => _CircleButton(
            icon: Icons.sync_rounded,
            onTap: () => store.refreshValuation(force: true, source: 'headerButton'),
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
  const _CircleButton({required this.icon, required this.onTap, this.loading = false});

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
        decoration: BoxDecoration(color: AppTheme.cardColor(context), borderRadius: BorderRadius.circular(18)),
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

class _AssetSection extends StatelessWidget {
  const _AssetSection({
    required this.store,
    required this.title,
    required this.description,
    required this.assets,
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
          EmptyCard(title: emptyText, subtitle: emptySubtitle, icon: emptyIcon, tips: emptyTips, onTap: emptyAction)
        else
          ...assets.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: AssetTile(
                  item: item,
                  defaultCurrency: store.settings.defaultCurrency,
                  valuation: store.valuationAsset(item.id),
                  onDelete: () => store.removeAsset(item.id),
                  onEdit: () => Get.to<void>(() => AssetFormPage(investmentDefault: item.isInvestment, existing: item)),
                ),
              )),
      ],
    );
  }
}

class _DebtSection extends StatelessWidget {
  const _DebtSection({required this.store, required this.debts, required this.emptyAction});

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
          ...debts.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: DebtTile(
                  item: item,
                  defaultCurrency: store.settings.defaultCurrency,
                  valuation: store.valuationDebt(item.id),
                  onDelete: () => store.removeDebt(item.id),
                  onEdit: () => Get.to<void>(() => DebtFormPage(existing: item)),
                ),
              )),
      ],
    );
  }
}
