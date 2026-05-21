import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/number_utils.dart';
import '../models/asset_item.dart';
import '../models/debt_item.dart';
import '../models/ledger_settings.dart';
import '../models/market_option.dart';
import 'quote_api_service.dart';

class LedgerStore extends GetxController {
  LedgerStore({required QuoteApiService apiService}) : _apiService = apiService;

  final QuoteApiService _apiService;

  final Rx<LedgerSettings> _settings = LedgerSettings().obs;
  final RxList<AssetItem> assets = <AssetItem>[].obs;
  final RxList<DebtItem> debts = <DebtItem>[].obs;
  final Rxn<Map<String, dynamic>> _valuation = Rxn<Map<String, dynamic>>();
  final RxBool _isRefreshing = false.obs;
  final RxBool _showRefreshSpinner = false.obs;
  final RxnString _lastError = RxnString();
  final RxBool _appLocked = false.obs;
  final RxBool _appInForeground = true.obs;
  final RxBool _unlockPromptActive = false.obs;
  DateTime? _lastUnlockedAt;
  Future<void>? _activeRefresh;
  int _refreshSequence = 0;
  final Set<int> _timedOutRefreshes = <int>{};
  Timer? _refreshSpinnerGuardTimer;
  DateTime? _lastRefreshFinishedAt;
  DateTime? _lastManualRefreshAt;

  static const Duration _refreshTimeout = Duration(seconds: 35);
  static const Duration _refreshSpinnerMaxVisible = Duration(seconds: 10);
  static const Duration _autoRefreshCooldown = Duration(seconds: 30);
  static const Duration _manualRefreshCooldown = Duration(seconds: 3);

  LedgerSettings get settings => _settings.value;
  set settings(LedgerSettings value) => _settings.value = value;

  Map<String, dynamic>? get valuation => _valuation.value;
  set valuation(Map<String, dynamic>? value) => _valuation.value = value;

  bool get isRefreshing => _isRefreshing.value;
  set isRefreshing(bool value) => _isRefreshing.value = value;

  bool get showRefreshSpinner => _showRefreshSpinner.value;
  set showRefreshSpinner(bool value) => _setRefreshSpinner(value);

  String? get lastError => _lastError.value;
  set lastError(String? value) => _lastError.value = value;

  bool get hasApiToken => settings.apiToken.trim().isNotEmpty;
  bool get appLocked => _appLocked.value;
  set appLocked(bool value) => _appLocked.value = value;

  RxBool get appInForegroundRx => _appInForeground;
  bool get appInForeground => _appInForeground.value;
  set appInForeground(bool value) => _appInForeground.value = value;

  bool get unlockPromptActive => _unlockPromptActive.value;
  set unlockPromptActive(bool value) => _unlockPromptActive.value = value;
  bool get appLockEnabled => settings.appLockEnabled;
  bool get appBiometricsEnabled => settings.useDeviceLock;
  bool get appPinEnabled => settings.usePinLock;
  String get appLockMethod => settings.useDeviceLock ? 'device' : (settings.usePinLock ? 'pin' : 'none');
  int get remainingPinAttempts => (8 - settings.appLockFailedAttempts).clamp(0, 8).toInt();

  @override
  void onClose() {
    _refreshSpinnerGuardTimer?.cancel();
    super.onClose();
  }

  static const _storageKey = 'personal_ledger_v1';

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.trim().isEmpty) return;

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      settings = LedgerSettings.fromJson((data['settings'] as Map?)?.cast<String, dynamic>() ?? {});
      assets
        ..clear()
        ..addAll(((data['assets'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => AssetItem.fromJson(e.cast<String, dynamic>())));
      debts
        ..clear()
        ..addAll(((data['debts'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => DebtItem.fromJson(e.cast<String, dynamic>())));
      valuation = (data['valuation'] as Map?)?.cast<String, dynamic>();
    } catch (_) {
      // 本地数据损坏时不让 App 崩溃。
    }
  }


  void initializeAppLockState() {
    appInForeground = true;
    appLocked = settings.appLockEnabled;
  }

  /// 进入后台/多任务前先切到锁屏，避免系统任务卡片截到资产金额。
  ///
  /// 注意：Android 指纹 / iOS Face ID 弹窗本身也会触发 inactive/paused。
  /// 这种情况下不要重复改锁屏状态，否则会出现生物识别弹窗循环。
  void preparePrivacySnapshot() {
    appInForeground = false;
    if (unlockPromptActive) {
      return;
    }
    if (settings.appLockEnabled) {
      appLocked = true;
    }
  }

  /// 回到前台时保持锁屏状态；LockScreen 会在前台后再触发生物识别。
  ///
  /// 这个方法只在 App 真的进入后台后再回来时调用。
  /// 截图、下拉状态栏这类只触发 inactive 的场景不会调用它，避免锁屏过于敏感。
  void markAppForegrounded() {
    appInForeground = true;
    if (!settings.appLockEnabled) {
      return;
    }
    if (unlockPromptActive || _recentlyUnlocked()) {
      return;
    }
    appLocked = true;
  }

  /// App 只是从 inactive 回到 resumed，例如截图、下拉状态栏、系统弹窗返回。
  /// 这类场景保持前台状态，不主动锁 App。
  void markAppStillForegrounded() {
    appInForeground = true;
  }

  bool _recentlyUnlocked() {
    final last = _lastUnlockedAt;
    if (last == null) return false;
    return DateTime.now().difference(last) < const Duration(seconds: 2);
  }

  void lockApp() {
    if (settings.appLockEnabled) {
      appLocked = true;
    }
  }

  Future<void> unlockApp() async {
    _lastUnlockedAt = DateTime.now();
    unlockPromptActive = false;
    appLocked = false;
    if (settings.appLockFailedAttempts != 0) {
      settings = settings.copyWith(appLockFailedAttempts: 0);
      await save();
      update();
    }
  }

  Future<void> enableDeviceAppLock() async {
    if (!settings.hasPin) {
      throw Exception('pinRequiredBeforeBiometrics'.tr);
    }
    settings = settings.copyWith(
      appLockEnabled: true,
      appLockMethod: 'device',
      appBiometricsEnabled: true,
      appLockFailedAttempts: 0,
    );
    appLocked = false;
    await save();
    update();
  }

  Future<void> enablePinAppLock(String pin, {bool keepBiometrics = false}) async {
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      throw Exception('pinMustBeSixDigits'.tr);
    }
    final salt = _generateSalt();
    final shouldKeepBiometrics = keepBiometrics && settings.appBiometricsEnabled;
    settings = settings.copyWith(
      appLockEnabled: true,
      appLockMethod: shouldKeepBiometrics ? 'device' : 'pin',
      appBiometricsEnabled: shouldKeepBiometrics,
      appPinSalt: salt,
      appPinHash: _hashPin(pin, salt),
      appLockFailedAttempts: 0,
    );
    appLocked = false;
    await save();
    update();
  }

  Future<void> disableAppLock() async {
    settings = settings.copyWith(
      appLockEnabled: false,
      appLockMethod: 'none',
      appBiometricsEnabled: false,
      appPinSalt: '',
      appPinHash: '',
      appLockFailedAttempts: 0,
    );
    appLocked = false;
    await save();
    update();
  }

  Future<bool> verifyPinAndUnlock(String pin) async {
    if (!settings.usePinLock) return true;
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) return false;

    final ok = _hashPin(pin, settings.appPinSalt) == settings.appPinHash;
    if (ok) {
      await unlockApp();
      return true;
    }

    final attempts = settings.appLockFailedAttempts + 1;
    if (attempts >= 8) {
      await wipeAllData();
      return false;
    }

    settings = settings.copyWith(appLockFailedAttempts: attempts);
    await save();
    update();
    return false;
  }

  Future<void> wipeAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
    settings = LedgerSettings();
    assets.clear();
    debts.clear();
    valuation = null;
    lastError = null;
    isRefreshing = false;
    showRefreshSpinner = false;
    appLocked = false;
    _activeRefresh = null;
    _refreshSequence++;
    update();
  }

  String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt:$pin');
    return sha256.convert(bytes).toString();
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, exportJson());
  }

  String exportJson() {
    return const JsonEncoder.withIndent('  ').convert({
      'settings': settings.toJson(),
      'assets': assets.map((e) => e.toJson()).toList(),
      'debts': debts.map((e) => e.toJson()).toList(),
      'valuation': valuation,
      'exportedAt': DateTime.now().toIso8601String(),
    });
  }

  Future<void> importJson(String raw) async {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    settings = LedgerSettings.fromJson((data['settings'] as Map?)?.cast<String, dynamic>() ?? {});
    assets
      ..clear()
      ..addAll(((data['assets'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => AssetItem.fromJson(e.cast<String, dynamic>())));
    debts
      ..clear()
      ..addAll(((data['debts'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => DebtItem.fromJson(e.cast<String, dynamic>())));
    valuation = (data['valuation'] as Map?)?.cast<String, dynamic>();
    await save();
    update();
  }

  Future<void> updateSettings(LedgerSettings newSettings) async {
    settings = newSettings;
    _applyGetXRuntimeSettings();
    await save();
    update();
  }

  void _applyGetXRuntimeSettings() {
    Get.changeThemeMode(_themeMode(settings.themeMode));
    final language = settings.languageMode;
    if (language == 'zh' || language == 'en') {
      Get.updateLocale(Locale(language));
    } else {
      Get.updateLocale(Locale(_normalizeLanguageCode(Get.deviceLocale ?? WidgetsBinding.instance.platformDispatcher.locale)));
    }
  }

  ThemeMode _themeMode(String mode) {
    return switch (mode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  String _normalizeLanguageCode(Locale? locale) {
    final code = locale?.languageCode.toLowerCase() ?? 'en';
    return code.startsWith('zh') ? 'zh' : 'en';
  }

  Future<void> addAsset(AssetItem item) async {
    assets.insert(0, item);
    await save();
    update();
  }

  Future<void> updateAsset(AssetItem item) async {
    final index = assets.indexWhere((e) => e.id == item.id);
    if (index >= 0) {
      assets[index] = item;
    } else {
      assets.insert(0, item);
    }
    await save();
    update();
  }

  Future<void> removeAsset(String id) async {
    assets.removeWhere((e) => e.id == id);
    _syncValuationAfterLocalChange();
    await save();
    update();
  }

  Future<void> addDebt(DebtItem item) async {
    debts.insert(0, item);
    await save();
    update();
  }

  Future<void> updateDebt(DebtItem item) async {
    final index = debts.indexWhere((e) => e.id == item.id);
    if (index >= 0) {
      debts[index] = item;
    } else {
      debts.insert(0, item);
    }
    await save();
    update();
  }

  Future<void> removeDebt(String id) async {
    debts.removeWhere((e) => e.id == id);
    _syncValuationAfterLocalChange();
    await save();
    update();
  }


  void _syncValuationAfterLocalChange() {
    lastError = null;
    showRefreshSpinner = false;
    isRefreshing = false;

    if (assets.isEmpty && debts.isEmpty) {
      valuation = null;
      return;
    }

    // 删除某一项时不要直接退回纯本地估值，否则剩余股票/ETF/虚拟币等远程资产会临时变成 0，
    // 造成“删除后净资产归零，点刷新又恢复”的错觉。这里优先保留上一轮远程估值里仍然存在的项目，
    // 再对现金/手动资产等可本地计算的项目补值。
    valuation = _buildValuationPreservingExisting();
  }

  Future<void> refreshValuation({bool force = false, String source = 'unknown'}) {
    // 不管是 15 分钟定时、下拉刷新、右上角刷新还是保存后刷新，只允许同一时间存在一个估值请求。
    // 这里即使 force=true，也先复用当前请求，避免多个请求互相覆盖 UI 状态。
    if (_activeRefresh != null) {
      return _activeRefresh!;
    }

    final now = DateTime.now();

    // 这次日志里能看到 1～2 秒内重复触发 refresh#4/#5/#6，接口本身 70ms 左右就返回，
    // 所以问题不是接口卡住，而是 UI/手势/生命周期里触发了过多刷新。
    // 这里做双保险：自动刷新 30 秒内只允许一次，手动刷新 3 秒内只允许一次。
    if (!force && _lastRefreshFinishedAt != null) {
      final elapsed = now.difference(_lastRefreshFinishedAt!);
      if (elapsed < _autoRefreshCooldown) {
        return Future<void>.value();
      }
    }

    if (force && _lastManualRefreshAt != null) {
      final elapsed = now.difference(_lastManualRefreshAt!);
      if (elapsed < _manualRefreshCooldown) {
        return Future<void>.value();
      }
    }
    if (force) {
      _lastManualRefreshAt = now;
    }

    final refreshId = ++_refreshSequence;
    _timedOutRefreshes.removeWhere((id) => id < refreshId - 10);
    if (assets.isNotEmpty || debts.isNotEmpty) {
      showRefreshSpinner = true;
    }

    final future = _refreshValuationInternal(refreshId).timeout(
      _refreshTimeout,
      onTimeout: () async {
        _timedOutRefreshes.add(refreshId);
        if (refreshId == _refreshSequence) {
          valuation = _buildLocalValuation();
          lastError = 'refreshTimeoutError'.tr;
          isRefreshing = false;
          showRefreshSpinner = false;
          await save();
          update();
        }
      },
    ).catchError((Object error, StackTrace stackTrace) async {
      if (refreshId == _refreshSequence) {
        valuation = _buildLocalValuation();
        lastError = error.toString().replaceFirst('Exception: ', '');
        showRefreshSpinner = false;
        await save();
      }
    }).whenComplete(() {
      if (refreshId == _refreshSequence) {
        isRefreshing = false;
        showRefreshSpinner = false;
        _lastRefreshFinishedAt = DateTime.now();
        update();
      }
      _activeRefresh = null;
    });

    _activeRefresh = future;
    return future;
  }

  Future<void> _refreshValuationInternal(int refreshId) async {
    if (assets.isEmpty && debts.isEmpty) {
      valuation = null;
      lastError = null;
      await save();
      update();
      return;
    }

    // 未配置 API 地址或 Token 时，不要在首页直接弹红色错误。
    // 用户仍可继续本地记账；需要联网估值时，在设置页「测试 API」会给出明确原因。
    if (settings.apiBaseUrl.trim().isEmpty || settings.apiToken.trim().isEmpty) {
      valuation = _buildLocalValuation();
      lastError = null;
      await save();
      update();
      return;
    }

    isRefreshing = true;
    lastError = null;
    update();

    try {
      final remoteValuation = await _apiService.valuatePortfolio(
        settings: settings,
        assets: assets,
        debts: debts,
      );

      // 如果旧请求超时后才回来，不允许它覆盖新状态。
      if (refreshId != _refreshSequence || _timedOutRefreshes.contains(refreshId)) {
        return;
      }

      valuation = remoteValuation;
      await save();
    } catch (e) {
      if (refreshId != _refreshSequence || _timedOutRefreshes.contains(refreshId)) {
        return;
      }

      // API 失败时保留本地可计算估值，不影响继续记账。
      valuation = _buildLocalValuation();
      lastError = e.toString().replaceFirst('Exception: ', '');
      await save();
    } finally {
      if (refreshId == _refreshSequence && !_timedOutRefreshes.contains(refreshId)) {
        isRefreshing = false;
        showRefreshSpinner = false;
        update();
      }
    }
  }

  void _setRefreshSpinner(bool value) {
    if (_showRefreshSpinner.value == value) {
      return;
    }

    _refreshSpinnerGuardTimer?.cancel();
    _showRefreshSpinner.value = value;

    if (value) {
      _refreshSpinnerGuardTimer = Timer(_refreshSpinnerMaxVisible, () {
        if (_showRefreshSpinner.value) {
          _showRefreshSpinner.value = false;
          update();
        }
      });
    }
  }


  Map<String, dynamic> _buildValuationPreservingExisting() {
    final currency = settings.defaultCurrency;
    final previousAssets = <String, Map<String, dynamic>>{};
    final previousAssetList = valuation?['assets'];
    if (previousAssetList is List) {
      for (final item in previousAssetList) {
        if (item is Map && item['id'] != null) {
          previousAssets[item['id'].toString()] = item.cast<String, dynamic>();
        }
      }
    }

    final previousDebts = <String, Map<String, dynamic>>{};
    final previousDebtList = valuation?['liabilities'];
    if (previousDebtList is List) {
      for (final item in previousDebtList) {
        if (item is Map && item['id'] != null) {
          previousDebts[item['id'].toString()] = item.cast<String, dynamic>();
        }
      }
    }

    double assetTotal = 0;
    double receivableTotal = 0;
    double payableTotal = 0;

    final valuedAssets = assets.map((item) {
      final previous = previousAssets[item.id];
      double? value = previous == null ? null : _asDouble(previous['value']);
      double? price = previous == null ? null : _asDouble(previous['price']);
      String quoteCurrency = (previous?['quoteCurrency'] as String?) ?? item.currency;

      if (value == null) {
        if (item.type == 'cash' && item.currency == currency) {
          value = item.quantity;
          price = 1;
          quoteCurrency = item.currency;
        } else if (item.type == 'manual' && item.currency == currency) {
          price = item.manualPrice;
          value = item.quantity * item.manualPrice;
          quoteCurrency = item.currency;
        }
      }

      if (value != null) {
        assetTotal += value;
      }

      return {
        ...?previous,
        'id': item.id,
        'name': item.name,
        'type': item.type,
        'symbol': item.symbol,
        'unit': item.unit,
        'quantity': item.quantity,
        'price': price,
        'quoteCurrency': quoteCurrency,
        'value': value,
        'valueCurrency': currency,
        'preserved': previous != null,
      };
    }).toList();

    final valuedDebts = debts.map((item) {
      final previous = previousDebts[item.id];
      double? value = previous == null ? null : _asDouble(previous['value']);
      if (value == null && item.currency == currency) {
        value = item.amount;
      }

      if (value != null) {
        if (item.direction == 'receivable') {
          receivableTotal += value;
        } else {
          payableTotal += value;
        }
      }

      return {
        ...?previous,
        'id': item.id,
        'name': item.name,
        'direction': item.direction,
        'amount': item.amount,
        'currency': item.currency,
        'value': value,
        'valueCurrency': currency,
        'preserved': previous != null,
      };
    }).toList();

    return {
      'ok': true,
      'defaultCurrency': currency,
      'totals': {
        'assetTotal': assetTotal,
        'receivableTotal': receivableTotal,
        'payableTotal': payableTotal,
        'netWorth': assetTotal + receivableTotal - payableTotal,
      },
      'assets': valuedAssets,
      'liabilities': valuedDebts,
      'failedAssets': (valuation?['failedAssets'] as List?) ?? [],
      'updatedAt': DateTime.now().toIso8601String(),
      'source': 'local_preserved',
    };
  }

  double? _asDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  Map<String, dynamic> _buildLocalValuation() {
    final currency = settings.defaultCurrency;
    double assetTotal = 0;
    double receivableTotal = 0;
    double payableTotal = 0;

    final valuedAssets = assets.map((item) {
      double? value;
      double? price;

      if (item.type == 'cash' && item.currency == currency) {
        value = item.quantity;
        price = 1;
      } else if (item.type == 'manual' && item.currency == currency) {
        price = item.manualPrice;
        value = item.quantity * item.manualPrice;
      }

      if (value != null) {
        assetTotal += value;
      }

      return {
        'id': item.id,
        'name': item.name,
        'type': item.type,
        'symbol': item.symbol,
        'quantity': item.quantity,
        'price': price,
        'quoteCurrency': item.currency,
        'value': value,
        'valueCurrency': currency,
        'localOnly': true,
      };
    }).toList();

    final valuedDebts = debts.map((item) {
      double? value;
      if (item.currency == currency) {
        value = item.amount;
        if (item.direction == 'receivable') {
          receivableTotal += value;
        } else {
          payableTotal += value;
        }
      }
      return {
        'id': item.id,
        'name': item.name,
        'direction': item.direction,
        'amount': item.amount,
        'currency': item.currency,
        'value': value,
        'valueCurrency': currency,
        'localOnly': true,
      };
    }).toList();

    return {
      'ok': true,
      'defaultCurrency': currency,
      'totals': {
        'assetTotal': assetTotal,
        'receivableTotal': receivableTotal,
        'payableTotal': payableTotal,
        'netWorth': assetTotal + receivableTotal - payableTotal,
      },
      'assets': valuedAssets,
      'liabilities': valuedDebts,
      'failedAssets': [],
      'updatedAt': DateTime.now().toIso8601String(),
      'source': 'local',
    };
  }

  Future<List<MarketOption>> searchMarket(String type, String query, {int limit = 12}) {
    return _apiService.searchMarket(settings: settings, type: type, query: query, limit: limit);
  }

  Future<bool> testApi() => _apiService.testApi(settings);

  double? get assetTotal => numFromPath(valuation, ['totals', 'assetTotal']);
  double? get receivableTotal => numFromPath(valuation, ['totals', 'receivableTotal']);
  double? get payableTotal => numFromPath(valuation, ['totals', 'payableTotal']);
  double? get netWorth => numFromPath(valuation, ['totals', 'netWorth']);
  String? get updatedAt => valuation?['updatedAt'] as String?;

  Map<String, dynamic>? valuationAsset(String id) {
    final list = valuation?['assets'];
    if (list is! List) return null;
    for (final item in list) {
      if (item is Map && item['id'] == id) return item.cast<String, dynamic>();
    }
    return null;
  }

  Map<String, dynamic>? valuationDebt(String id) {
    final list = valuation?['liabilities'];
    if (list is! List) return null;
    for (final item in list) {
      if (item is Map && item['id'] == id) return item.cast<String, dynamic>();
    }
    return null;
  }

  List<Map<String, dynamic>> get failedAssets => ((valuation?['failedAssets'] as List?) ?? [])
      .whereType<Map>()
      .map((e) => e.cast<String, dynamic>())
      .toList();
}
