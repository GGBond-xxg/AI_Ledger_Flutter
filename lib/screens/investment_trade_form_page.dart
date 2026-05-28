import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/app_constants.dart';
import '../core/formatters.dart';
import '../core/id.dart';
import '../l10n/translation_service.dart';
import '../models/asset_item.dart';
import '../models/bill_item.dart';
import '../services/ledger_store.dart';
import '../widgets/common_cards.dart';
import '../widgets/form_fields.dart';

class InvestmentTradeFormPage extends StatefulWidget {
  const InvestmentTradeFormPage({super.key, this.existing, this.defaultSell = true});

  final BillItem? existing;
  final bool defaultSell;

  @override
  State<InvestmentTradeFormPage> createState() => _InvestmentTradeFormPageState();
}

class _InvestmentTradeFormPageState extends State<InvestmentTradeFormPage> {
  final LedgerStore store = Get.find<LedgerStore>();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _quantityController = TextEditingController();
  final _noteController = TextEditingController();
  final _newFundNameController = TextEditingController();
  final _newInvestmentNameController = TextEditingController();
  final _newInvestmentSymbolController = TextEditingController();

  static const _newFundValue = '__new_fund_account__';
  static const _newInvestmentValue = '__new_investment_asset__';

  String _category = 'investmentSell';
  String _investmentAssetId = '';
  String _fundAssetId = '';
  String _newFundCurrency = 'USD';
  String _newInvestmentType = 'stock';
  String _newInvestmentCurrency = 'USD';
  String _newInvestmentUnit = 'gram';
  DateTime _occurredAt = DateTime.now();
  final RxInt _uiVersion = 0.obs;

  bool get _isEditing => widget.existing != null;
  bool get _isSell => _category == 'investmentSell';
  bool get _creatingInvestment => !_isSell && _investmentAssetId == _newInvestmentValue;
  void _refreshUi() => _uiVersion.value++;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _category = existing.category == 'investmentSell' ? 'investmentSell' : 'investmentBuy';
      _investmentAssetId = existing.investmentAssetId;
      _fundAssetId = existing.assetId;
      _amountController.text = trimNum(existing.amount);
      _quantityController.text = trimNum(existing.investmentQuantity);
      _noteController.text = existing.note;
      _newFundCurrency = existing.currency;
      _newInvestmentCurrency = existing.currency;
      _occurredAt = existing.occurredAt;
    } else {
      _category = widget.defaultSell ? 'investmentSell' : 'investmentBuy';
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _quantityController.dispose();
    _noteController.dispose();
    _newFundNameController.dispose();
    _newInvestmentNameController.dispose();
    _newInvestmentSymbolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      _uiVersion.value;
      final investments = store.billLinkedInvestments;
      final funds = store.billLinkedAssets;
      final selectedInvestment = _findAssetById(investments, _investmentAssetId);
      final selectedFund = _findAssetById(funds, _fundAssetId);

      if (_isSell && _investmentAssetId == _newInvestmentValue) {
        _investmentAssetId = '';
      }
      if (_investmentAssetId.isNotEmpty && _investmentAssetId != _newInvestmentValue && selectedInvestment == null) {
        _investmentAssetId = '';
      }
      if (_fundAssetId.isNotEmpty && _fundAssetId != _newFundValue && selectedFund == null) {
        _fundAssetId = '';
      }

      final fundCurrency = selectedFund?.currency ?? _newFundCurrency;

      return Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'editInvestmentTrade'.tr : (_isSell ? 'sellInvestment'.tr : 'buyInvestment'.tr))),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  FormCard(
                    children: [
                      LedgerDropdownField<String>(
                        label: 'investmentTradeType'.tr,
                        value: _category,
                        items: [
                          DropdownMenuItem(value: 'investmentBuy', child: Text('buyInvestment'.tr)),
                          DropdownMenuItem(value: 'investmentSell', child: Text('sellInvestment'.tr)),
                        ],
                        onChanged: (value) {
                          _category = value ?? _category;
                          if (_isSell && _investmentAssetId == _newInvestmentValue) {
                            _investmentAssetId = '';
                          }
                          _refreshUi();
                        },
                      ),
                      LedgerDropdownField<String>(
                        label: 'linkedInvestment'.tr,
                        value: _investmentAssetId,
                        items: [
                          DropdownMenuItem(value: '', child: Text('selectInvestment'.tr)),
                          ...investments.map((asset) => DropdownMenuItem(
                                value: asset.id,
                                child: Text(_investmentLabel(asset)),
                              )),
                          if (!_isSell) DropdownMenuItem(value: _newInvestmentValue, child: Text('createNewInvestment'.tr)),
                        ],
                        onChanged: (value) {
                          _investmentAssetId = value ?? '';
                          final asset = _findAssetById(investments, _investmentAssetId);
                          if (_fundAssetId == _newFundValue && asset != null && _newFundCurrency.trim().isEmpty) {
                            _newFundCurrency = asset.currency;
                          }
                          if (_investmentAssetId == _newInvestmentValue && _newInvestmentNameController.text.trim().isEmpty) {
                            _newInvestmentNameController.text = 'investment'.tr;
                          }
                          _refreshUi();
                        },
                      ),
                      if (_creatingInvestment) ..._newInvestmentFields(),
                      LedgerTextField(
                        controller: _quantityController,
                        label: 'investmentQuantity'.tr,
                        hint: selectedInvestment == null ? 'investmentQuantityHint'.tr : '${'currentHolding'.tr} ${trimNum(_sellableQuantity(selectedInvestment))}',
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          final number = double.tryParse(value?.trim() ?? '');
                          if (number == null || number <= 0) return 'enterPositiveNumber'.tr;
                          if (_isSell && selectedInvestment != null && number > _sellableQuantity(selectedInvestment) + 0.000000001) {
                            return '${'amountCannotExceed'.tr} ${trimNum(_sellableQuantity(selectedInvestment))}';
                          }
                          return null;
                        },
                      ),
                      LedgerDropdownField<String>(
                        label: _isSell ? 'receiveFundAccount'.tr : 'fundSource'.tr,
                        value: _fundAssetId,
                        items: [
                          DropdownMenuItem(value: '', child: Text('selectFundAccount'.tr)),
                          ...funds.map((asset) => DropdownMenuItem(
                                value: asset.id,
                                child: Text('${asset.name} · ${trimNum(asset.quantity)} ${asset.currency}'),
                              )),
                          DropdownMenuItem(value: _newFundValue, child: Text('createNewFundAccount'.tr)),
                        ],
                        onChanged: (value) {
                          _fundAssetId = value ?? '';
                          if (_fundAssetId == _newFundValue) {
                            final investment = _findAssetById(investments, _investmentAssetId);
                            _newFundCurrency = investment?.currency ?? _newInvestmentCurrency;
                            if (_newFundNameController.text.trim().isEmpty) {
                              _newFundNameController.text = 'fundAccount'.tr;
                            }
                          }
                          _refreshUi();
                        },
                      ),
                      if (_fundAssetId == _newFundValue) ...[
                        LedgerTextField(
                          controller: _newFundNameController,
                          label: 'newFundAccountName'.tr,
                          hint: 'newFundAccountNameHint'.tr,
                          validator: (value) => value == null || value.trim().isEmpty ? 'enterName'.tr : null,
                        ),
                        LedgerDropdownField<String>(
                          label: 'newFundAccountCurrency'.tr,
                          value: _newFundCurrency,
                          items: kCurrencies.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (value) {
                            _newFundCurrency = value ?? _newFundCurrency;
                            _refreshUi();
                          },
                        ),
                      ],
                      LedgerTextField(
                        controller: _amountController,
                        label: (_isSell ? 'receiveAmount' : 'fundAmount').trParams({'currency': fundCurrency}),
                        hint: 'amountHint'.tr,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          final number = double.tryParse(value?.trim() ?? '');
                          if (number == null || number <= 0) return 'enterPositiveAmount'.tr;
                          return null;
                        },
                      ),
                      _TradeDateField(value: _occurredAt, onTap: _pickDate),
                      LedgerTextField(controller: _noteController, label: 'noteOptional'.tr, maxLines: 3),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _TradeHelpBox(text: _isSell ? 'sellInvestmentHelp'.tr : 'buyInvestmentHelp'.tr),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(onPressed: _submit, child: Text(_isEditing ? 'saveChanges'.tr : 'save'.tr)),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  List<Widget> _newInvestmentFields() {
    final widgets = <Widget>[
      LedgerDropdownField<String>(
        label: 'newInvestmentType'.tr,
        value: _newInvestmentType,
        items: _investmentTypeOptions
            .map((value) => DropdownMenuItem(value: value, child: Text(trAssetType(value))))
            .toList(),
        onChanged: (value) {
          if (value == null) return;
          _newInvestmentType = value;
          _newInvestmentCurrency = _defaultCurrencyForInvestment(value);
          _newInvestmentUnit = 'gram';
          _refreshUi();
        },
      ),
      LedgerTextField(
        controller: _newInvestmentNameController,
        label: 'newInvestmentName'.tr,
        hint: 'newInvestmentNameHint'.tr,
        validator: (value) => value == null || value.trim().isEmpty ? 'enterName'.tr : null,
      ),
      LedgerTextField(
        controller: _newInvestmentSymbolController,
        label: _newInvestmentType == 'crypto' ? 'cryptoSymbol'.tr : 'symbol'.tr,
        hint: trSymbolHint(_newInvestmentType),
        validator: (value) => value == null || value.trim().isEmpty ? 'enterSymbol'.tr : null,
      ),
      LedgerDropdownField<String>(
        label: 'newInvestmentCurrency'.tr,
        value: _newInvestmentCurrency,
        items: kCurrencies.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (value) {
          _newInvestmentCurrency = value ?? _newInvestmentCurrency;
          _refreshUi();
        },
      ),
    ];

    if (_newInvestmentType == 'metal') {
      widgets.add(
        LedgerDropdownField<String>(
          label: 'newInvestmentUnit'.tr,
          value: _newInvestmentUnit,
          items: kMetalUnits.map((e) => DropdownMenuItem(value: e, child: Text(trMetalUnit(e)))).toList(),
          onChanged: (value) {
            _newInvestmentUnit = value ?? _newInvestmentUnit;
            _refreshUi();
          },
        ),
      );
    }

    return widgets;
  }

  static const _investmentTypeOptions = ['stock', 'etf', 'cn_stock', 'cn_etf', 'metal', 'crypto'];

  String _defaultCurrencyForInvestment(String type) {
    return (type == 'cn_stock' || type == 'cn_etf') ? 'CNY' : 'USD';
  }

  AssetItem? _findAssetById(List<AssetItem> assets, String id) {
    if (id.trim().isEmpty || id == _newInvestmentValue) return null;
    for (final asset in assets) {
      if (asset.id == id) return asset;
    }
    return null;
  }

  String _investmentLabel(AssetItem asset) {
    final code = asset.symbol.trim().isEmpty ? asset.name : asset.symbol.trim();
    return '${asset.name} · $code · ${trimNum(asset.quantity)}';
  }

  double _sellableQuantity(AssetItem asset) {
    final existing = widget.existing;
    if (existing != null && existing.isInvestmentSell && existing.investmentAssetId == asset.id) {
      return asset.quantity + existing.investmentQuantity;
    }
    return asset.quantity;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _occurredAt,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    _occurredAt = DateTime(picked.year, picked.month, picked.day, _occurredAt.hour, _occurredAt.minute);
    _refreshUi();
  }

  Future<void> _submit() async {
    final investments = store.billLinkedInvestments;
    final funds = store.billLinkedAssets;
    final creatingInvestment = _creatingInvestment;
    final investment = creatingInvestment ? null : _findAssetById(investments, _investmentAssetId);
    final existingFund = _findAssetById(funds, _fundAssetId);
    final creatingFund = _fundAssetId == _newFundValue;

    if (!creatingInvestment && investment == null) {
      Get.snackbar('investment'.tr, 'selectInvestment'.tr);
      return;
    }
    if (!creatingFund && existingFund == null) {
      Get.snackbar('investment'.tr, 'selectFundAccount'.tr);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final AssetItem? newFund = creatingFund
        ? AssetItem(
            id: newId(),
            name: _newFundNameController.text.trim(),
            type: 'cash',
            quantity: 0,
            currency: _newFundCurrency,
          )
        : null;

    final AssetItem? newInvestment = creatingInvestment
        ? AssetItem(
            id: newId(),
            name: _newInvestmentNameController.text.trim(),
            type: _newInvestmentType,
            symbol: _newInvestmentSymbolController.text.trim(),
            quantity: 0,
            currency: _newInvestmentCurrency,
            unit: _newInvestmentType == 'metal' ? _newInvestmentUnit : '',
          )
        : null;

    final selectedInvestment = newInvestment ?? investment!;
    final fundId = newFund?.id ?? existingFund!.id;
    final fundName = newFund?.name ?? existingFund!.name;
    final fundCurrency = newFund?.currency ?? existingFund!.currency;

    final item = BillItem(
      id: widget.existing?.id ?? newId(),
      type: 'investment',
      category: _category,
      amount: double.parse(_amountController.text.trim()),
      currency: fundCurrency,
      assetId: fundId,
      assetName: fundName,
      investmentAssetId: selectedInvestment.id,
      investmentAssetName: selectedInvestment.name,
      investmentQuantity: double.parse(_quantityController.text.trim()),
      note: _noteController.text.trim(),
      occurredAt: _occurredAt,
      createdAt: widget.existing?.createdAt,
    );

    final saveFuture = store.saveBillWithOptionalNewCashAsset(
      item,
      newCashAsset: newFund,
      newInvestmentAsset: newInvestment,
      updateExisting: _isEditing,
    );
    if (mounted) Get.back<void>();
    unawaited(saveFuture.catchError((_) {}));
    unawaited(store.refreshValuation(force: true, source: 'investmentTradeSaved'));
  }
}

class _TradeDateField extends StatelessWidget {
  const _TradeDateField({required this.value, required this.onTap});

  final DateTime value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Theme.of(context).inputDecorationTheme.fillColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('billDate'.tr, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 6),
              Text(dateText(value), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}

class _TradeHelpBox extends StatelessWidget {
  const _TradeHelpBox({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(text, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, height: 1.5)),
    );
  }
}
