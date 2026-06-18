part of '../home_page.dart';

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
      onTap: () => Get.to<void>(() => AssetFormPage(investmentDefault: asset.isInvestment, existing: asset)),
      child: Row(
        children: [
          _TonalIcon(icon: _assetIcon(asset), color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(asset.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(_fmt(value, store.settings.defaultCurrency), style: const TextStyle(fontWeight: FontWeight.w900)),
              if (asset.isInvestment)
                Text('市值', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
    final color = debt.isReceivable ? _toneColor(context, _Tone.positive) : _toneColor(context, _Tone.negative);
    final total = debt.originalAmount;
    final paid = debt.settledAmount;
    return _SurfaceInk(
      onTap: () => Get.to<void>(() => DebtDetailPage(debtId: debt.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(debt.name, style: const TextStyle(fontWeight: FontWeight.w900))),
              Text(_fmt(debt.amount, debt.currency), style: const TextStyle(fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '已还 ${_fmt(paid, debt.currency)}      剩余 ${_fmt(debt.amount, debt.currency)}',
                  style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ),
              _StatusChip(text: debt.isSettled ? '已结清' : (paid > 0 ? '部分已还' : '未还'), color: color),
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
  const _DebtTopCard({required this.title, required this.amount, required this.subtitle, required this.positive});

  final String title;
  final String amount;
  final String subtitle;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final color = _toneColor(context, positive ? _Tone.positive : _Tone.negative);
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
          Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          FittedBox(child: Text(amount, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: color))),
          const SizedBox(height: 6),
          Text(subtitle, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
        ],
      ),
    );
  }
}
