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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
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

    // Android/iOS 进入多任务界面前会先进入 inactive/paused。
    // 如果用户开启了密码锁，这里要尽早切到锁屏 UI，避免系统任务卡片截到资产金额。
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _wasBackgrounded = true;
      store.preparePrivacySnapshot();
      return;
    }

    if (state == AppLifecycleState.resumed) {
      store.markAppForegrounded();
      if (_wasBackgrounded) {
        _wasBackgrounded = false;
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
