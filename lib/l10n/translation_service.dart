import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../models/market_option.dart';

class TranslationService extends Translations {
  TranslationService._(this._keys);

  final Map<String, Map<String, String>> _keys;

  static const fallbackLocale = Locale('en');
  static const supportedLocales = [
    Locale('en'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
  ];
  static const supportedLanguageCodes = ['en', 'zh', 'zh_Hant'];

  static final Map<String, Map<String, dynamic>> rawValues = {};

  @override
  Map<String, Map<String, String>> get keys => _keys;

  static Future<TranslationService> load() async {
    final result = <String, Map<String, String>>{};
    for (final code in supportedLanguageCodes) {
      final raw = await rootBundle.loadString('assets/i18n/$code.json');
      final jsonMap = json.decode(raw) as Map<String, dynamic>;
      rawValues[code] = jsonMap;
      result[code] =
          jsonMap.map((key, value) => MapEntry(key, _stringify(value)));
    }
    return TranslationService._(result);
  }

  static String normalizeLanguageCode(Locale? locale) {
    final code = locale?.languageCode.toLowerCase() ?? 'en';
    if (code.startsWith('zh')) {
      final script = locale?.scriptCode?.toLowerCase();
      final country = locale?.countryCode?.toLowerCase();
      if (script == 'hant' ||
          country == 'tw' ||
          country == 'hk' ||
          country == 'mo') return 'zh_Hant';
      return 'zh';
    }
    return 'en';
  }

  /// Always returns a concrete locale.
  ///
  /// GetX will sometimes render raw keys on the very first frame when `locale` is
  /// null and the app is using the system language. Resolving system language
  /// here keeps the first screen stable: Chinese devices use zh, everything else
  /// falls back to English.
  static Locale localeFromMode(String mode) {
    return switch (mode) {
      'zh' => const Locale('zh'),
      'zh_Hant' =>
        const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant'),
      'en' => const Locale('en'),
      _ => currentDeviceLocale(),
    };
  }

  static Locale currentDeviceLocale() {
    final code = normalizeLanguageCode(
        Get.deviceLocale ?? WidgetsBinding.instance.platformDispatcher.locale);
    return code == 'zh_Hant'
        ? const Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
        : Locale(code);
  }

  static String _stringify(dynamic value) {
    if (value is List) {
      return value.map((e) => e.toString()).join('|');
    }
    return value?.toString() ?? '';
  }
}

extension TranslationListExtension on String {
  List<String> get trList {
    final value = tr;
    if (value.trim().isEmpty || value == this) return const [];
    return value
        .split('|')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }
}

String trEstimateIn(String currency) =>
    'estimateIn'.trParams({'currency': currency});

String trPartialQuoteFailed(String names) =>
    'partialQuoteFailed'.trParams({'names': names});

String trDeleteCannotRecover(String title) =>
    'deleteCannotRecover'.trParams({'title': title});

String trImageLoadFailed(String error) =>
    'imageLoadFailed'.trParams({'error': error});

String trUnitPrice(String price, String? quoteCurrency) {
  final quotePart = quoteCurrency == null ? '' : ' · $quoteCurrency';
  return 'unitPrice'.trParams({'price': price, 'quotePart': quotePart});
}

String trSelectLabel(String label) => 'selectLabel'.trParams({'label': label});

String trAssetType(String type) {
  return switch (type) {
    'cash' => 'cashType'.tr,
    'manual' => 'manualShort'.tr,
    'crypto' => 'cryptoType'.tr,
    'metal' => 'metalType'.tr,
    'stock' => 'stockType'.tr,
    'etf' => 'etfType'.tr,
    'cn_stock' => 'cnStockType'.tr,
    'cn_etf' => 'cnEtfType'.tr,
    _ => type,
  };
}

String trDebtDirection(String direction) {
  return direction == 'payable' ? 'iOweOthers'.tr : 'othersOweMe'.tr;
}

String trDefaultName(String type) {
  return switch (type) {
    'cash' => 'defaultCashName'.tr,
    'manual' => 'defaultManualAssetName'.tr,
    _ => '',
  };
}

String trNameHint(String type) {
  return switch (type) {
    'cash' => 'nameHintCash'.tr,
    'manual' => 'nameHintManual'.tr,
    'crypto' => 'nameHintCrypto'.tr,
    'metal' => 'nameHintMetal'.tr,
    'stock' => 'nameHintStock'.tr,
    'etf' => 'nameHintEtf'.tr,
    'cn_stock' => 'nameHintCnStock'.tr,
    'cn_etf' => 'nameHintCnEtf'.tr,
    _ => 'nameHintAsset'.tr,
  };
}

String trSymbolHint(String type) {
  return switch (type) {
    'crypto' => 'cryptoSymbolHint'.tr,
    'metal' => 'metalSymbolHint'.tr,
    'stock' => 'stockSymbolHint'.tr,
    'etf' => 'etfSymbolHint'.tr,
    'cn_stock' => 'cnStockSymbolHint'.tr,
    'cn_etf' => 'cnEtfSymbolHint'.tr,
    _ => 'genericSymbolHint'.tr,
  };
}

String trSymbolHelp(String type) {
  return switch (type) {
    'crypto' => 'cryptoHelp'.tr,
    'metal' => 'metalHelp'.tr,
    'stock' => 'stockHelp'.tr,
    'etf' => 'etfHelp'.tr,
    'cn_stock' => 'cnStockHelp'.tr,
    'cn_etf' => 'cnEtfHelp'.tr,
    'manual' => 'manualHelp'.tr,
    _ => 'cashHelp'.tr,
  };
}

String trMetalUnit(String unit) {
  return switch (unit) {
    'gram' => 'unitGram'.tr,
    'troy_ounce' => 'unitTroyOunce'.tr,
    _ => unit,
  };
}

String trMarketOptionName(MarketOption item) {
  if (item.assetType == 'metal') {
    final code = item.displayCode.trim().isNotEmpty
        ? item.displayCode.trim().toUpperCase()
        : item.symbol.trim().toUpperCase();
    return switch (code) {
      'XAU' => 'metalGoldName'.tr,
      'XAG' => 'metalSilverName'.tr,
      'XPT' => 'metalPlatinumName'.tr,
      'XPD' => 'metalPalladiumName'.tr,
      _ => item.name,
    };
  }
  return item.name;
}

String trMarketProvider(String provider) {
  final value = provider.trim();
  if (value.isEmpty) return '';
  final key = value.toLowerCase().replaceAll(' ', '');
  return switch (key) {
    'local' => 'providerLocal'.tr,
    'remote' => 'providerRemote'.tr,
    'twelvedata' => 'providerTwelveData'.tr,
    'coingecko' => 'providerCoinGecko'.tr,
    'goldapi' => 'providerGoldApi'.tr,
    _ => value,
  };
}

String trNoMatch(String type) {
  return switch (type) {
    'crypto' => 'noCryptoMatch'.tr,
    'stock' => 'noStockMatch'.tr,
    'etf' => 'noEtfMatch'.tr,
    'cn_stock' => 'noCnStockMatch'.tr,
    'cn_etf' => 'noCnEtfMatch'.tr,
    'metal' => 'noMetalMatch'.tr,
    _ => 'noMatch'.tr,
  };
}

String trBillCategory(String key) => 'billCategory_$key'.tr;
