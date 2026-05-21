import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import '../l10n/translation_service.dart';
import '../screens/home_page.dart';
import '../screens/lock_screen.dart';
import '../services/ledger_store.dart';
import 'app_theme.dart';

class PersonalLedgerApp extends StatefulWidget {
  const PersonalLedgerApp({super.key, required this.translations});

  final TranslationService translations;

  @override
  State<PersonalLedgerApp> createState() => _PersonalLedgerAppState();
}

class _PersonalLedgerAppState extends State<PersonalLedgerApp> with WidgetsBindingObserver {
  final LedgerStore store = Get.find<LedgerStore>();
  bool _wasBackgrounded = false;
  Timer? _inactivePrivacyTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    _inactivePrivacyTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    super.didChangeLocales(locales);
    if (store.settings.languageMode == 'system') {
      Get.updateLocale(TranslationService.currentDeviceLocale());
    }
  }


  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    // 生物识别弹窗会触发 inactive/paused，不能在这个阶段反复锁定，否则会出现指纹/Face ID 循环弹出。
    if (store.unlockPromptActive) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Android 进入多任务/切后台前会先触发 inactive。
      // 这里先显示一层隐私锁屏快照，让系统任务卡片尽量截到锁屏，而不是资产金额。
      // 如果只是下拉状态栏、截图、系统弹窗，resumed 时会立即清掉这层快照，不要求解锁。
      store.showPrivacySnapshotOnly();
      return;
    }

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _inactivePrivacyTimer?.cancel();
      _wasBackgrounded = true;
      store.preparePrivacySnapshot();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      _inactivePrivacyTimer?.cancel();
      if (_wasBackgrounded) {
        store.markAppForegrounded();
        _wasBackgrounded = false;
      } else {
        store.markAppStillForegrounded();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() => GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Ledger',
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: _themeMode(store.settings.themeMode),
      translations: widget.translations,
      locale: TranslationService.localeFromMode(store.settings.languageMode),
      fallbackLocale: TranslationService.fallbackLocale,
      supportedLocales: TranslationService.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppLockGate(child: HomePage()),
    ));
  }

  ThemeMode _themeMode(String mode) {
    return switch (mode) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }
}
