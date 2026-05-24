import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/app_constants.dart';
import '../app/app_theme.dart';
import '../core/formatters.dart';
import '../l10n/translation_service.dart';
import '../core/id.dart';
import '../data/market_catalog.dart';
import '../models/asset_item.dart';
import '../models/market_option.dart';
import '../services/ledger_store.dart';
import '../widgets/common_cards.dart';
import '../widgets/form_fields.dart';

class AssetFormPage extends StatefulWidget {
  const AssetFormPage({
    super.key,
    required this.investmentDefault,
    this.existing,
  });

  final bool investmentDefault;
  final AssetItem? existing;

  @override
  State<AssetFormPage> createState() => _AssetFormPageState();
}

class _AssetFormPageState extends State<AssetFormPage> {
  final LedgerStore store = Get.find<LedgerStore>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  final _quantityController = TextEditingController();
  final _manualPriceController = TextEditingController();
  final _noteController = TextEditingController();

  late String _type = widget.existing?.type ?? (widget.investmentDefault ? 'stock' : 'cash');
  String _currency = 'CNY';
  String _unit = 'gram';
  String _lastEditedField = 'name';
  bool _applyingSuggestion = false;
  bool _searchingRemote = false;
  List<MarketOption> _remoteSuggestions = const [];
  Timer? _searchDebounce;
  final RxInt _uiVersion = 0.obs;

  void _refreshUi() => _uiVersion.value++;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _type = existing.type;
      _nameController.text = existing.name;
      _symbolController.text = existing.symbol;
      _quantityController.text = trimNum(existing.quantity);
      _manualPriceController.text = trimNum(existing.manualPrice == 0 ? 1 : existing.manualPrice);
      _noteController.text = existing.note;
      _currency = existing.currency;
      _unit = existing.unit.isEmpty ? 'gram' : existing.unit;
    } else if (widget.investmentDefault) {
      _currency = 'USD';
    }
    _scheduleRemoteSearch(immediate: true);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _nameController.dispose();
    _symbolController.dispose();
    _quantityController.dispose();
    _manualPriceController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  bool get _needsSymbol => ['crypto', 'metal', 'stock', 'etf', 'cn_stock', 'cn_etf'].contains(_type);
  bool get _needsMarketSuggestions => ['crypto', 'metal', 'stock', 'etf', 'cn_stock', 'cn_etf'].contains(_type);

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      _uiVersion.value;
      final needsManualPrice = _type == 'manual';
    final needsCurrency = ['cash', 'manual'].contains(_type);
    final suggestions = _marketSuggestions();

      return Scaffold(
      appBar: AppBar(title: Text(_title())),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FormCard(
                  children: [
                    LedgerDropdownField<String>(
                      label: 'type'.tr,
                      value: _type,
                      items: [
                        DropdownMenuItem(value: 'cash', child: Text('cashType'.tr)),
                        DropdownMenuItem(value: 'manual', child: Text('manualType'.tr)),
                        DropdownMenuItem(value: 'crypto', child: Text('cryptoType'.tr)),
                        DropdownMenuItem(value: 'metal', child: Text('metalType'.tr)),
                        DropdownMenuItem(value: 'stock', child: Text('stockType'.tr)),
                        DropdownMenuItem(value: 'etf', child: Text('etfType'.tr)),
                        DropdownMenuItem(value: 'cn_stock', child: Text('cnStockType'.tr)),
                        DropdownMenuItem(value: 'cn_etf', child: Text('cnEtfType'.tr)),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        _type = value;
                        _currency = (value == 'cash' || value == 'cn_stock' || value == 'cn_etf') ? 'CNY' : 'USD';
                        _unit = 'gram';
                        _lastEditedField = 'name';
                        _nameController.text = trDefaultName(value);
                        _symbolController.text = '';
                        _remoteSuggestions = const [];
                        _refreshUi();
                        _scheduleRemoteSearch(immediate: true);
                      },
                    ),
                    LedgerTextField(
                      controller: _nameController,
                      label: 'name'.tr,
                      hint: trNameHint(_type),
                      onChanged: (_) => _handleFieldChanged('name'),
                      validator: (value) => value == null || value.trim().isEmpty ? 'enterName'.tr : null,
                    ),
                    if (_needsSymbol)
                      LedgerTextField(
                        controller: _symbolController,
                        label: _type == 'crypto' ? 'cryptoSymbol'.tr : 'symbol'.tr,
                        hint: trSymbolHint(_type),
                        onChanged: (_) => _handleFieldChanged('symbol'),
                        validator: (value) => value == null || value.trim().isEmpty ? 'enterSymbol'.tr : null,
                      ),
                    if (_needsMarketSuggestions)
                      _MarketSuggestionBox(
                        type: _type,
                        suggestions: suggestions,
                        searching: _searchingRemote,
                        onSelected: _applyMarketOption,
                      ),
                    LedgerTextField(
                      controller: _quantityController,
                      label: _type == 'cash' ? 'amount'.tr  : 'quantity'.tr,
                      hint: _type == 'cash' ? 'amountHintCash'.tr  : 'quantityHint'.tr,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        final number = double.tryParse(value?.trim() ?? '');
                        if (number == null || number <= 0) return 'enterPositiveNumber'.tr;
                        return null;
                      },
                    ),
                    if (needsCurrency)
                      LedgerDropdownField<String>(
                        label: 'currency'.tr,
                        value: _currency,
                        items: kCurrencies.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                        onChanged: (value) { _currency = value ?? _currency; _refreshUi(); },
                      ),
                    if (_type == 'metal')
                      LedgerDropdownField<String>(
                        label: 'unit'.tr,
                        value: _unit,
                        items: kMetalUnits.map((e) => DropdownMenuItem(value: e, child: Text(trMetalUnit(e)))).toList(),
                        onChanged: (value) { _unit = value ?? _unit; _refreshUi(); },
                      ),
                    if (needsManualPrice)
                      LedgerTextField(
                        controller: _manualPriceController,
                        label: 'manualPrice'.tr,
                        hint: 'manualPriceHint'.tr,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          final number = double.tryParse(value?.trim() ?? '');
                          if (number == null || number < 0) return 'enterValidPrice'.tr;
                          return null;
                        },
                      ),
                    LedgerTextField(controller: _noteController, label: 'noteOptional'.tr, maxLines: 3),
                  ],
                ),
                const SizedBox(height: 14),
                _HelpBox(text: trSymbolHelp(_type)),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(onPressed: _submit, child: Text(_isEditing ? 'saveChanges'.tr  : 'save'.tr)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    });
  }

  String _title() {
    if (_isEditing) return widget.existing!.isInvestment ? 'editInvestment'.tr : 'editAsset'.tr;
    return widget.investmentDefault ? 'addInvestment'.tr : 'addAsset'.tr;
  }

  void _handleFieldChanged(String field) {
    if (_applyingSuggestion || !_needsMarketSuggestions) return;

    _lastEditedField = field;
    final text = field == 'symbol' ? _symbolController.text.trim() : _nameController.text.trim();
    final exact = exactMarketOption(_type, text);

    if (text.isNotEmpty && exact != null) {
      _applyMarketOption(exact, notify: false);
    }

    _scheduleRemoteSearch();
    if (mounted) _refreshUi();
  }

  void _scheduleRemoteSearch({bool immediate = false}) {
    _searchDebounce?.cancel();
    if (!_needsMarketSuggestions) return;

    final query = _currentQuery();
    final canSearchRemote = store.settings.apiBaseUrl.trim().isNotEmpty &&
        store.settings.apiToken.trim().isNotEmpty &&
        ['stock', 'etf', 'crypto', 'cn_stock', 'cn_etf'].contains(_type);

    if (!canSearchRemote) return;
    if (_type != 'crypto' && query.trim().isEmpty) return;

    _searchDebounce = Timer(immediate ? Duration.zero : const Duration(milliseconds: 450), () async {
      if (!mounted) return;
      _searchingRemote = true;
      _refreshUi();
      try {
        final items = await store.searchMarket(_type, query, limit: 3);
        if (!mounted) return;
        _remoteSuggestions = items;
        _refreshUi();
      } finally {
        if (mounted) {
          _searchingRemote = false;
          _refreshUi();
        }
      }
    });
  }

  String _currentQuery() {
    final nameText = _nameController.text.trim();
    final symbolText = _symbolController.text.trim();
    return _lastEditedField == 'symbol'
        ? (symbolText.isNotEmpty ? symbolText : nameText)
        : (nameText.isNotEmpty ? nameText : symbolText);
  }

  List<MarketOption> _marketSuggestions() {
    if (!_needsMarketSuggestions) return const [];
    return mergeMarketSuggestions(marketSuggestionsFor(_type, _currentQuery(), limit: 3), _remoteSuggestions, limit: 3);
  }

  void _applyMarketOption(MarketOption option, {bool notify = true}) {
    _applyingSuggestion = true;
    _nameController.text = trMarketOptionName(option);
    _symbolController.text = option.symbol;
    _currency = option.quoteCurrency;
    _lastEditedField = 'name';
    if (option.assetType == 'metal') {
      _unit = option.unit.isEmpty ? 'gram' : option.unit;
    }
    _applyingSuggestion = false;

    if (notify && mounted) {
      _refreshUi();
      FocusScope.of(context).unfocus();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final existing = widget.existing;
    final item = AssetItem(
      id: existing?.id ?? newId(),
      name: _nameController.text.trim(),
      type: _type,
      symbol: _symbolController.text.trim(),
      quantity: double.parse(_quantityController.text.trim()),
      currency: _currency,
      unit: _type == 'metal' ? _unit : '',
      manualPrice: double.tryParse(_manualPriceController.text.trim()) ?? 0,
      note: _noteController.text.trim(),
      createdAt: existing?.createdAt,
    );

    if (_isEditing) {
      await store.updateAsset(item);
    } else {
      await store.addAsset(item);
    }
    await store.refreshValuation(force: true, source: 'assetSaved');
    if (mounted) Get.back<void>();
  }

}

class _MarketSuggestionBox extends StatelessWidget {
  const _MarketSuggestionBox({
    required this.type,
    required this.suggestions,
    required this.searching,
    required this.onSelected,
  });

  final String type;
  final List<MarketOption> suggestions;
  final bool searching;
  final ValueChanged<MarketOption> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.inputColor(context),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('suggestions'.tr, style: TextStyle(fontSize: 13, color: AppTheme.textSubtle(context), fontWeight: FontWeight.w800)),
                const Spacer(),
                if (searching)
                  SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: theme.colorScheme.primary),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            if (suggestions.isEmpty && !searching)
              Text(_emptyText(context, type), style: TextStyle(color: AppTheme.textSubtle(context), fontSize: 13, height: 1.4))
            else
              ...suggestions.map((item) => _SuggestionTile(item: item, onTap: () => onSelected(item))),
          ],
        ),
      ),
    );
  }

  String _emptyText(BuildContext context, String type) => trNoMatch(type);
}

class _SuggestionTile extends StatelessWidget {
  const _SuggestionTile({required this.item, required this.onTap});

  final MarketOption item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.09),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(
                    item.displayCode.isEmpty ? '?' : item.displayCode.substring(0, item.displayCode.length > 4 ? 4 : item.displayCode.length),
                    style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.w900, fontSize: 11),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(trMarketOptionName(item), maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                      const SizedBox(height: 2),
                      Text(_subtitle(item), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: AppTheme.textSubtle(context))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(Icons.add_circle_outline_rounded, size: 20, color: AppTheme.textSubtle(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _subtitle(MarketOption item) {
    final parts = <String>[item.displayCode, item.symbol];
    if (item.subtitle.trim().isNotEmpty) parts.add(item.subtitle.trim());
    final provider = trMarketProvider(item.provider);
    if (provider.trim().isNotEmpty) parts.add(provider.trim());
    return parts.where((e) => e.trim().isNotEmpty).join(' · ');
  }
}

class _HelpBox extends StatelessWidget {
  const _HelpBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(18)),
      child: Text(text, style: TextStyle(color: AppTheme.textSubtle(context), height: 1.5)),
    );
  }
}
