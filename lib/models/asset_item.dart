import '../core/id.dart';
import '../core/number_utils.dart';

class AssetItem {
  AssetItem({
    required this.id,
    required this.name,
    required this.type,
    required this.quantity,
    this.symbol = '',
    this.currency = 'CNY',
    this.unit = '',
    this.manualPrice = 0,
    this.note = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  String type; // cash / manual / crypto / metal / stock / etf / cn_stock / cn_etf
  String symbol;
  double quantity;
  String currency;
  String unit;
  double manualPrice;
  String note;
  DateTime createdAt;

  bool get isInvestment => ['crypto', 'metal', 'stock', 'etf', 'cn_stock', 'cn_etf'].contains(type);
  bool get isNormalAsset => !isInvestment;

  factory AssetItem.fromJson(Map<String, dynamic> json) {
    return AssetItem(
      id: json['id'] as String? ?? newId(),
      name: json['name'] as String? ?? '未命名资产',
      type: json['type'] as String? ?? 'cash',
      symbol: json['symbol'] as String? ?? '',
      quantity: asDouble(json['quantity']),
      currency: (json['currency'] as String?)?.toUpperCase() ?? 'CNY',
      unit: json['unit'] as String? ?? '',
      manualPrice: asDouble(json['manualPrice']),
      note: json['note'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'symbol': symbol,
        'quantity': quantity,
        'currency': currency,
        'unit': unit,
        'manualPrice': manualPrice,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toApiJson() {
    final apiType = type == 'etf' ? 'stock' : type;
    final map = <String, dynamic>{
      'id': id,
      'name': name,
      'type': apiType,
      'quantity': quantity,
    };

    if (type == 'cash') {
      map['currency'] = currency;
    } else if (type == 'manual') {
      map['currency'] = currency;
      map['manualPrice'] = manualPrice;
    } else if (type == 'crypto') {
      map['symbol'] = symbol.trim();
    } else if (type == 'metal') {
      map['symbol'] = symbol.trim().isEmpty ? 'XAU' : symbol.trim().toUpperCase();
      map['unit'] = unit.trim().isEmpty ? 'gram' : unit.trim();
    } else if (type == 'stock' || type == 'etf' || type == 'cn_stock' || type == 'cn_etf') {
      map['symbol'] = symbol.trim().toUpperCase();
    }

    return map;
  }
}
