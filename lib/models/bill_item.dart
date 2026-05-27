import '../core/id.dart';
import '../core/number_utils.dart';

class BillItem {
  BillItem({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    this.currency = 'CNY',
    this.assetId = '',
    this.assetName = '',
    this.investmentAssetId = '',
    this.investmentAssetName = '',
    this.investmentQuantity = 0,
    this.toAssetId = '',
    this.toAssetName = '',
    this.toAmount = 0,
    this.toCurrency = '',
    this.note = '',
    DateTime? occurredAt,
    DateTime? createdAt,
  })  : occurredAt = occurredAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String type; // expense / income / investment / exchange
  String category;
  double amount;
  String currency;
  /// Optional linked fund asset id. Expenses deduct from this asset and income adds to it.
  /// Investment buy/sell bills also use this as the fund account.
  String assetId;
  /// Snapshot of linked asset name, used for display even if the asset is later renamed/deleted.
  String assetName;
  /// Optional linked investment asset id. Investment buy adds quantity, sell reduces quantity.
  String investmentAssetId;
  /// Snapshot of linked investment name.
  String investmentAssetName;
  /// Quantity of linked investment to add/subtract.
  double investmentQuantity;
  /// Exchange target fund account id.
  String toAssetId;
  /// Snapshot of exchange target fund account name.
  String toAssetName;
  /// Exchange target amount.
  double toAmount;
  /// Exchange target currency.
  String toCurrency;
  String note;
  DateTime occurredAt;
  DateTime createdAt;

  bool get isIncome => type == 'income';
  bool get isExpense => type == 'expense';
  bool get isInvestmentBill => type == 'investment';
  bool get isExchangeBill => type == 'exchange';
  bool get isInvestmentBuy => isInvestmentBill && category != 'investmentSell';
  bool get isInvestmentSell => isInvestmentBill && category == 'investmentSell';
  bool get hasLinkedAsset => assetId.trim().isNotEmpty;
  bool get hasLinkedInvestment => investmentAssetId.trim().isNotEmpty && investmentQuantity > 0;

  factory BillItem.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String? ?? 'expense';
    final normalizedType = rawType == 'investment'
        ? 'investment'
        : (rawType == 'exchange' ? 'exchange' : (rawType == 'income' ? 'income' : 'expense'));
    var category = json['category'] as String? ?? (normalizedType == 'income' ? 'otherIncome' : 'otherExpense');
    if (normalizedType == 'investment' && category != 'investmentSell') {
      category = 'investmentBuy';
    } else if (normalizedType == 'exchange') {
      category = 'exchange';
    }
    return BillItem(
      id: json['id'] as String? ?? newId(),
      type: normalizedType,
      category: category,
      amount: asDouble(json['amount']),
      currency: (json['currency'] as String?)?.toUpperCase() ?? 'CNY',
      assetId: json['assetId'] as String? ?? '',
      assetName: json['assetName'] as String? ?? '',
      investmentAssetId: json['investmentAssetId'] as String? ?? '',
      investmentAssetName: json['investmentAssetName'] as String? ?? '',
      investmentQuantity: asDouble(json['investmentQuantity']),
      toAssetId: json['toAssetId'] as String? ?? '',
      toAssetName: json['toAssetName'] as String? ?? '',
      toAmount: asDouble(json['toAmount']),
      toCurrency: (json['toCurrency'] as String?)?.toUpperCase() ?? '',
      note: json['note'] as String? ?? '',
      occurredAt: DateTime.tryParse(json['occurredAt'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'category': category,
        'amount': amount,
        'currency': currency,
        'assetId': assetId,
        'assetName': assetName,
        'investmentAssetId': investmentAssetId,
        'investmentAssetName': investmentAssetName,
        'investmentQuantity': investmentQuantity,
        'toAssetId': toAssetId,
        'toAssetName': toAssetName,
        'toAmount': toAmount,
        'toCurrency': toCurrency,
        'note': note,
        'occurredAt': occurredAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}
