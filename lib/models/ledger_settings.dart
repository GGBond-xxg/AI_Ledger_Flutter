import '../core/app_constants.dart';

class LedgerSettings {
  LedgerSettings({
    this.apiBaseUrl = '',
    this.apiToken = '',
    this.defaultCurrency = 'CNY',
    this.themeMode = 'system',
    this.languageMode = 'system',
    this.appLockEnabled = false,
    this.appLockMethod = 'none',
    this.appBiometricsEnabled = false,
    this.appPinSalt = '',
    this.appPinHash = '',
    this.appLockFailedAttempts = 0,
    this.showZeroItems = false,
    this.assetSortAscending = false,
  });

  String apiBaseUrl;
  String apiToken;
  String defaultCurrency;

  /// system / light / dark
  String themeMode;

  /// system / zh / zh_Hant / en
  String languageMode;

  /// false = 不启用密码锁。
  bool appLockEnabled;

  /// none / device / pin
  ///
  /// 兼容旧数据使用；新逻辑里 device 表示「6 位密码 + 生物识别」。
  String appLockMethod;

  /// 是否开启设备生物识别。生物识别必须建立在 6 位 App 密码之上，避免指纹/Face ID 失效后无法进入。
  bool appBiometricsEnabled;

  /// App 独立 6 位数字密码使用 salt + sha256 hash 保存，不保存明文密码。
  String appPinSalt;
  String appPinHash;

  /// 独立密码输错次数。达到 8 次会清空本地数据。
  int appLockFailedAttempts;

  /// 资产页是否显示数量/金额为 0 的资金、理财、借款记录。默认隐藏。
  bool showZeroItems;

  /// 资产页排序方向。false = 默认从大到小，true = 从小到大。
  bool assetSortAscending;

  bool get hasPin => appPinSalt.trim().isNotEmpty && appPinHash.trim().isNotEmpty;
  bool get useDeviceLock => appLockEnabled && appBiometricsEnabled && hasPin;
  bool get usePinLock => appLockEnabled && hasPin;

  factory LedgerSettings.fromJson(Map<String, dynamic> json) {
    final apiBase = (json['apiBaseUrl'] as String?)?.trim();
    final theme = (json['themeMode'] as String?)?.trim();
    final language = (json['languageMode'] as String?)?.trim();
    final method = (json['appLockMethod'] as String?)?.trim();
    final enabled = json['appLockEnabled'] == true;
    final pinSalt = (json['appPinSalt'] as String?) ?? '';
    final pinHash = (json['appPinHash'] as String?) ?? '';
    final hasPin = pinSalt.isNotEmpty && pinHash.isNotEmpty;
    final requestedBiometrics = json['appBiometricsEnabled'] == true || method == 'device';
    final safeMethod = ['none', 'device', 'pin'].contains(method) ? method! : 'none';

    // 新规则：任何密码锁都必须有 6 位 App 密码。旧版本可能存在只有生物识别、没有 PIN 的数据，
    // 这种情况自动降级为未开启，避免指纹/Face ID 失效后无法进入 App。
    final safeEnabled = enabled && safeMethod != 'none' && hasPin;
    final safeBiometrics = safeEnabled && requestedBiometrics;

    return LedgerSettings(
      apiBaseUrl: apiBase == null || apiBase.isEmpty || apiBase == kDefaultApiBaseUrl ? '' : apiBase,
      apiToken: (json['apiToken'] as String?) ?? '',
      defaultCurrency: (json['defaultCurrency'] as String?)?.toUpperCase() ?? 'CNY',
      themeMode: ['system', 'light', 'dark'].contains(theme) ? theme! : 'system',
      languageMode: ['system', 'zh', 'zh_Hant', 'en'].contains(language) ? language! : 'system',
      appLockEnabled: safeEnabled,
      appLockMethod: safeEnabled ? (safeBiometrics ? 'device' : 'pin') : 'none',
      appBiometricsEnabled: safeBiometrics,
      appPinSalt: pinSalt,
      appPinHash: pinHash,
      appLockFailedAttempts: ((json['appLockFailedAttempts'] as num?)?.toInt().clamp(0, 8) ?? 0).toInt(),
      showZeroItems: json['showZeroItems'] == true,
      assetSortAscending: json['assetSortAscending'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'apiBaseUrl': apiBaseUrl,
        'apiToken': apiToken,
        'defaultCurrency': defaultCurrency,
        'themeMode': themeMode,
        'languageMode': languageMode,
        'appLockEnabled': appLockEnabled,
        'appLockMethod': appLockMethod,
        'appBiometricsEnabled': appBiometricsEnabled,
        'appPinSalt': appPinSalt,
        'appPinHash': appPinHash,
        'appLockFailedAttempts': appLockFailedAttempts,
        'showZeroItems': showZeroItems,
        'assetSortAscending': assetSortAscending,
      };

  LedgerSettings copyWith({
    String? apiBaseUrl,
    String? apiToken,
    String? defaultCurrency,
    String? themeMode,
    String? languageMode,
    bool? appLockEnabled,
    String? appLockMethod,
    bool? appBiometricsEnabled,
    String? appPinSalt,
    String? appPinHash,
    int? appLockFailedAttempts,
    bool? showZeroItems,
    bool? assetSortAscending,
  }) {
    return LedgerSettings(
      apiBaseUrl: apiBaseUrl ?? this.apiBaseUrl,
      apiToken: apiToken ?? this.apiToken,
      defaultCurrency: defaultCurrency ?? this.defaultCurrency,
      themeMode: themeMode ?? this.themeMode,
      languageMode: languageMode ?? this.languageMode,
      appLockEnabled: appLockEnabled ?? this.appLockEnabled,
      appLockMethod: appLockMethod ?? this.appLockMethod,
      appBiometricsEnabled: appBiometricsEnabled ?? this.appBiometricsEnabled,
      appPinSalt: appPinSalt ?? this.appPinSalt,
      appPinHash: appPinHash ?? this.appPinHash,
      appLockFailedAttempts: appLockFailedAttempts ?? this.appLockFailedAttempts,
      showZeroItems: showZeroItems ?? this.showZeroItems,
      assetSortAscending: assetSortAscending ?? this.assetSortAscending,
    );
  }
}
