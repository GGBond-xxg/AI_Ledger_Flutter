import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:file_picker/file_picker.dart';

import '../app/app_theme.dart';
import '../core/app_constants.dart';
import '../core/formatters.dart';
import '../core/app_toast.dart';
import '../data/about_catalog.dart';
import '../services/ledger_store.dart';
import '../widgets/common_cards.dart';
import '../widgets/form_fields.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  static const _maskedApiToken = '******';

  final LedgerStore store = Get.find<LedgerStore>();
  late final TextEditingController _apiBaseController;
  late final TextEditingController _tokenController;
  late String _currency;
  late String _themeMode;
  late String _languageMode;
  late bool _useDynamicColors;
  bool _testing = false;
  final RxInt _uiVersion = 0.obs;

  void _refreshUi() => _uiVersion.value++;

  @override
  void initState() {
    super.initState();
    _apiBaseController = TextEditingController(text: store.settings.apiBaseUrl);
    _tokenController = TextEditingController(text: store.settings.apiToken.trim().isEmpty ? '' : _maskedApiToken);
    _currency = store.settings.defaultCurrency;
    _themeMode = store.settings.themeMode;
    _languageMode = store.settings.languageMode;
    _useDynamicColors = store.settings.useDynamicColors;
  }

  @override
  void dispose() {
    _apiBaseController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      _uiVersion.value;
      return Scaffold(
        backgroundColor: AppTheme.pageBackground(context),
        appBar: AppBar(
          centerTitle: false,
          backgroundColor: AppTheme.pageBackground(context),
          title: Text('settings'.tr),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
            child: Column(
              children: [
                FormCard(
                  children: [
                    LedgerDropdownField<String>(
                      label: 'themeMode'.tr,
                      value: _themeMode,
                      items: [
                        DropdownMenuItem(
                            value: 'system', child: Text('system'.tr)),
                        DropdownMenuItem(
                            value: 'light', child: Text('light'.tr)),
                        DropdownMenuItem(value: 'dark', child: Text('dark'.tr)),
                      ],
                      onChanged: (value) {
                        _themeMode = value ?? _themeMode;
                        _refreshUi();
                      },
                    ),
                    LedgerDropdownField<String>(
                      label: 'language'.tr,
                      value: _languageMode,
                      items: [
                        DropdownMenuItem(
                            value: 'system', child: Text('system'.tr)),
                        DropdownMenuItem(
                            value: 'zh', child: Text('chinese'.tr)),
                        DropdownMenuItem(
                            value: 'zh_Hant',
                            child: Text('traditionalChinese'.tr)),
                        DropdownMenuItem(
                            value: 'en', child: Text('english'.tr)),
                      ],
                      onChanged: (value) {
                        _languageMode = value ?? _languageMode;
                        _refreshUi();
                      },
                    ),
                    _SwitchRow(
                      icon: Icons.palette_rounded,
                      title: 'useDynamicColors'.tr,
                      subtitle: 'useDynamicColorsDesc'.tr,
                      value: _useDynamicColors,
                      onChanged: (value) {
                        _useDynamicColors = value;
                        _refreshUi();
                      },
                    ),
                    LedgerDropdownField<String>(
                      label: 'defaultCurrency'.tr,
                      value: _currency,
                      items: kCurrencies
                          .map(
                              (e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (value) {
                        _currency = value ?? _currency;
                        _refreshUi();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FormCard(
                  children: [
                    LedgerTextField(
                      controller: _apiBaseController,
                      label: 'apiBaseUrl'.tr,
                      hint: 'apiBaseUrlHint'.tr,
                    ),
                    LedgerTextField(
                      controller: _tokenController,
                      label: 'apiToken'.tr,
                      hint: 'apiTokenHint'.tr,
                      obscureText: _tokenController.text == _maskedApiToken,
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _save,
                          icon: const Icon(Icons.save_rounded),
                          label: Text('saveSettings'.tr),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: OutlinedButton.icon(
                          onPressed: _testing ? null : _testApi,
                          icon: _testing
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.network_check_rounded),
                          label: Text('testApi'.tr),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FormCard(
                  children: [
                    _ActionRow(
                      icon: Icons.lock_rounded,
                      title: 'appLock'.tr,
                      subtitle: _appLockSubtitle(),
                      onTap: _showAppLockDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FormCard(
                  children: [
                    _ActionRow(
                      icon: Icons.copy_rounded,
                      title: 'exportBackup'.tr,
                      subtitle: 'exportBackupDesc'.tr,
                      onTap: _exportBackup,
                    ),
                    const Divider(height: 1),
                    _ActionRow(
                      icon: Icons.paste_rounded,
                      title: 'importBackup'.tr,
                      subtitle: 'importBackupDesc'.tr,
                      onTap: _showImportDialog,
                    ),
                    const Divider(height: 1),
                    _ActionRow(
                      icon: Icons.info_outline_rounded,
                      title: 'aboutUs'.tr,
                      subtitle: 'aboutUsDesc'.tr,
                      onTap: _showAboutDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'privacyNote'.tr,
                  style: TextStyle(
                      color: Theme.of(context).hintColor, height: 1.45),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Future<void> _save({bool showToast = true}) async {
    FocusManager.instance.primaryFocus?.unfocus();
    Get.closeAllSnackbars();

    final normalizedApiBaseUrl = normalizeBaseUrl(_apiBaseController.text);
    if (_apiBaseController.text.trim() != normalizedApiBaseUrl) {
      _apiBaseController.text = normalizedApiBaseUrl;
    }

    final inputToken = _tokenController.text.trim();
    final nextToken = inputToken == _maskedApiToken ? store.settings.apiToken : inputToken;
    final settings = store.settings.copyWith(
      apiBaseUrl: normalizedApiBaseUrl,
      apiToken: nextToken,
      defaultCurrency: _currency,
      themeMode: _themeMode,
      languageMode: _languageMode,
      useDynamicColors: _useDynamicColors,
    );
    await store.updateSettings(settings);
    if (mounted) {
      _tokenController.text = nextToken.trim().isEmpty ? '' : _maskedApiToken;
    }
    if (mounted && showToast) _toast('settingsSaved'.tr);
    unawaited(store
        .refreshValuation(force: true, source: 'settingsSaved')
        .catchError((_) {}));
  }

  Future<void> _testApi() async {
    await _save(showToast: false);
    if (!mounted) return;
    _testing = true;
    _refreshUi();
    try {
      final ok = await store.testApi();
      if (mounted) _toast(ok ? 'apiTestSuccess'.tr : 'apiTestFailed'.tr);
    } catch (e) {
      if (mounted) {
        _toast(e.toString().replaceFirst('Exception: ', ''),
            title: 'apiTestFailed'.tr, icon: Icons.error_outline_rounded);
      }
    } finally {
      if (mounted) {
        _testing = false;
        _refreshUi();
      }
    }
  }

  String _appLockSubtitle() {
    if (!store.settings.appLockEnabled) return 'appLockDisabled'.tr;
    if (store.settings.useDeviceLock) return 'appLockDeviceEnabled'.tr;
    if (store.settings.usePinLock) return 'appLockPinEnabled'.tr;
    return 'appLockDisabled'.tr;
  }

  Future<void> _showAppLockDialog() async {
    FocusManager.instance.primaryFocus?.unfocus();
    Get.closeAllSnackbars();

    await Get.dialog<void>(
      AlertDialog(
        title: Text('appLock'.tr),
        content: Obx(() => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('appLockDesc'.tr,
                    style: TextStyle(
                        color: Theme.of(context).hintColor, height: 1.45)),
                const SizedBox(height: 16),
                _SecurityOptionTile(
                  icon: Icons.fingerprint_rounded,
                  title: 'useDeviceBiometrics'.tr,
                  subtitle: 'useDeviceBiometricsDesc'.tr,
                  selected: store.settings.useDeviceLock,
                  onTap: _enableDeviceLock,
                ),
                const SizedBox(height: 10),
                _SecurityOptionTile(
                  icon: Icons.pin_rounded,
                  title: 'useSixDigitPin'.tr,
                  subtitle: 'useSixDigitPinDesc'.tr,
                  selected: store.settings.usePinLock,
                  onTap: () => _showSetPinDialog(),
                ),
                if (store.settings.appLockEnabled) ...[
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _disableAppLock,
                        icon: const Icon(Icons.lock_open_rounded),
                        label: Text('disableAppLock'.tr),
                      ),
                    ),
                  ),
                ],
              ],
            )),
        actions: [
          TextButton(onPressed: () => Get.back<void>(), child: Text('done'.tr)),
        ],
      ),
    );
  }

  Future<void> _enableDeviceLock() async {
    try {
      if (!store.settings.hasPin) {
        _toast('pinRequiredBeforeBiometrics'.tr,
            title: 'appLock'.tr, icon: Icons.pin_rounded);
        final pinCreated = await _showSetPinDialog(
            successToastKey: 'pinSetBeforeBiometricsToast');
        if (!pinCreated || !mounted) return;
      }

      final auth = LocalAuthentication();
      final canCheck = await auth.canCheckBiometrics;
      final biometrics = await auth.getAvailableBiometrics();
      if (!mounted) return;
      if (!canCheck || biometrics.isEmpty) {
        _toast('deviceBiometricsUnavailable'.tr,
            title: 'appLock'.tr, icon: Icons.error_outline_rounded);
        return;
      }

      final ok = await auth.authenticate(
        localizedReason: 'biometricSetupReason'.tr,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          useErrorDialogs: true,
        ),
      );
      if (!ok) return;
      await store.enableDeviceAppLock();
      if (mounted) {
        _toast('biometricLockEnabled'.tr, icon: Icons.fingerprint_rounded);
      }
    } catch (e) {
      if (mounted) {
        _toast('deviceBiometricsUnavailable'.tr,
            title: 'appLock'.tr, icon: Icons.error_outline_rounded);
      }
    }
  }

  Future<bool> _showSetPinDialog(
      {String successToastKey = 'appLockEnabled'}) async {
    final result = await Get.dialog<List<String>>(
      const _SetPinDialog(),
      barrierDismissible: false,
    );

    if (result == null) return false;
    final pin = result[0];
    final confirm = result[1];
    if (!RegExp(r'^\d{6}$').hasMatch(pin)) {
      _toast('pinMustBeSixDigits'.tr,
          title: 'appLock'.tr, icon: Icons.error_outline_rounded);
      return false;
    }
    if (pin != confirm) {
      _toast('pinConfirmMismatch'.tr,
          title: 'appLock'.tr, icon: Icons.error_outline_rounded);
      return false;
    }
    await store.enablePinAppLock(pin,
        keepBiometrics: store.settings.appBiometricsEnabled);
    if (mounted) _toast(successToastKey.tr, icon: Icons.lock_rounded);
    return true;
  }

  Future<void> _disableAppLock() async {
    await store.disableAppLock();
    if (mounted) {
      _toast('appLockDisabledToast'.tr, icon: Icons.lock_open_rounded);
    }
  }

  Future<void> _exportBackup() async {
    FocusManager.instance.primaryFocus?.unfocus();
    Get.closeAllSnackbars();

    final action = await Get.dialog<String>(
      AlertDialog(
        title: Text('exportBackup'.tr),
        content: Text('exportBackupDesc'.tr),
        actions: [
          TextButton(
              onPressed: () => Get.back<void>(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () => Get.back(result: 'copy'),
            child: Text('copyBackupToClipboard'.tr),
          ),
          FilledButton(
            onPressed: () => Get.back(result: 'file'),
            child: Text('saveBackupFile'.tr),
          ),
        ],
      ),
    );

    if (action == 'copy') {
      await Clipboard.setData(ClipboardData(text: store.exportJson()));
      if (mounted) _toast('backupCopied'.tr);
    } else if (action == 'file') {
      await _saveBackupFile();
    }
  }

  Future<void> _saveBackupFile() async {
    try {
      final json = store.exportJson();
      final bytes = Uint8List.fromList(utf8.encode(json));
      final filename = 'ledger_backup_${_backupTimestamp()}.json';
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'exportBackup'.tr,
        fileName: filename,
        type: FileType.custom,
        allowedExtensions: const ['json'],
        bytes: bytes,
      );
      if (path == null) return;
      if (mounted) _toast('backupSaved'.tr);
    } catch (e) {
      if (mounted) {
        _toast('backupSaveFailed'.tr, icon: Icons.error_outline_rounded);
      }
    }
  }

  String _backupTimestamp() {
    final now = DateTime.now();
    String two(int value) => value.toString().padLeft(2, '0');
    return '${now.year}${two(now.month)}${two(now.day)}_${two(now.hour)}${two(now.minute)}${two(now.second)}';
  }

  Future<void> _showImportDialog() async {
    FocusManager.instance.primaryFocus?.unfocus();
    Get.closeAllSnackbars();

    final action = await Get.dialog<String>(
      AlertDialog(
        title: Text('importJsonBackup'.tr),
        content: Text('importBackupDesc'.tr),
        actions: [
          TextButton(
              onPressed: () => Get.back<void>(), child: Text('cancel'.tr)),
          TextButton(
            onPressed: () => Get.back(result: 'text'),
            child: Text('importFromClipboard'.tr),
          ),
          FilledButton(
            onPressed: () => Get.back(result: 'file'),
            child: Text('importFromFile'.tr),
          ),
        ],
      ),
    );

    if (action == 'file') {
      await _importBackupFromFile();
    } else if (action == 'text') {
      await _importBackupFromText();
    }
  }

  Future<void> _importBackupFromFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        dialogTitle: 'importJsonBackup'.tr,
        type: FileType.custom,
        allowedExtensions: const ['json', 'txt'],
        allowMultiple: false,
        withData: true,
      );
      final file = result?.files.single;
      if (file == null) return;
      final bytes = file.bytes ??
          (file.path == null ? null : await File(file.path!).readAsBytes());
      if (bytes == null || bytes.isEmpty) {
        throw Exception('fileEmpty'.tr);
      }
      await _importRawBackup(_decodeBackupBytes(bytes));
    } catch (e) {
      if (mounted) {
        _toast(_friendlyImportError(e),
            title: 'importFailedTitle'.tr, icon: Icons.error_outline_rounded);
      }
    }
  }

  Future<void> _importBackupFromText() async {
    final controller = TextEditingController();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    controller.text = data?.text ?? '';

    final raw = await Get.dialog<String>(
      AlertDialog(
        title: Text('importJsonBackup'.tr),
        content: TextField(
          controller: controller,
          minLines: 6,
          maxLines: 12,
          decoration: InputDecoration(hintText: 'pasteJson'.tr),
        ),
        actions: [
          TextButton(
              onPressed: () => Get.back<void>(), child: Text('cancel'.tr)),
          FilledButton(
              onPressed: () => Get.back(result: controller.text),
              child: Text('import'.tr)),
        ],
      ),
    );

    if (raw == null || raw.trim().isEmpty) return;
    await _importRawBackup(raw);
  }

  String _decodeBackupBytes(List<int> bytes) {
    if (bytes.length >= 3 &&
        bytes[0] == 0xEF &&
        bytes[1] == 0xBB &&
        bytes[2] == 0xBF) {
      return utf8.decode(bytes.sublist(3), allowMalformed: true);
    }
    return utf8.decode(bytes, allowMalformed: true);
  }

  Future<void> _importRawBackup(String raw) async {
    try {
      await store.importJson(raw);
      if (!mounted) return;
      _apiBaseController.text = store.settings.apiBaseUrl;
      _tokenController.text = store.settings.apiToken;
      _currency = store.settings.defaultCurrency;
      _themeMode = store.settings.themeMode;
      _languageMode = store.settings.languageMode;
      _useDynamicColors = store.settings.useDynamicColors;
      _refreshUi();
      _toast('importSuccess'.tr);
      unawaited(store
          .refreshValuation(force: true, source: 'importBackup')
          .catchError((_) {}));
    } catch (e) {
      if (mounted) {
        _toast(_friendlyImportError(e),
            title: 'importFailedTitle'.tr, icon: Icons.error_outline_rounded);
      }
    }
  }

  String _friendlyImportError(Object error) {
    final raw = error
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('FormatException: ', '')
        .trim();
    if (raw.isEmpty) return 'importFailedInvalidJson'.tr;
    return raw;
  }

  Future<void> _showAboutDialog() async {
    FocusManager.instance.primaryFocus?.unfocus();
    Get.closeAllSnackbars();

    await Get.dialog<void>(
      Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Material(
              color: Theme.of(context).cardColor,
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 10, 8),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primary
                                  .withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(Icons.menu_book_rounded,
                                color: Theme.of(context).colorScheme.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('aboutUs'.tr,
                                    style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900)),
                                const SizedBox(height: 2),
                                Text('appTitle'.tr,
                                    style: TextStyle(
                                        color: Theme.of(context).hintColor)),
                              ],
                            ),
                          ),
                          IconButton(
                              onPressed: () => Get.back<void>(),
                              icon: const Icon(Icons.close_rounded)),
                        ],
                      ),
                    ),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('aboutAppIntro'.tr,
                                style: TextStyle(
                                    color: Theme.of(context).hintColor,
                                    height: 1.45)),
                            const SizedBox(height: 18),
                            _AboutSectionTitle(title: 'usedTechnologies'.tr),
                            const SizedBox(height: 8),
                            ...kAboutLinks.map(
                              (item) => _AboutLinkRow(
                                title: item.title,
                                url: item.url,
                                description: item.descriptionKey?.tr,
                                onCopy: () => _copyToClipboard(item.url),
                              ),
                            ),
                            const SizedBox(height: 18),
                            _AboutSectionTitle(title: 'sponsorship'.tr),
                            const SizedBox(height: 8),
                            Text('sponsorshipDesc'.tr,
                                style: TextStyle(
                                    color: Theme.of(context).hintColor,
                                    height: 1.45)),
                            const SizedBox(height: 10),
                            ...kDonationAddresses.map(
                              (item) => _DonationRow(
                                chain: item.chain,
                                address: item.address,
                                onCopy: item.address.trim().isEmpty
                                    ? null
                                    : () => _copyToClipboard(item.address),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text('donationAddressHint'.tr,
                                style: TextStyle(
                                    color: Theme.of(context).hintColor,
                                    fontSize: 12,
                                    height: 1.4)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    _toast('copiedToClipboard'.tr);
  }

  void _toast(String message,
      {String? title, IconData icon = Icons.info_rounded}) {
    showAppToast(message, title: title, icon: icon);
  }
}

class _SecurityOptionTile extends StatelessWidget {
  const _SecurityOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.10)
              : Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.45),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.35)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).hintColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(
                          color: Theme.of(context).hintColor,
                          fontSize: 12.5,
                          height: 1.35)),
                ],
              ),
            ),
            if (selected)
              Icon(Icons.check_circle_rounded,
                  color: Theme.of(context).colorScheme.primary),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 8),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 3),
                Text(subtitle,
                    style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 13,
                        height: 1.35)),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow(
      {required this.icon,
      required this.title,
      required this.subtitle,
      required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(height: 3),
                  Text(subtitle,
                      style: TextStyle(
                          color: Theme.of(context).hintColor, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Theme.of(context).hintColor),
          ],
        ),
      ),
    );
  }
}

class _AboutSectionTitle extends StatelessWidget {
  const _AboutSectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
    );
  }
}

class _SetPinDialog extends StatefulWidget {
  const _SetPinDialog();

  @override
  State<_SetPinDialog> createState() => _SetPinDialogState();
}

class _SetPinDialogState extends State<_SetPinDialog> {
  final TextEditingController _pinController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();

  @override
  void dispose() {
    _pinController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    Get.back<List<String>>(
        result: [_pinController.text, _confirmController.text]);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('setSixDigitPin'.tr),
      content: ConstrainedBox(
        constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.58),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('setSixDigitPinDesc'.tr,
                  style: TextStyle(
                      color: Theme.of(context).hintColor, height: 1.45)),
              const SizedBox(height: 14),
              TextField(
                controller: _pinController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                autofocus: true,
                decoration: InputDecoration(
                    labelText: 'sixDigitPin'.tr, counterText: ''),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6)
                ],
                onSubmitted: (_) => FocusScope.of(context).nextFocus(),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _confirmController,
                keyboardType: TextInputType.number,
                obscureText: true,
                maxLength: 6,
                decoration: InputDecoration(
                    labelText: 'confirmSixDigitPin'.tr, counterText: ''),
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6)
                ],
                onSubmitted: (_) => _submit(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Get.back<void>(), child: Text('cancel'.tr)),
        FilledButton(onPressed: _submit, child: Text('save'.tr)),
      ],
    );
  }
}

class _AboutLinkRow extends StatelessWidget {
  const _AboutLinkRow({
    required this.title,
    required this.url,
    required this.onCopy,
    this.description,
  });

  final String title;
  final String url;
  final String? description;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                if (description != null && description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(description!,
                      style: TextStyle(
                          color: Theme.of(context).hintColor, fontSize: 12.5)),
                ],
                const SizedBox(height: 5),
                SelectableText(
                  url,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filledTonal(
            tooltip: 'copyLink'.tr,
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}

class _DonationRow extends StatelessWidget {
  const _DonationRow(
      {required this.chain, required this.address, required this.onCopy});

  final String chain;
  final String address;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    final hasAddress = address.trim().isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(chain,
                style: const TextStyle(fontWeight: FontWeight.w900)),
          ),
          Expanded(
            child: SelectableText(
              hasAddress ? address : 'notConfigured'.tr,
              style: TextStyle(
                color: hasAddress
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).hintColor,
                fontSize: 12.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: 'copyAddress'.tr,
            onPressed: onCopy,
            icon: const Icon(Icons.copy_rounded, size: 18),
          ),
        ],
      ),
    );
  }
}
