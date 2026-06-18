import 'dart:async';
import 'dart:convert';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;

import '../core/formatters.dart';
import '../models/asset_item.dart';
import '../models/debt_item.dart';
import '../models/ledger_settings.dart';
import '../models/market_option.dart';

class QuoteApiService {
  QuoteApiService({http.Client? client}) : client = client ?? http.Client();

  final http.Client client;

  static const Duration _portfolioTimeout = Duration(seconds: 18);
  static const Duration _searchTimeout = Duration(seconds: 8);
  static const Duration _healthTimeout = Duration(seconds: 8);

  Future<Map<String, dynamic>> valuatePortfolio({
    required LedgerSettings settings,
    required List<AssetItem> assets,
    required List<DebtItem> debts,
  }) async {
    final base = normalizeBaseUrl(settings.apiBaseUrl);
    if (base.isEmpty) {
      throw Exception('apiAddressRequiredDetail'.tr);
    }

    final uri = Uri.parse('$base/api/portfolio/valuate');
    final body = jsonEncode({
      'defaultCurrency': settings.defaultCurrency,
      'assets': assets.map((e) => e.toApiJson()).toList(),
      'liabilities': debts.map((e) => e.toApiJson()).toList(),
    });

    try {
      final response = await client
          .post(
            uri,
            headers: {
              'content-type': 'application/json',
              if (settings.apiToken.trim().isNotEmpty) 'x-api-token': settings.apiToken.trim(),
            },
            body: body,
          )
          .timeout(_portfolioTimeout);

      final decoded = _decodeObject(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300 || decoded['ok'] != true) {
        throw Exception(_friendlyHttpError(response.statusCode, decoded['error']?.toString()));
      }
      return decoded;
    } on TimeoutException {
      throw Exception('apiTimeoutDetail'.tr);
    } catch (error) {
      throw Exception(_friendlyNetworkError(error, base));
    }
  }

  Future<List<MarketOption>> searchMarket({
    required LedgerSettings settings,
    required String type,
    required String query,
    int limit = 12,
  }) async {
    final base = normalizeBaseUrl(settings.apiBaseUrl);
    if (base.isEmpty) {
      return const [];
    }

    final uri = Uri.parse('$base/api/search').replace(queryParameters: {
      'type': type,
      'q': query.trim(),
      'limit': '$limit',
    });

    try {
      final response = await client.get(
        uri,
        headers: {
          if (settings.apiToken.trim().isNotEmpty) 'x-api-token': settings.apiToken.trim(),
        },
      ).timeout(_searchTimeout);

      final decoded = _tryDecodeObject(response.body);
      if (response.statusCode < 200 || response.statusCode >= 300 || decoded == null || decoded['ok'] != true) {
        return const [];
      }

      return ((decoded['items'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => MarketOption.fromJson(e.cast<String, dynamic>()))
          .where((e) => e.symbol.trim().isNotEmpty)
          .toList();
    } on TimeoutException {
      return const [];
    } catch (_) {
      return const [];
    }
  }

  Future<bool> testApi(LedgerSettings settings) async {
    final base = normalizeBaseUrl(settings.apiBaseUrl);
    if (base.isEmpty) {
      throw Exception('apiAddressRequiredDetail'.tr);
    }
    final uri = Uri.parse('$base/api/health');
    try {
      final response = await client.get(
        uri,
        headers: {
          if (settings.apiToken.trim().isNotEmpty) 'x-api-token': settings.apiToken.trim(),
        },
      ).timeout(_healthTimeout);

      final decoded = _tryDecodeObject(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300 && decoded != null && decoded['ok'] == true) {
        return true;
      }
      throw Exception(_friendlyHttpError(response.statusCode, decoded?['error']?.toString()));
    } on TimeoutException {
      throw Exception('apiTimeoutDetail'.tr);
    } catch (error) {
      throw Exception(_friendlyNetworkError(error, base));
    }
  }

  Map<String, dynamic> _decodeObject(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // handled below
    }
    throw Exception('apiResponseInvalid'.tr);
  }

  Map<String, dynamic>? _tryDecodeObject(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {
      // ignored
    }
    return null;
  }

  String _friendlyHttpError(int statusCode, String? rawMessage) {
    final raw = rawMessage?.trim() ?? '';
    if (statusCode == 401 || raw.toLowerCase().contains('unauthorized') || raw.toLowerCase().contains('token')) {
      return 'apiUnauthorizedDetail'.tr;
    }
    if (statusCode == 404) {
      return 'apiNotFoundDetail'.tr;
    }
    if (statusCode >= 500) {
      return 'apiServerErrorDetail'.trParams({'status': '$statusCode'});
    }
    if (raw.isNotEmpty) {
      return raw;
    }
    return 'apiRequestFailedDetail'.trParams({'status': '$statusCode'});
  }

  String _friendlyNetworkError(Object error, String baseUrl) {
    var message = error.toString().replaceFirst('Exception: ', '').trim();

    // Avoid wrapping our own friendly messages again.
    final friendlyKeys = [
      'apiAddressRequiredDetail'.tr,
      'apiTokenRequiredDetail'.tr,
      'apiTimeoutDetail'.tr,
      'apiUnauthorizedDetail'.tr,
      'apiNotFoundDetail'.tr,
      'apiResponseInvalid'.tr,
    ];
    if (friendlyKeys.contains(message)) {
      return message;
    }

    final lower = message.toLowerCase();
    if (lower.contains('failed host lookup') ||
        lower.contains('no address associated with hostname') ||
        lower.contains('socketfailedhostlookup') ||
        lower.contains('socketexception')) {
      return 'apiDnsErrorDetail'.trParams({'host': Uri.tryParse(baseUrl)?.host ?? baseUrl});
    }
    if (lower.contains('connection refused')) {
      return 'apiConnectionRefusedDetail'.tr;
    }
    if (lower.contains('handshake') || lower.contains('certificate') || lower.contains('tls')) {
      return 'apiTlsErrorDetail'.tr;
    }
    if (lower.contains('clientexception')) {
      return 'apiNetworkErrorDetail'.tr;
    }

    return message.isEmpty ? 'apiNetworkErrorDetail'.tr : message;
  }
}
