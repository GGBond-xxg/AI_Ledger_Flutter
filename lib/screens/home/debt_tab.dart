part of '../home_page.dart';

class _DebtMd3Page extends StatefulWidget {
  const _DebtMd3Page({required this.store});

  final LedgerStore store;

  @override
  State<_DebtMd3Page> createState() => _DebtMd3PageState();
}

class _DebtMd3PageState extends State<_DebtMd3Page> {
  int _selectedFilter = 0;
  _SortMode _sortMode = _SortMode.nameAsc;

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

  @override
  Widget build(BuildContext context) {
    final receivables = _sortDebts(widget.store.displayDebts.where((e) => e.isReceivable).toList());
      final payables = _sortDebts(widget.store.displayDebts.where((e) => e.isPayable).toList());
      final currency = widget.store.settings.defaultCurrency;
      final currentList = _selectedFilter == 0 ? receivables : payables;
      return _PageScaffold(
        title: '借贷',
        actions: [
          _SortIconButton(
            mode: _sortMode,
            onTap: () => setState(() => _sortMode = _nextSortMode(_sortMode)),
            onSelected: (mode) => setState(() => _sortMode = mode),
          ),
          _IconCircleButton(icon: Icons.add_rounded, onTap: () => Get.to<void>(() => DebtFormPage(initialDirection: _selectedFilter == 0 ? 'receivable' : 'payable'))),
        ],
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: _DebtTopCard(
                    title: '借出给他人',
                    amount: _fmt(_receivableDebtsTotal(widget.store), currency),
                    subtitle: '${receivables.length} 笔',
                    positive: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _DebtTopCard(
                    title: '欠他人款项',
                    amount: _fmt(_payableDebtsTotal(widget.store), currency),
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
                icon: _selectedFilter == 0 ? Icons.handshake_outlined : Icons.account_balance_wallet_outlined,
                title: _selectedFilter == 0 ? '暂无借出记录' : '暂无欠款记录',
                subtitle: _selectedFilter == 0 ? '记录别人欠你的钱' : '记录你欠别人的钱',
                actionText: _selectedFilter == 0 ? '新增借出' : '新增欠款',
                onTap: () => Get.to<void>(() => DebtFormPage(initialDirection: _selectedFilter == 0 ? 'receivable' : 'payable')),
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
