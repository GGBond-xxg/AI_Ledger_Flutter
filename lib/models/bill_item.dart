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
    this.note = '',
    DateTime? occurredAt,
    DateTime? createdAt,
  })  : occurredAt = occurredAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String type; // expense / income
  String category;
  double amount;
  String currency;
  /// Optional linked fund asset id. When set, expenses deduct from this asset and income adds to it.
  String assetId;
  /// Snapshot of linked asset name, used for display even if the asset is later renamed/deleted.
  String assetName;
  /// Optional linked investment asset id. Expenses add quantity (buy), income subtracts quantity (sell).
  String investmentAssetId;
  /// Snapshot of linked investment name.
  String investmentAssetName;
  /// Quantity of linked investment to add/subtract.
  double investmentQuantity;
  String note;
  DateTime occurredAt;
  DateTime createdAt;

  bool get isIncome => type == 'income';
  bool get isExpense => type != 'income';
  bool get hasLinkedAsset => assetId.trim().isNotEmpty;
  bool get hasLinkedInvestment => investmentAssetId.trim().isNotEmpty && investmentQuantity > 0;

  factory BillItem.fromJson(Map<String, dynamic> json) {
    return BillItem(
      id: json['id'] as String? ?? newId(),
      type: json['type'] as String? ?? 'expense',
      category: json['category'] as String? ?? 'otherExpense',
      amount: asDouble(json['amount']),
      currency: (json['currency'] as String?)?.toUpperCase() ?? 'CNY',
      assetId: json['assetId'] as String? ?? '',
      assetName: json['assetName'] as String? ?? '',
      investmentAssetId: json['investmentAssetId'] as String? ?? '',
      investmentAssetName: json['investmentAssetName'] as String? ?? '',
      investmentQuantity: asDouble(json['investmentQuantity']),
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
        'note': note,
        'occurredAt': occurredAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}
