import '../core/id.dart';
import '../core/number_utils.dart';

class DebtTransaction {
  DebtTransaction({
    required this.id,
    required this.type,
    required this.amount,
    this.currency = 'CNY',
    this.assetId = '',
    this.assetName = '',
    this.note = '',
    DateTime? occurredAt,
    DateTime? createdAt,
  })  : occurredAt = occurredAt ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String type; // repayment / collection / borrow / lend
  double amount;
  String currency;
  String assetId;
  String assetName;
  String note;
  DateTime occurredAt;
  DateTime createdAt;

  bool get isRepayment => type == 'repayment';
  bool get isCollection => type == 'collection';
  bool get isBorrow => type == 'borrow';
  bool get isLend => type == 'lend';
  bool get isIncrease => isBorrow || isLend;

  factory DebtTransaction.fromJson(Map<String, dynamic> json) {
    final rawType = json['type'] as String? ?? 'repayment';
    final normalizedType = rawType == 'collection'
        ? 'collection'
        : (rawType == 'borrow' ? 'borrow' : (rawType == 'lend' ? 'lend' : 'repayment'));
    return DebtTransaction(
      id: json['id'] as String? ?? newId(),
      type: normalizedType,
      amount: asDouble(json['amount']),
      currency: (json['currency'] as String?)?.toUpperCase() ?? 'CNY',
      assetId: json['assetId'] as String? ?? '',
      assetName: json['assetName'] as String? ?? '',
      note: json['note'] as String? ?? '',
      occurredAt: DateTime.tryParse(json['occurredAt'] as String? ?? '') ?? DateTime.now(),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type,
        'amount': amount,
        'currency': currency,
        'assetId': assetId,
        'assetName': assetName,
        'note': note,
        'occurredAt': occurredAt.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };
}

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
    List<DebtTransaction>? transactions,
    DateTime? createdAt,
  })  : imageBase64List = _normalizeImages(imageBase64List, imageBase64),
        transactions = transactions ?? <DebtTransaction>[],
        createdAt = createdAt ?? DateTime.now();

  final String id;
  String name;
  String direction; // payable / receivable
  double amount;
  String currency;
  String note;
  List<String> imageBase64List; // 本地压缩后的图片 base64，最多 3 张，不上传服务器。
  List<DebtTransaction> transactions; // 本地还款/收款记录。
  DateTime createdAt;

  bool get isPayable => direction == 'payable';
  bool get isReceivable => direction == 'receivable';
  bool get hasImage => imageBase64List.isNotEmpty;
  bool get isSettled => amount <= 0.000000001;
  double get settledAmount => transactions.fold<double>(0, (sum, item) => sum + item.amount);
  double get originalAmount => amount + settledAmount;

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
    final rawTransactions = json['transactions'];
    return DebtItem(
      id: json['id'] as String? ?? newId(),
      name: json['name'] as String? ?? '未命名借款',
      direction: json['direction'] as String? ?? 'payable',
      amount: asDouble(json['amount']),
      currency: (json['currency'] as String?)?.toUpperCase() ?? 'CNY',
      note: json['note'] as String? ?? '',
      imageBase64: json['imageBase64'] as String? ?? '',
      imageBase64List: rawList is List ? rawList.whereType<String>().toList() : null,
      transactions: rawTransactions is List
          ? rawTransactions
              .whereType<Map>()
              .map((e) => DebtTransaction.fromJson(e.cast<String, dynamic>()))
              .toList(growable: true)
          : null,
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
        'transactions': transactions.map((e) => e.toJson()).toList(),
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
