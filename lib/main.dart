import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'app/personal_ledger_app.dart';
import 'l10n/translation_service.dart';
import 'services/ledger_store.dart';
import 'services/quote_api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final translations = await TranslationService.load();
  final store = Get.put(LedgerStore(apiService: QuoteApiService()), permanent: true);
  await store.load();
  store.initializeAppLockState();

  runApp(PersonalLedgerApp(translations: translations));
}
