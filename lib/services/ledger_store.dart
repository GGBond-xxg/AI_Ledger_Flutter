import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/number_utils.dart';
import '../models/asset_item.dart';
import '../models/bill_item.dart';
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
  final RxList<BillItem> bills = <BillItem>[].obs;
  final Rx<DateTime> selectedBillMonth = DateTime(DateTime.now().year, DateTime.now().month).obs;
  final RxInt billsVersion = 0.obs;
  final RxInt selectedMainTab = 0.obs;
  final RxInt selectedAssetTab = 0.obs;
  final Rxn<Map<String, dynamic>> _valuation = Rxn<Map<String, dynamic>>();
  final RxBool _isRefreshing = false.obs;
  final RxBool _showRefreshSpinner = false.obs;
  final RxnString _lastError = RxnString();
  final RxBool _appLocked = false.obs;
  final RxBool _privacySnapshotVisible = false.obs;
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

  bool get privacySnapshotVisible => _privacySnapshotVisible.value;
  set privacySnapshotVisible(bool value) => _privacySnapshotVisible.value = value;

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
      bills
        ..clear()
        ..addAll(((data['bills'] as List?) ?? [])
            .whereType<Map>()
            .map((e) => BillItem.fromJson(e.cast<String, dynamic>())));
      valuation = _withoutTransientQuoteErrors((data['valuation'] as Map?)?.cast<String, dynamic>());
      _touchBills();
    } catch (_) {
      // 本地数据损坏时不让 App 崩溃。
    }
  }


  void initializeAppLockState() {
    appInForeground = true;
    privacySnapshotVisible = false;
    appLocked = settings.appLockEnabled;
  }

  /// App 即将被系统遮挡时先显示隐私锁屏快照，避免多任务窗口截到资产金额。
  ///
  /// inactive 可能只是下拉状态栏/截图/系统弹窗，所以 showPrivacySnapshotOnly 不会真正要求解锁；
  /// paused/hidden 才会调用 preparePrivacySnapshot，把 App 置为真正锁定状态。
  void showPrivacySnapshotOnly() {
    if (!settings.appLockEnabled || unlockPromptActive || appLocked) {
      return;
    }
    privacySnapshotVisible = true;
    update();
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
      privacySnapshotVisible = true;
      appLocked = true;
      update();
    }
  }

  /// 回到前台时保持锁屏状态；LockScreen 会在前台后再触发生物识别。
  ///
  /// 这个方法只在 App 真的进入后台后再回来时调用。
  /// 截图、下拉状态栏这类只触发 inactive 的场景不会调用它，避免锁屏过于敏感。
  void markAppForegrounded() {
    appInForeground = true;
    _clearTransientQuoteErrors();
    if (!settings.appLockEnabled) {
      privacySnapshotVisible = false;
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
    _clearTransientQuoteErrors();
    if (!appLocked) {
      privacySnapshotVisible = false;
    }
  }

  Map<String, dynamic>? _withoutTransientQuoteErrors(Map<String, dynamic>? source) {
    if (source == null) return null;
    if ((source['failedAssets'] as List?)?.isNotEmpty == true) {
      return {...source, 'failedAssets': []};
    }
    return source;
  }

  void _clearTransientQuoteErrors() {
    lastError = null;
    final current = valuation;
    final cleaned = _withoutTransientQuoteErrors(current);
    if (!identical(cleaned, current)) {
      valuation = cleaned;
      save();
    }
  }

  bool _recentlyUnlocked() {
    final last = _lastUnlockedAt;
    if (last == null) return false;
    return DateTime.now().difference(last) < const Duration(seconds: 2);
  }

  void lockApp() {
    if (settings.appLockEnabled) {
      privacySnapshotVisible = true;
      appLocked = true;
    }
  }

  Future<void> unlockApp() async {
    _lastUnlockedAt = DateTime.now();
    unlockPromptActive = false;
    privacySnapshotVisible = false;
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
    privacySnapshotVisible = false;
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
    privacySnapshotVisible = false;
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
    privacySnapshotVisible = false;
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
    bills.clear();
    valuation = null;
    lastError = null;
    _touchBills();
    isRefreshing = false;
    showRefreshSpinner = false;
    privacySnapshotVisible = false;
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
      'bills': bills.map((e) => e.toJson()).toList(),
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
    bills
      ..clear()
      ..addAll(((data['bills'] as List?) ?? [])
          .whereType<Map>()
          .map((e) => BillItem.fromJson(e.cast<String, dynamic>())));
    valuation = (data['valuation'] as Map?)?.cast<String, dynamic>();
    _touchBills();
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
    if (language == 'zh_Hant') {
      Get.updateLocale(const Locale('zh', 'TW'));
    } else if (language == 'zh') {
      Get.updateLocale(const Locale('zh', 'CN'));
    } else if (language == 'en') {
      Get.updateLocale(const Locale('en'));
    } else {
      final code = _normalizeLanguageCode(Get.deviceLocale ?? WidgetsBinding.instance.platformDispatcher.locale);
      Get.updateLocale(switch (code) {
        'zh_Hant' => const Locale('zh', 'TW'),
        'zh_Hans' => const Locale('zh', 'CN'),
        _ => Locale(code),
      });
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
    if (code.startsWith('zh')) {
      final script = locale?.scriptCode?.toLowerCase();
      final country = locale?.countryCode?.toLowerCase();
      if (script == 'hant' || country == 'tw' || country == 'hk' || country == 'mo') return 'zh_Hant';
      return 'zh_Hans';
    }
    return 'en';
  }


  void _touchBills() {
    billsVersion.value++;
  }

  Future<void> addBill(BillItem item) async {
    bills.insert(0, item);
    _applyBillAssetEffect(item);
    selectedBillMonth.value = DateTime(item.occurredAt.year, item.occurredAt.month);
    _touchBills();
    _syncValuationAfterLocalChange();
    await save();
    update();
  }

  Future<void> updateBill(BillItem item) async {
    final index = bills.indexWhere((e) => e.id == item.id);
    if (index >= 0) {
      final old = bills[index];
      _applyBillAssetEffect(old, reverse: true);
      bills[index] = item;
      _applyBillAssetEffect(item);
    } else {
      bills.insert(0, item);
      _applyBillAssetEffect(item);
    }
    selectedBillMonth.value = DateTime(item.occurredAt.year, item.occurredAt.month);
    _touchBills();
    _syncValuationAfterLocalChange();
    await save();
    update();
  }

  Future<void> removeBill(String id) async {
    final index = bills.indexWhere((e) => e.id == id);
    if (index >= 0) {
      final old = bills[index];
      bills.removeAt(index);
      _applyBillAssetEffect(old, reverse: true);
    }
    _touchBills();
    _syncValuationAfterLocalChange();
    await save();
    update();
  }

  void _applyBillAssetEffect(BillItem item, {bool reverse = false}) {
    if (item.isExchangeBill) {
      _applyBillExchangeEffect(item, reverse: reverse);
      return;
    }
    _applyBillFundEffect(item, reverse: reverse);
    _applyBillInvestmentEffect(item, reverse: reverse);
  }

  void _applyBillExchangeEffect(BillItem item, {bool reverse = false}) {
    if (item.assetId.trim().isEmpty ||
        item.toAssetId.trim().isEmpty ||
        item.amount <= 0 ||
        item.toAmount <= 0) {
      return;
    }

    final fromIndex = assets.indexWhere((asset) =>
        asset.id == item.assetId &&
        asset.type == 'cash' &&
        asset.currency.toUpperCase() == item.currency.toUpperCase());
    final toIndex = assets.indexWhere((asset) =>
        asset.id == item.toAssetId &&
        asset.type == 'cash' &&
        asset.currency.toUpperCase() == item.toCurrency.toUpperCase());
    if (fromIndex < 0 || toIndex < 0 || fromIndex == toIndex) return;

    final fromAsset = assets[fromIndex];
    final toAsset = assets[toIndex];
    var fromDelta = -item.amount;
    var toDelta = item.toAmount;
    if (reverse) {
      fromDelta = -fromDelta;
      toDelta = -toDelta;
    }

    fromAsset.quantity += fromDelta;
    toAsset.quantity += toDelta;
    if (fromAsset.quantity.abs() < 0.000000001) {
      fromAsset.quantity = 0;
    }
    if (toAsset.quantity.abs() < 0.000000001) {
      toAsset.quantity = 0;
    }
    assets[fromIndex] = fromAsset;
    assets[toIndex] = toAsset;
  }

  void _applyBillFundEffect(BillItem item, {bool reverse = false}) {
    if (item.assetId.trim().isEmpty || item.amount <= 0) return;

    final index = assets.indexWhere((asset) => item.assetId == asset.id && asset.type == 'cash');
    if (index < 0) return;

    final asset = assets[index];

    // A bill uses the linked asset currency. If old imported data is inconsistent,
    // do not mutate the asset to avoid silently converting money without an FX rate.
    if (asset.currency.toUpperCase() != item.currency.toUpperCase()) return;

    double delta;
    if (item.isInvestmentBill) {
      // Buying investments spends funds; selling investments receives funds.
      delta = item.isInvestmentSell ? item.amount : -item.amount;
    } else {
      delta = item.isIncome ? item.amount : -item.amount;
    }
    if (reverse) {
      delta = -delta;
    }

    asset.quantity += delta;
    if (asset.quantity.abs() < 0.000000001) {
      asset.quantity = 0;
    }
    assets[index] = asset;
  }

  void _applyBillInvestmentEffect(BillItem item, {bool reverse = false}) {
    if (item.investmentAssetId.trim().isEmpty || item.investmentQuantity <= 0) return;

    final index = assets.indexWhere((asset) => asset.id == item.investmentAssetId && asset.isInvestment);
    if (index < 0) return;

    final asset = assets[index];

    double delta;
    if (item.isInvestmentBill) {
      // Investment bill: buy increases holdings, sell reduces holdings.
      delta = item.isInvestmentSell ? -item.investmentQuantity : item.investmentQuantity;
    } else {
      // Backward compatibility: old expense+investment means buy, income+investment means sell.
      delta = item.isIncome ? -item.investmentQuantity : item.investmentQuantity;
    }
    if (reverse) {
      delta = -delta;
    }

    asset.quantity += delta;
    if (asset.quantity.abs() < 0.000000001) {
      asset.quantity = 0;
    }
    assets[index] = asset;
  }

  void setBillMonth(DateTime month) {
    selectedBillMonth.value = DateTime(month.year, month.month);
    _touchBills();
    update();
  }

  void setMainTab(int index) {
    selectedMainTab.value = index.clamp(0, 1).toInt();
    update();
  }

  void setAssetTab(int index) {
    selectedAssetTab.value = index.clamp(0, 2).toInt();
    update();
  }

  List<BillItem> get monthlyBills {
    billsVersion.value;
    final month = selectedBillMonth.value;
    final list = bills
        .where((e) => e.occurredAt.year == month.year && e.occurredAt.month == month.month)
        .toList();
    list.sort((a, b) => b.occurredAt.compareTo(a.occurredAt));
    return list;
  }

  /// 月度汇总只统计真实收入/支出。
  /// 理财买入/卖出、换汇属于资产内部转换，会显示在账单列表里，但不计入收入、支出、结余。
  List<BillItem> get monthlyIncomeExpenseBills => monthlyBills
      .where((e) => e.isIncome || e.isExpense)
      .toList(growable: false);

  double get monthlyIncomeTotal => monthlyIncomeExpenseBills
      .where((e) => e.isIncome)
      .fold<double>(0, (sum, item) => sum + _billAmountInDefaultCurrency(item));

  double get monthlyExpenseTotal => monthlyIncomeExpenseBills
      .where((e) => e.isExpense)
      .fold<double>(0, (sum, item) => sum + _billAmountInDefaultCurrency(item));

  double get monthlyBillNet => monthlyIncomeTotal - monthlyExpenseTotal;

  /// 将账单金额统一折算到默认估值货币后汇总。
  /// 之前这里只统计与默认货币相同的账单，所以 EUR/USD 账单会显示 0。
  /// 现在优先使用账单绑定的现金资产汇率；没有绑定时，使用同币种现金资产的估值汇率。
  /// 如果确实没有任何可用汇率，才跳过该笔，避免把不同币种直接相加。
  double _billAmountInDefaultCurrency(BillItem item) {
    final sourceCurrency = item.currency.toUpperCase();
    final targetCurrency = settings.defaultCurrency.toUpperCase();
    if (sourceCurrency == targetCurrency) {
      return item.amount;
    }

    final rate = _fxRateForCurrency(sourceCurrency, preferredAssetId: item.assetId);
    if (rate == null || rate <= 0) {
      return 0;
    }
    return item.amount * rate;
  }

  double? _fxRateForCurrency(String sourceCurrency, {String preferredAssetId = ''}) {
    final source = sourceCurrency.toUpperCase();
    final target = settings.defaultCurrency.toUpperCase();
    if (source == target) return 1;

    final candidates = <AssetItem>[];
    if (preferredAssetId.trim().isNotEmpty) {
      candidates.addAll(assets.where((asset) =>
          asset.id == preferredAssetId &&
          asset.type == 'cash' &&
          asset.currency.toUpperCase() == source));
    }
    candidates.addAll(assets.where((asset) =>
        asset.type == 'cash' &&
        asset.currency.toUpperCase() == source &&
        !candidates.any((existing) => existing.id == asset.id)));

    for (final asset in candidates) {
      final rate = _cashAssetFxRate(asset);
      if (rate != null && rate > 0) return rate;
    }
    return null;
  }

  double? _cashAssetFxRate(AssetItem asset) {
    final valued = valuationAsset(asset.id);
    final directPrice = _asDouble(valued?['price']);
    if (directPrice != null && directPrice > 0) {
      return directPrice;
    }

    final value = _asDouble(valued?['value']);
    if (value != null && asset.quantity.abs() > 0.000000001) {
      return value / asset.quantity;
    }
    return null;
  }

  double get fundsTotal => _assetGroupTotal(investment: false);

  double get investmentTotal => _assetGroupTotal(investment: true);

  double _assetGroupTotal({required bool investment}) {
    var total = 0.0;
    for (final item in assets.where((asset) => asset.isInvestment == investment)) {
      final value = numFromPath(valuationAsset(item.id), ['value']) ?? _localAssetValue(item);
      total += value;
    }
    return total;
  }

  double _localAssetValue(AssetItem item) {
    final currency = settings.defaultCurrency;
    if (item.type == 'cash' && item.currency == currency) {
      return item.quantity;
    }
    if (item.type == 'manual' && item.currency == currency) {
      return item.quantity * item.manualPrice;
    }
    return 0;
  }

  /// Assets that can be linked to bills.
  /// Bills are everyday income/expense records, so they should affect cash/bank style assets only.
  List<AssetItem> get billLinkedAssets =>
      assets.where((item) => item.type == 'cash').toList(growable: false);

  List<AssetItem> get billLinkedInvestments =>
      assets.where((item) => item.isInvestment).toList(growable: false);

  void reorderAssets({required bool investment, required int oldIndex, required int newIndex}) {
    final group = assets.where((item) => item.isInvestment == investment).toList(growable: true);
    if (oldIndex < 0 || oldIndex >= group.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    newIndex = newIndex.clamp(0, group.length - 1).toInt();
    final moved = group.removeAt(oldIndex);
    group.insert(newIndex, moved);

    var cursor = 0;
    final rebuilt = assets.map((item) {
      if (item.isInvestment == investment) {
        return group[cursor++];
      }
      return item;
    }).toList(growable: false);
    assets.assignAll(rebuilt);
    save();
    update();
  }

  void reorderDebts(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= debts.length) return;
    if (newIndex > oldIndex) newIndex -= 1;
    newIndex = newIndex.clamp(0, debts.length - 1).toInt();
    final items = debts.toList(growable: true);
    final moved = items.removeAt(oldIndex);
    items.insert(newIndex, moved);
    debts.assignAll(items);
    save();
    update();
  }

  Future<void> addAsset(AssetItem item) async {
    assets.insert(0, item);
    _syncValuationAfterLocalChange();
    await save();
    update();
  }

  Future<void> addInvestmentWithFunding({
    required AssetItem investment,
    required String fundAssetId,
    required double fundAmount,
  }) async {
    AssetItem? fund;
    for (final asset in assets) {
      if (asset.id == fundAssetId && asset.type == 'cash') {
        fund = asset;
        break;
      }
    }
    assets.insert(0, investment);

    if (fund != null && fundAmount > 0) {
      final bill = BillItem(
        id: _newBillIdForInvestment(investment.id),
        type: 'investment',
        category: 'investmentBuy',
        amount: fundAmount,
        currency: fund.currency,
        assetId: fund.id,
        assetName: fund.name,
        investmentAssetId: investment.id,
        investmentAssetName: investment.name,
        investmentQuantity: investment.quantity,
        note: investment.note,
      );
      bills.insert(0, bill);
      selectedBillMonth.value = DateTime(bill.occurredAt.year, bill.occurredAt.month);
      _applyBillFundEffect(bill);
      _touchBills();
    }

    _syncValuationAfterLocalChange();
    await save();
    update();
  }

  String _newBillIdForInvestment(String investmentId) => 'bill_$investmentId';

  Future<void> updateAsset(AssetItem item) async {
    final index = assets.indexWhere((e) => e.id == item.id);
    if (index >= 0) {
      assets[index] = item;
    } else {
      assets.insert(0, item);
    }
    _syncValuationAfterLocalChange();
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
    _syncValuationAfterLocalChange();
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
    _syncValuationAfterLocalChange();
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
          valuation = _buildValuationPreservingExisting();
          lastError = 'refreshTimeoutError'.tr;
          isRefreshing = false;
          showRefreshSpinner = false;
          await save();
          update();
        }
      },
    ).catchError((Object error, StackTrace stackTrace) async {
      if (refreshId == _refreshSequence) {
        valuation = _buildValuationPreservingExisting();
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

      valuation = _mergeRemoteValuationWithPrevious(remoteValuation);
      lastError = null;
      await save();
    } catch (e) {
      if (refreshId != _refreshSequence || _timedOutRefreshes.contains(refreshId)) {
        return;
      }

      // API 失败时保留本地可计算估值，不影响继续记账。
      valuation = _buildValuationPreservingExisting();
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


  Map<String, dynamic> _mergeRemoteValuationWithPrevious(Map<String, dynamic> remote) {
    final previous = valuation;
    if (previous == null) return remote;

    final previousAssets = _mapValuationItemsById(previous['assets']);
    final previousLiabilities = _mapValuationItemsById(previous['liabilities']);

    final remoteAssets = _valuationItemList(remote['assets']);
    final remoteAssetIds = remoteAssets
        .map((item) => item['id']?.toString())
        .whereType<String>()
        .toSet();
    final failedAssets = _valuationItemList(remote['failedAssets']);
    final remainingFailedAssets = <Map<String, dynamic>>[];

    for (final failed in failedAssets) {
      final id = failed['id']?.toString();
      if (id == null) {
        remainingFailedAssets.add(failed);
        continue;
      }

      final previousItem = previousAssets[id];
      if (_hasUsableValuationValue(previousItem)) {
        if (!remoteAssetIds.contains(id)) {
          remoteAssets.add({
            ...previousItem!,
            'preserved': true,
            'stale': true,
            'provider': '${previousItem['provider'] ?? 'previous'} · preserved',
          });
          remoteAssetIds.add(id);
        }
      } else {
        remainingFailedAssets.add(failed);
      }
    }

    final remoteLiabilities = _valuationItemList(remote['liabilities']);
    final remoteLiabilityIds = remoteLiabilities
        .map((item) => item['id']?.toString())
        .whereType<String>()
        .toSet();
    final failedLiabilities = _valuationItemList(remote['failedLiabilities']);
    final remainingFailedLiabilities = <Map<String, dynamic>>[];

    for (final failed in failedLiabilities) {
      final id = failed['id']?.toString();
      if (id == null) {
        remainingFailedLiabilities.add(failed);
        continue;
      }

      final previousItem = previousLiabilities[id];
      if (_hasUsableValuationValue(previousItem)) {
        if (!remoteLiabilityIds.contains(id)) {
          remoteLiabilities.add({
            ...previousItem!,
            'preserved': true,
            'stale': true,
            'provider': '${previousItem['provider'] ?? 'previous'} · preserved',
          });
          remoteLiabilityIds.add(id);
        }
      } else {
        remainingFailedLiabilities.add(failed);
      }
    }

    final assetTotal = remoteAssets.fold<double>(
        0, (sum, item) => sum + (_asDouble(item['value']) ?? 0));
    final receivableTotal = remoteLiabilities
        .where((item) => item['direction'] == 'receivable')
        .fold<double>(0, (sum, item) => sum + (_asDouble(item['value']) ?? 0));
    final payableTotal = remoteLiabilities
        .where((item) => item['direction'] == 'payable')
        .fold<double>(0, (sum, item) => sum + (_asDouble(item['value']) ?? 0));

    return {
      ...remote,
      'totals': {
        ...?((remote['totals'] as Map?)?.cast<String, dynamic>()),
        'assetTotal': assetTotal,
        'receivableTotal': receivableTotal,
        'payableTotal': payableTotal,
        'netWorth': assetTotal + receivableTotal - payableTotal,
      },
      'assets': remoteAssets,
      'liabilities': remoteLiabilities,
      'failedAssets': remainingFailedAssets,
      'failedLiabilities': remainingFailedLiabilities,
    };
  }

  Map<String, Map<String, dynamic>> _mapValuationItemsById(dynamic source) {
    final result = <String, Map<String, dynamic>>{};
    if (source is! List) return result;
    for (final item in source) {
      if (item is Map && item['id'] != null) {
        result[item['id'].toString()] = item.cast<String, dynamic>();
      }
    }
    return result;
  }

  List<Map<String, dynamic>> _valuationItemList(dynamic source) {
    if (source is! List) return <Map<String, dynamic>>[];
    return source
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList(growable: true);
  }

  bool _hasUsableValuationValue(Map<String, dynamic>? item) {
    final value = _asDouble(item?['value']);
    return value != null && value.isFinite;
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
      final previousQuantity = previous == null ? null : _asDouble(previous['quantity']);
      String quoteCurrency = (previous?['quoteCurrency'] as String?) ?? item.currency;

      // 离线或接口失败时，优先沿用上一轮成功刷新保存下来的估值。
      // 如果用户只是修改了数量，则按上一轮单位估值等比例换算，避免断网后理财金额直接归零。
      if (value != null && previousQuantity != null && previousQuantity > 0 && item.quantity != previousQuantity) {
        value = value / previousQuantity * item.quantity;
      }

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
      final previousAmount = previous == null ? null : _asDouble(previous['amount']);
      if (value != null && previousAmount != null && previousAmount > 0 && item.amount != previousAmount) {
        value = value / previousAmount * item.amount;
      }
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
      'failedAssets': [],
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
