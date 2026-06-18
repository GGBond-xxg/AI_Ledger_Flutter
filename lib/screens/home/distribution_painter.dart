part of '../home_page.dart';

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
    canvas.drawArc(rect.deflate(strokeWidth / 2), -math.pi / 2, math.pi * 2, false, bgPaint);
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
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.items != items;
}

class _DistributionItem {
  _DistributionItem(this.label, this.value, this.color);
  final String label;
  final double value;
  final Color color;
}

List<_DistributionItem> _distributionItems(BuildContext context, LedgerStore store) {
  final cs = Theme.of(context).colorScheme;
  return [
    _DistributionItem('资金账户', _fundAccountsTotal(store), cs.primary),
    _DistributionItem('存款理财', _depositAssetsTotal(store), const Color(0xFF4EA66A)),
    _DistributionItem('基金股票', _investmentAssetsTotal(store), const Color(0xFFF2C14E)),
    _DistributionItem('借出款项', _receivableDebtsTotal(store), const Color(0xFF5B7CFA)),
    _DistributionItem('欠款负债', _payableDebtsTotal(store), const Color(0xFFE75D5D)),
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

BoxDecoration _surfaceDecoration(BuildContext context, {required double radius}) {
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
    final sameDay = bill.occurredAt.year == now.year && bill.occurredAt.month == now.month && bill.occurredAt.day == now.day;
    if (!sameDay || bill.currency.toUpperCase() != currency) return false;
    return income ? bill.isIncome : bill.isExpense;
  }).fold<double>(0, (sum, bill) => sum + bill.amount);
}

double _totalAsset(LedgerStore store) {
  // 必须和页面上展示的各分组保持同一套口径：
  // 总资产 = 资金账户 + 存款理财 + 基金股票 + 借出款项 - 欠款负债。
  // 不直接使用接口 totals.netWorth，避免某些本地资产/外币资产未返回估值时，
  // 顶部总资产与下方分组金额、圆环百分比不一致。
  return _fundAccountsTotal(store) +
      _depositAssetsTotal(store) +
      _investmentAssetsTotal(store) +
      _receivableDebtsTotal(store) -
      _payableDebtsTotal(store);
}

double _fundAccountsTotal(LedgerStore store) {
  return store
      .displayAssets(investment: false)
      .where((item) => item.type != 'manual')
      .fold<double>(0, (sum, item) => sum + _assetValue(store, item));
}

double _depositAssetsTotal(LedgerStore store) {
  return store
      .displayAssets(investment: false)
      .where((item) => item.type == 'manual')
      .fold<double>(0, (sum, item) => sum + _assetValue(store, item));
}

double _investmentAssetsTotal(LedgerStore store) {
  return store
      .displayAssets(investment: true)
      .fold<double>(0, (sum, item) => sum + _assetValue(store, item));
}

double _receivableDebtsTotal(LedgerStore store) {
  return store.displayDebts
      .where((item) => item.isReceivable)
      .fold<double>(0, (sum, item) => sum + _debtValue(store, item));
}

double _payableDebtsTotal(LedgerStore store) {
  return store.displayDebts
      .where((item) => item.isPayable)
      .fold<double>(0, (sum, item) => sum + _debtValue(store, item));
}

double _debtSortAmount(LedgerStore store, DebtItem debt) => _debtValue(store, debt).abs();

String _nameSortKey(String input) {
  final normalized = input.trim().toLowerCase();
  if (normalized.isEmpty) return '';
  final buffer = StringBuffer();
  for (final rune in normalized.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(_pinyinInitials[ch] ?? ch);
  }
  return buffer.toString();
}

const Map<String, String> _pinyinInitials = {
  '阿': 'a', '安': 'an', '奥': 'ao',
  '八': 'ba', '白': 'bai', '包': 'bao', '北': 'bei', '本': 'ben', '币': 'bi', '宾': 'bin', '波': 'bo',
  '财': 'cai', '餐': 'can', '仓': 'cang', '曹': 'cao', '陈': 'chen', '程': 'cheng', '持': 'chi', '出': 'chu', '储': 'chu', '存': 'cun',
  '大': 'da', '代': 'dai', '单': 'dan', '定': 'ding', '东': 'dong',
  '额': 'e',
  '发': 'fa', '方': 'fang', '飞': 'fei', '冯': 'feng', '付': 'fu',
  '港': 'gang', '高': 'gao', '个': 'ge', '工': 'gong', '股': 'gu', '广': 'guang', '国': 'guo',
  '海': 'hai', '行': 'hang', '好': 'hao', '花': 'hua', '华': 'hua', '黄': 'huang',
  '基': 'ji', '建': 'jian', '交': 'jiao', '金': 'jin', '京': 'jing',
  '款': 'kuan',
  '理': 'li', '李': 'li', '林': 'lin', '刘': 'liu', '龙': 'long',
  '美': 'mei', '民': 'min',
  '农': 'nong',
  '欧': 'ou',
  '平': 'ping', '浦': 'pu',
  '期': 'qi', '钱': 'qian', '欠': 'qian',
  '人': 'ren',
  '商': 'shang', '生': 'sheng', '收': 'shou', '数': 'shu',
  '腾': 'teng', '同': 'tong',
  '微': 'wei', '王': 'wang', '吴': 'wu',
  '小': 'xiao', '信': 'xin', '兴': 'xing',
  '亚': 'ya', '银': 'yin', '余': 'yu', '元': 'yuan',
  '招': 'zhao', '账': 'zhang', '张': 'zhang', '支': 'zhi', '中': 'zhong', '周': 'zhou', '资': 'zi',
};

double _assetValue(LedgerStore store, AssetItem item) {
  final valued = store.valuationAsset(item.id);
  final v = valued?['value'];
  if (v is num && v.isFinite) return v.toDouble();
  if (item.type == 'cash') return item.quantity;
  if (item.type == 'manual') return item.quantity * item.manualPrice;
  return 0;
}

double _debtValue(LedgerStore store, DebtItem debt) {
  final valued = store.valuationDebt(debt.id);
  final v = valued?['value'];
  if (v is num && v.isFinite) return v.abs().toDouble();
  return debt.amount.abs();
}

String _fmt(num value, String currency, {bool signed = false, bool compact = false}) {
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
  final intPart = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  final sign = value < 0 ? '-' : (signed && value > 0 ? '+' : '');
  return '$sign$symbol$intPart.${parts[1]}';
}

String _hm(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.hour)}:${two(date.minute)}';
}

String _billTitle(BillItem bill) {
  if (bill.isInvestmentBill) return bill.isInvestmentSell ? '卖出 ${bill.investmentAssetName.isEmpty ? bill.category : bill.investmentAssetName}' : '买入 ${bill.investmentAssetName.isEmpty ? bill.category : bill.investmentAssetName}';
  if (bill.isExchangeBill) return '换汇 / 转账';
  if (bill.isDebtBill) return bill.debtName.isEmpty ? _categoryName(bill.category) : bill.debtName;
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
    _ => bill.isIncome ? Icons.trending_up_rounded : Icons.trending_down_rounded,
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
