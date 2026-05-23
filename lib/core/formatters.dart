import 'number_utils.dart';

String money(num? value, String currency, {bool showCurrency = true}) {
  final text = (value ?? 0).toStringAsFixed(3);
  return showCurrency ? '$text $currency' : text;
}

String trimNum(num value) {
  if (value == value.roundToDouble()) return value.toStringAsFixed(0);
  return value.toStringAsFixed(6).replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

/// Normalizes the user-entered API base URL.
///
/// Examples:
/// - `ledger.example.com/` -> `https://ledger.example.com`
/// - `https://ledger.example.com/api/health` -> `https://ledger.example.com`
/// - `http://127.0.0.1:8787/` -> `http://127.0.0.1:8787`
/// - `http://ledger.example.com` -> `https://ledger.example.com`
String normalizeBaseUrl(String input) {
  var value = input.trim();
  if (value.isEmpty) return '';

  value = value.replaceAll(RegExp(r'\s+'), '');

  if (!value.startsWith(RegExp(r'https?://', caseSensitive: false))) {
    value = 'https://$value';
  }

  final parsed = Uri.tryParse(value);
  if (parsed == null || parsed.host.trim().isEmpty) {
    return value.replaceAll(RegExp(r'/+$'), '');
  }

  final host = parsed.host.trim();
  final isLocalHost = host == 'localhost' || host == '127.0.0.1' || host.startsWith('192.168.') || host.startsWith('10.');
  final scheme = parsed.scheme == 'http' && !isLocalHost ? 'https' : parsed.scheme;
  final port = parsed.hasPort ? ':${parsed.port}' : '';
  return '$scheme://$host$port';
}

String shortTime(String? iso, {String fallback = '未刷新'}) {
  if (iso == null || iso.isEmpty) return fallback;
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  final local = dt.toLocal();
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
}


double toValuationAmount(Map<String, dynamic>? map, List<String> path) {
  return numFromPath(map, path) ?? 0;
}

String monthText(DateTime value) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}';
}

String dateText(DateTime value) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${value.year}-${two(value.month)}-${two(value.day)}';
}
