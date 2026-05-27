import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/formatters.dart';
import '../core/id.dart';
import '../models/asset_item.dart';
import '../models/bill_item.dart';
import '../services/ledger_store.dart';
import '../widgets/common_cards.dart';
import '../widgets/form_fields.dart';

class ExchangeFormPage extends StatefulWidget {
  const ExchangeFormPage({super.key, this.existing});

  final BillItem? existing;

  @override
  State<ExchangeFormPage> createState() => _ExchangeFormPageState();
}

class _ExchangeFormPageState extends State<ExchangeFormPage> {
  final LedgerStore store = Get.find<LedgerStore>();
  final _formKey = GlobalKey<FormState>();
  final _fromAmountController = TextEditingController();
  final _toAmountController = TextEditingController();
  final _noteController = TextEditingController();

  String _fromAssetId = '';
  String _toAssetId = '';
  DateTime _occurredAt = DateTime.now();
  final RxInt _uiVersion = 0.obs;

  bool get _isEditing => widget.existing != null;
  void _refreshUi() => _uiVersion.value++;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _fromAssetId = existing.assetId;
      _toAssetId = existing.toAssetId;
      _fromAmountController.text = trimNum(existing.amount);
      _toAmountController.text = trimNum(existing.toAmount);
      _noteController.text = existing.note;
      _occurredAt = existing.occurredAt;
    }
  }

  @override
  void dispose() {
    _fromAmountController.dispose();
    _toAmountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      _uiVersion.value;
      final fundAssets = store.billLinkedAssets;
      final fromAsset = _findAssetById(fundAssets, _fromAssetId);
      final toAsset = _findAssetById(fundAssets, _toAssetId);
      if (_fromAssetId.isNotEmpty && fromAsset == null) {
        _fromAssetId = '';
      }
      if (_toAssetId.isNotEmpty && toAsset == null) {
        _toAssetId = '';
      }

      return Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'editExchange'.tr : 'exchangeBill'.tr)),
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
                        label: 'fromFundAccount'.tr,
                        value: _fromAssetId,
                        items: [
                          DropdownMenuItem(value: '', child: Text('selectFundAccount'.tr)),
                          ...fundAssets.map((asset) => DropdownMenuItem(
                                value: asset.id,
                                child: Text('${asset.name} · ${trimNum(asset.quantity)} ${asset.currency}'),
                              )),
                        ],
                        onChanged: (value) {
                          _fromAssetId = value ?? '';
                          _refreshUi();
                        },
                      ),
                      if (fromAsset != null)
                        LedgerTextField(
                          controller: _fromAmountController,
                          label: 'fromAmount'.trParams({'currency': fromAsset.currency}),
                          hint: 'amountHint'.tr,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: _positiveAmountValidator,
                        ),
                      LedgerDropdownField<String>(
                        label: 'toFundAccount'.tr,
                        value: _toAssetId,
                        items: [
                          DropdownMenuItem(value: '', child: Text('selectFundAccount'.tr)),
                          ...fundAssets.map((asset) => DropdownMenuItem(
                                value: asset.id,
                                child: Text('${asset.name} · ${trimNum(asset.quantity)} ${asset.currency}'),
                              )),
                        ],
                        onChanged: (value) {
                          _toAssetId = value ?? '';
                          _refreshUi();
                        },
                      ),
                      if (toAsset != null)
                        LedgerTextField(
                          controller: _toAmountController,
                          label: 'toAmount'.trParams({'currency': toAsset.currency}),
                          hint: 'amountHint'.tr,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: _positiveAmountValidator,
                        ),
                      _ExchangeDateField(value: _occurredAt, onTap: _pickDate),
                      LedgerTextField(controller: _noteController, label: 'noteOptional'.tr, maxLines: 3),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ExchangeHelpBox(text: 'exchangeBillHelp'.tr),
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

  String? _positiveAmountValidator(String? value) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null || number <= 0) return 'enterPositiveAmount'.tr;
    return null;
  }

  AssetItem? _findAssetById(List<AssetItem> assets, String id) {
    if (id.trim().isEmpty) return null;
    for (final asset in assets) {
      if (asset.id == id) return asset;
    }
    return null;
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
    final fundAssets = store.billLinkedAssets;
    final fromAsset = _findAssetById(fundAssets, _fromAssetId);
    final toAsset = _findAssetById(fundAssets, _toAssetId);
    if (fromAsset == null || toAsset == null) {
      Get.snackbar('exchangeBill'.tr, 'selectExchangeAccounts'.tr);
      return;
    }
    if (fromAsset.id == toAsset.id) {
      Get.snackbar('exchangeBill'.tr, 'exchangeAccountMustDifferent'.tr);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final item = BillItem(
      id: widget.existing?.id ?? newId(),
      type: 'exchange',
      category: 'exchange',
      amount: double.parse(_fromAmountController.text.trim()),
      currency: fromAsset.currency,
      assetId: fromAsset.id,
      assetName: fromAsset.name,
      toAssetId: toAsset.id,
      toAssetName: toAsset.name,
      toAmount: double.parse(_toAmountController.text.trim()),
      toCurrency: toAsset.currency,
      note: _noteController.text.trim(),
      occurredAt: _occurredAt,
      createdAt: widget.existing?.createdAt,
    );

    final Future<void> saveFuture =
        _isEditing ? store.updateBill(item) : store.addBill(item);
    if (mounted) Get.back<void>();
    unawaited(saveFuture.catchError((_) {}));
    unawaited(store.refreshValuation(force: true, source: 'exchangeSaved'));
  }
}

class _ExchangeDateField extends StatelessWidget {
  const _ExchangeDateField({required this.value, required this.onTap});

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

class _ExchangeHelpBox extends StatelessWidget {
  const _ExchangeHelpBox({required this.text});

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
