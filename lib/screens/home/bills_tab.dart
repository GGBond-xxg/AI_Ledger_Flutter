part of '../home_page.dart';

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
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
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
                              Get.to<void>(() => ExchangeFormPage(existing: bill));
                            } else if (bill.isInvestmentBill) {
                              Get.to<void>(() => InvestmentTradeFormPage(existing: bill));
                            } else if (bill.isDebtBill && bill.debtId.trim().isNotEmpty) {
                              Get.to<void>(() => DebtDetailPage(debtId: bill.debtId));
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
        4 => bill.category == 'depositIn' || bill.category == 'depositOut' || bill.category.contains('deposit'),
        5 => bill.isInvestmentBill,
        6 => bill.isDebtBill,
        _ => true,
      };
    }).toList(growable: false);
  }
}
