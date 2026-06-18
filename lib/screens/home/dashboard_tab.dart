part of '../home_page.dart';

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
