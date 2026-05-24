import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/app_constants.dart';
import '../core/formatters.dart';
import '../core/id.dart';
import '../models/asset_item.dart';
import '../models/bill_item.dart';
import '../services/ledger_store.dart';
import '../widgets/common_cards.dart';
import '../widgets/form_fields.dart';

class BillFormPage extends StatefulWidget {
  const BillFormPage({super.key, this.existing});

  final BillItem? existing;

  @override
  State<BillFormPage> createState() => _BillFormPageState();
}

class _BillFormPageState extends State<BillFormPage> {
  final LedgerStore store = Get.find<LedgerStore>();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _investmentQuantityController = TextEditingController();

  String _type = 'expense';
  String _category = 'food';
  String _currency = 'CNY';
  String _assetId = '';
  String _investmentAssetId = '';
  DateTime _occurredAt = DateTime.now();
  final RxInt _uiVersion = 0.obs;

  bool get _isEditing => widget.existing != null;
  void _refreshUi() => _uiVersion.value++;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _type = existing.type;
      _category = existing.category;
      _amountController.text = trimNum(existing.amount);
      _currency = existing.currency;
      _assetId = existing.assetId;
      _investmentAssetId = existing.investmentAssetId;
      if (existing.investmentQuantity > 0) {
        _investmentQuantityController.text = trimNum(existing.investmentQuantity);
      }
      _noteController.text = existing.note;
      _occurredAt = existing.occurredAt;
    } else {
      _currency = store.settings.defaultCurrency;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _investmentQuantityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      _uiVersion.value;
      final categories = _type == 'income' ? _incomeCategories : _expenseCategories;
      if (!categories.contains(_category)) {
        _category = categories.first;
      }

      final fundAssets = store.billLinkedAssets;
      final investmentAssets = store.billLinkedInvestments;
      final selectedAsset = _findAssetById(fundAssets, _assetId);
      final selectedInvestment = _findAssetById(investmentAssets, _investmentAssetId);
      if (_assetId.isNotEmpty && selectedAsset == null) {
        _assetId = '';
      }
      if (selectedAsset != null && _currency != selectedAsset.currency) {
        _currency = selectedAsset.currency;
      }
      if (_investmentAssetId.isNotEmpty && selectedInvestment == null) {
        _investmentAssetId = '';
        _investmentQuantityController.clear();
      }

      return Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'editBill'.tr : 'addBill'.tr)),
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
                        label: 'billType'.tr,
                        value: _type,
                        items: [
                          DropdownMenuItem(value: 'expense', child: Text('expense'.tr)),
                          DropdownMenuItem(value: 'income', child: Text('income'.tr)),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          _type = value;
                          _category = (_type == 'income' ? _incomeCategories : _expenseCategories).first;
                          _refreshUi();
                        },
                      ),
                      LedgerTextField(
                        controller: _amountController,
                        label: 'amount'.tr,
                        hint: 'amountHint'.tr,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          final number = double.tryParse(value?.trim() ?? '');
                          if (number == null || number <= 0) return 'enterPositiveAmount'.tr;
                          return null;
                        },
                      ),
                      LedgerDropdownField<String>(
                        label: 'billCategory'.tr,
                        value: _category,
                        items: categories.map((e) => DropdownMenuItem(value: e, child: Text(trBillCategory(e)))).toList(),
                        onChanged: (value) {
                          _category = value ?? _category;
                          _refreshUi();
                        },
                      ),
                      LedgerDropdownField<String>(
                        label: 'linkedAsset'.tr,
                        value: _assetId,
                        items: [
                          DropdownMenuItem(value: '', child: Text('noLinkedAsset'.tr)),
                          ...fundAssets.map((asset) {
                            return DropdownMenuItem(
                              value: asset.id,
                              child: Text('${asset.name} · ${trimNum(asset.quantity)} ${asset.currency}'),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          _assetId = value ?? '';
                          final asset = _findAssetById(fundAssets, _assetId);
                          if (asset != null) {
                            _currency = asset.currency;
                          }
                          _refreshUi();
                        },
                      ),
                      if (selectedAsset == null)
                        LedgerDropdownField<String>(
                          label: 'currency'.tr,
                          value: _currency,
                          items: kCurrencies.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                          onChanged: (value) {
                            _currency = value ?? _currency;
                            _refreshUi();
                          },
                        )
                      else
                        _ReadonlyValueField(label: 'currency'.tr, value: selectedAsset.currency),
                      LedgerDropdownField<String>(
                        label: 'linkedInvestment'.tr,
                        value: _investmentAssetId,
                        items: [
                          DropdownMenuItem(value: '', child: Text('noLinkedInvestment'.tr)),
                          ...investmentAssets.map((asset) {
                            final symbol = asset.symbol.trim().isEmpty ? asset.name : asset.symbol.trim();
                            return DropdownMenuItem(
                              value: asset.id,
                              child: Text('${asset.name} · $symbol · ${trimNum(asset.quantity)}'),
                            );
                          }),
                        ],
                        onChanged: (value) {
                          _investmentAssetId = value ?? '';
                          if (_investmentAssetId.isEmpty) {
                            _investmentQuantityController.clear();
                          }
                          _refreshUi();
                        },
                      ),
                      if (selectedInvestment != null)
                        LedgerTextField(
                          controller: _investmentQuantityController,
                          label: 'investmentQuantity'.tr,
                          hint: 'investmentQuantityHint'.tr,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            final number = double.tryParse(value?.trim() ?? '');
                            if (number == null || number <= 0) return 'enterPositiveNumber'.tr;
                            return null;
                          },
                        ),
                      _DateField(
                        value: _occurredAt,
                        onTap: _pickDate,
                      ),
                      LedgerTextField(controller: _noteController, label: 'noteOptional'.tr, maxLines: 3),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _HelpBox(text: 'billLinkedAssetHelp'.tr),
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
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.existing;
    final linkedAsset = _findAssetById(store.billLinkedAssets, _assetId);
    final linkedInvestment = _findAssetById(store.billLinkedInvestments, _investmentAssetId);
    final investmentQuantity = linkedInvestment == null ? 0.0 : double.parse(_investmentQuantityController.text.trim());
    final item = BillItem(
      id: existing?.id ?? newId(),
      type: _type,
      category: _category,
      amount: double.parse(_amountController.text.trim()),
      currency: linkedAsset?.currency ?? _currency,
      assetId: linkedAsset?.id ?? '',
      assetName: linkedAsset?.name ?? '',
      investmentAssetId: linkedInvestment?.id ?? '',
      investmentAssetName: linkedInvestment?.name ?? '',
      investmentQuantity: investmentQuantity,
      note: _noteController.text.trim(),
      occurredAt: _occurredAt,
      createdAt: existing?.createdAt,
    );

    if (_isEditing) {
      await store.updateBill(item);
    } else {
      await store.addBill(item);
    }
    if (mounted) Get.back<void>();
  }
}

class _ReadonlyValueField extends StatelessWidget {
  const _ReadonlyValueField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
            Text(label, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({required this.value, required this.onTap});

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

class _HelpBox extends StatelessWidget {
  const _HelpBox({required this.text});

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

const List<String> _expenseCategories = [
  'food',
  'drink',
  'transport',
  'shopping',
  'rent',
  'utilities',
  'medical',
  'entertainment',
  'otherExpense',
];

const List<String> _incomeCategories = [
  'salary',
  'bonus',
  'partTime',
  'investmentIncome',
  'gift',
  'otherIncome',
];

String trBillCategory(String key) => 'billCategory_$key'.tr;
