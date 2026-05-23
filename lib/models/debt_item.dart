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
    String imageBase64 = '',
    List<String>? imageBase64List,
    DateTime? createdAt,
  })  : imageBase64List = _normalizeImages(imageBase64List, imageBase64),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  String direction; // payable / receivable
  double amount;
  String currency;
  String note;
  List<String> imageBase64List; // 本地压缩后的图片 base64，最多 3 张，不上传服务器。
  DateTime createdAt;

  bool get isPayable => direction == 'payable';
  bool get isReceivable => direction == 'receivable';
  bool get hasImage => imageBase64List.isNotEmpty;

  /// 旧版本只有一张图片，保留这个 getter 方便旧 UI / 旧备份兼容。
  String get imageBase64 => imageBase64List.isEmpty ? '' : imageBase64List.first;

  static List<String> _normalizeImages(List<String>? list, String legacyImage) {
    final result = <String>[];
    if (list != null) {
      for (final item in list) {
        final value = item.trim();
        if (value.isNotEmpty) result.add(value);
        if (result.length >= 3) break;
      }
    }
    final legacy = legacyImage.trim();
    if (result.isEmpty && legacy.isNotEmpty) {
      result.add(legacy);
    }
    return result.take(3).toList(growable: true);
  }

  factory DebtItem.fromJson(Map<String, dynamic> json) {
    final rawList = json['imageBase64List'];
    return DebtItem(
      id: json['id'] as String? ?? newId(),
      name: json['name'] as String? ?? '未命名借款',
      direction: json['direction'] as String? ?? 'payable',
      amount: asDouble(json['amount']),
      currency: (json['currency'] as String?)?.toUpperCase() ?? 'CNY',
      note: json['note'] as String? ?? '',
      imageBase64: json['imageBase64'] as String? ?? '',
      imageBase64List: rawList is List ? rawList.whereType<String>().toList() : null,
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
        'imageBase64List': imageBase64List,
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
