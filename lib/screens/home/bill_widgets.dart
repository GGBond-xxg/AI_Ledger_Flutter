part of '../home_page.dart';

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
        if (picked != null) store.setBillMonth(DateTime(picked.year, picked.month));
      },
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: _surfaceDecoration(context, radius: 18),
        child: Row(
          children: [
            Icon(Icons.calendar_month_rounded, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(monthText(month), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16))),
            Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
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
        Expanded(child: _SummaryCell(label: '收入', value: _fmt(store.monthlyIncomeTotal, currency, signed: true), tone: _Tone.positive)),
        const SizedBox(width: 8),
        Expanded(child: _SummaryCell(label: '支出', value: _fmt(-store.monthlyExpenseTotal, currency, signed: true), tone: _Tone.negative)),
        const SizedBox(width: 8),
        Expanded(child: _SummaryCell(label: '结余', value: _fmt(store.monthlyBillNet, currency, signed: true), tone: _Tone.primary)),
      ],
    );
  }
}

class _SummaryCell extends StatelessWidget {
  const _SummaryCell({required this.label, required this.value, required this.tone});

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
          Text(label, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
          const SizedBox(height: 4),
          FittedBox(child: Text(value, style: TextStyle(fontWeight: FontWeight.w900, color: color))),
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
    final isIncome = bill.isIncome || bill.isInvestmentSell || bill.category == 'debtCollection';
    final isExpense = bill.isExpense || bill.isInvestmentBuy || bill.category == 'debtRepayment' || bill.category == 'debtReceivable';
    final color = isIncome
        ? _toneColor(context, _Tone.positive)
        : isExpense
            ? _toneColor(context, _Tone.negative)
            : Theme.of(context).colorScheme.primary;
    final sign = isIncome ? 1.0 : (isExpense ? -1.0 : 0.0);
    final title = _billTitle(bill);
    final account = bill.assetName.trim().isNotEmpty ? bill.assetName : (bill.toAssetName.trim().isNotEmpty ? bill.toAssetName : bill.currency);
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
                Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text('$account · ${_hm(bill.occurredAt)}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            sign == 0 ? _fmt(bill.amount, bill.currency) : _fmt(bill.amount * sign, bill.currency, signed: true),
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
