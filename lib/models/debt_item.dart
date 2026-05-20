import '../core/id.dart';
import '../core/number_utils.dart';

class DebtItem {
  DebtItem({
    required this.id,
    required this.name,
    required this.direction,
    required this.amount,
    this.currency = 'CNY',
    this.note = '',
    this.imageBase64 = '',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  String direction; // payable / receivable
  double amount;
  String currency;
  String note;
  String imageBase64; // 本地压缩后的图片 base64，不上传服务器。
  DateTime createdAt;

  bool get isPayable => direction == 'payable';
  bool get isReceivable => direction == 'receivable';
  bool get hasImage => imageBase64.trim().isNotEmpty;

  factory DebtItem.fromJson(Map<String, dynamic> json) {
    return DebtItem(
      id: json['id'] as String? ?? newId(),
      name: json['name'] as String? ?? '未命名借款',
      direction: json['direction'] as String? ?? 'payable',
      amount: asDouble(json['amount']),
      currency: (json['currency'] as String?)?.toUpperCase() ?? 'CNY',
      note: json['note'] as String? ?? '',
      imageBase64: json['imageBase64'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'direction': direction,
        'amount': amount,
        'currency': currency,
        'note': note,
        'imageBase64': imageBase64,
        'createdAt': createdAt.toIso8601String(),
      };

  Map<String, dynamic> toApiJson() => {
        'id': id,
        'name': name,
        'direction': direction,
        'amount': amount,
        'currency': currency,
      };
}
