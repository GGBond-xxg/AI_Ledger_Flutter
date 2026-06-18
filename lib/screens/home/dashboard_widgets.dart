part of '../home_page.dart';

class _PageScaffold extends StatelessWidget {
  const _PageScaffold({required this.title, required this.child, this.actions = const []});

  final String title;
  final Widget child;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final store = Get.find<LedgerStore>();
    return RefreshIndicator(
      onRefresh: () => store.refreshValuation(force: true, source: 'pullToRefresh'),
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
        slivers: [
          SliverAppBar(
            pinned: false,
            floating: false,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.3)),
            actions: [
              ...actions,
              _IconCircleButton(
                icon: Icons.settings_rounded,
                onTap: () => Get.to<void>(() => const SettingsPage()),
              ),
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
      ),
    );
  }
}

class _TotalAssetHeroCard extends StatelessWidget {
  const _TotalAssetHeroCard({required this.store});

  final LedgerStore store;

  @override
  Widget build(BuildContext context) => _MiniTotalCard(store: store);
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
        Expanded(child: _MetricCard(title: '今日收入', value: _fmt(todayIncome, currency, signed: true), tone: _Tone.positive)),
        const SizedBox(width: 10),
        Expanded(child: _MetricCard(title: '今日支出', value: _fmt(-todayExpense, currency, signed: true), tone: _Tone.negative)),
      ],
    );
  }
}

enum _Tone { positive, negative, primary, neutral }

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.title, required this.value, required this.tone});

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
          Text(title, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(color: color, fontSize: 20, fontWeight: FontWeight.w900)),
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
        color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.55)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('总资产（$currency）', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w800)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _fmt(_totalAsset(store), currency),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.6),
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
                    Text('总资产', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    Text(_fmt(_totalAsset(store), currency, compact: true), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
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
                      Container(width: 8, height: 8, decoration: BoxDecoration(color: e.color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700))),
                      Text('${percent.toStringAsFixed(1)}%', style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
      _QuickAction(icon: Icons.edit_rounded, label: '记一笔', onTap: () => Get.to<void>(() => const BillFormPage())),
      _QuickAction(icon: Icons.business_center_rounded, label: '存款理财', onTap: () => Get.to<void>(() => const AssetFormPage(investmentDefault: false, initialType: 'manual'))),
      _QuickAction(icon: Icons.bar_chart_rounded, label: '买入投资', onTap: () => Get.to<void>(() => const InvestmentTradeFormPage(defaultSell: false))),
      _QuickAction(icon: Icons.person_add_alt_1_rounded, label: '新增借款', onTap: () => Get.to<void>(() => const DebtFormPage(initialDirection: 'receivable'))),
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
  const _QuickAction({required this.icon, required this.label, required this.onTap});

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
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
