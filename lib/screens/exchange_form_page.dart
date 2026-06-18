import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/app_theme.dart';
import '../core/app_constants.dart';
import '../core/formatters.dart';
import '../core/id.dart';
import '../models/asset_item.dart';
import '../models/bill_item.dart';
import '../services/ledger_store.dart';
import '../widgets/safe_bottom_sheet.dart';

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
  final _newToNameController = TextEditingController();

  static const _newToAssetValue = '__new_to_asset__';

  String _fromAssetId = '';
  String _toAssetId = '';
  String _newToCurrency = 'USD';
  DateTime _occurredAt = DateTime.now();
  final RxInt _uiVersion = 0.obs;

  bool get _isEditing => widget.existing != null;
  bool get _creatingToAsset => _toAssetId == _newToAssetValue;
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
      _newToCurrency = existing.toCurrency.trim().isEmpty ? 'USD' : existing.toCurrency;
      _occurredAt = existing.occurredAt;
    }
  }

  @override
  void dispose() {
    _fromAmountController.dispose();
    _toAmountController.dispose();
    _noteController.dispose();
    _newToNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      _uiVersion.value;
      final fundAssets = store.billLinkedAssets;
      final fromAsset = _findAssetById(fundAssets, _fromAssetId);
      final toAsset = _findAssetById(fundAssets, _toAssetId);
      if (_fromAssetId.isNotEmpty && fromAsset == null) _fromAssetId = '';
      if (_toAssetId.isNotEmpty && !_creatingToAsset && toAsset == null) _toAssetId = '';

      return _ExchangeScaffold(
        title: _isEditing ? '编辑换汇' : '换汇',
        onSubmit: _submit,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
            child: Column(
              children: [
                _ExchangeAmountHero(
                  fromAmount: _fromAmountController.text,
                  fromCurrency: fromAsset?.currency ?? '---',
                  toAmount: _toAmountController.text,
                  toCurrency: toAsset?.currency ?? (_creatingToAsset ? _newToCurrency : '---'),
                ),
                const SizedBox(height: 18),
                _ReferenceFormCard(
                  children: [
                    _InfoRow(
                      label: '换出账户',
                      value: fromAsset == null ? '请选择资金账户' : _assetLabel(fromAsset),
                      muted: fromAsset == null,
                      onTap: () => _showAssetSheet(
                        title: '选择换出账户',
                        assets: fundAssets,
                        selectedId: _fromAssetId,
                        allowCreate: false,
                        onSelected: (value) {
                          _fromAssetId = value;
                          if (_toAssetId == value) _toAssetId = '';
                          _refreshUi();
                        },
                      ),
                    ),
                    const _SoftDivider(),
                    _InlineInputRow(
                      label: '换出金额',
                      controller: _fromAmountController,
                      hint: fromAsset == null ? '0.00' : '金额（${fromAsset.currency}）',
                      validator: _positiveAmountValidator,
                      onChanged: (_) => _refreshUi(),
                    ),
                    const _SoftDivider(),
                    _InfoRow(
                      label: '换入账户',
                      value: _creatingToAsset ? '创建新资金账户' : (toAsset == null ? '请选择资金账户' : _assetLabel(toAsset)),
                      muted: !_creatingToAsset && toAsset == null,
                      onTap: () => _showAssetSheet(
                        title: '选择换入账户',
                        assets: fundAssets,
                        selectedId: _toAssetId,
                        allowCreate: true,
                        onSelected: (value) {
                          _toAssetId = value;
                          if (_toAssetId == _newToAssetValue && _newToNameController.text.trim().isEmpty) {
                            _newToNameController.text = fromAsset == null ? '新资金账户' : '${fromAsset.name}换入';
                          }
                          _refreshUi();
                        },
                      ),
                    ),
                    const _SoftDivider(),
                    if (_creatingToAsset) ...[
                      _InlineInputRow(
                        label: '账户名称',
                        controller: _newToNameController,
                        hint: '例如：美元账户',
                        keyboardType: TextInputType.text,
                        validator: (value) => value == null || value.trim().isEmpty ? '请输入账户名称' : null,
                        onChanged: (_) => _refreshUi(),
                      ),
                      const _SoftDivider(),
                      _InfoRow(
                        label: '账户货币',
                        value: _newToCurrency,
                        onTap: _showCurrencySheet,
                      ),
                      const _SoftDivider(),
                    ],
                    _InlineInputRow(
                      label: '换入金额',
                      controller: _toAmountController,
                      hint: '金额（${toAsset?.currency ?? (_creatingToAsset ? _newToCurrency : '目标货币')}）',
                      validator: _positiveAmountValidator,
                      onChanged: (_) => _refreshUi(),
                    ),
                    const _SoftDivider(),
                    _InfoRow(
                      label: '日期',
                      value: '${dateText(_occurredAt)}  ${_timeText(_occurredAt)}',
                      onTap: _pickDate,
                    ),
                    const _SoftDivider(),
                    _InfoRow(
                      label: '备注',
                      value: _noteController.text.trim().isEmpty ? '可填写备注...' : _noteController.text.trim(),
                      muted: _noteController.text.trim().isEmpty,
                      onTap: _showNoteSheet,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const _HelpBox(text: '换汇只记录两个资金账户之间的币种转换，不计入日常收入、支出和结余。'),
                const SizedBox(height: 22),
                SizedBox(width: double.infinity, height: 52, child: FilledButton(onPressed: _submit, child: const Text('保存'))),
              ],
            ),
          ),
        ),
      );
    });
  }

  String? _positiveAmountValidator(String? value) {
    final number = double.tryParse(value?.trim() ?? '');
    if (number == null || number <= 0) return '请输入有效金额';
    return null;
  }

  AssetItem? _findAssetById(List<AssetItem> assets, String id) {
    if (id.trim().isEmpty) return null;
    for (final asset in assets) {
      if (asset.id == id) return asset;
    }
    return null;
  }

  String _assetLabel(AssetItem asset) => '${asset.name}（${_formatMoney(asset.quantity, asset.currency)}）';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _occurredAt, firstDate: DateTime(2000), lastDate: DateTime(2100));
    if (picked == null || !mounted) return;
    final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_occurredAt));
    final time = pickedTime ?? TimeOfDay.fromDateTime(_occurredAt);
    _occurredAt = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
    _refreshUi();
  }

  void _showAssetSheet({
    required String title,
    required List<AssetItem> assets,
    required String selectedId,
    required bool allowCreate,
    required ValueChanged<String> onSelected,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.sheetBackground(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return SafeBottomSheet(
          children: [
            _SheetTitle(title: title),
            const SizedBox(height: 8),
            if (assets.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('暂无资金账户', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
              )
            else
              ...assets.map((asset) => _SheetTile(
                    selected: selectedId == asset.id,
                    icon: Icons.account_balance_wallet_rounded,
                    title: asset.name,
                    subtitle: '${asset.currency} · ${_formatMoney(asset.quantity, asset.currency)}',
                    onTap: () {
                      Navigator.pop(context);
                      onSelected(asset.id);
                    },
                  )),
            if (allowCreate)
              _SheetTile(
                selected: selectedId == _newToAssetValue,
                icon: Icons.add_rounded,
                title: '创建新资金账户',
                subtitle: '没有目标账户时可以直接创建',
                onTap: () {
                  Navigator.pop(context);
                  onSelected(_newToAssetValue);
                },
              ),
          ],
        );
      },
    );
  }

  void _showCurrencySheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.sheetBackground(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return SafeBottomSheet(
          children: [
            const _SheetTitle(title: '选择货币'),
            const SizedBox(height: 8),
            ...kCurrencies.map((currency) => _SheetTile(
                  selected: _newToCurrency == currency,
                  icon: Icons.payments_outlined,
                  title: currency,
                  subtitle: '',
                  onTap: () {
                    Navigator.pop(context);
                    _newToCurrency = currency;
                    _refreshUi();
                  },
                )),
          ],
        );
      },
    );
  }

  void _showNoteSheet() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.sheetBackground(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return SafeBottomSheet(
          keyboardAware: true,
          maxHeightFactor: 0.76,
          children: [
            const _SheetTitle(title: '填写备注'),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              autofocus: true,
              maxLines: 4,
              decoration: const InputDecoration(
                hintText: '例如：Zabank HKD 换 IBKR USD',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  _refreshUi();
                },
                child: const Text('完成'),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submit() async {
    final fundAssets = store.billLinkedAssets;
    final fromAsset = _findAssetById(fundAssets, _fromAssetId);
    final existingToAsset = _findAssetById(fundAssets, _toAssetId);
    final creatingToAsset = _creatingToAsset;
    if (fromAsset == null || (!creatingToAsset && existingToAsset == null)) {
      Get.snackbar('换汇', '请选择换出和换入账户');
      return;
    }
    if (!creatingToAsset && fromAsset.id == existingToAsset!.id) {
      Get.snackbar('换汇', '换出账户和换入账户不能相同');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final AssetItem? newToAsset = creatingToAsset
        ? AssetItem(id: newId(), name: _newToNameController.text.trim(), type: 'cash', quantity: 0, currency: _newToCurrency)
        : null;
    final toAssetId = newToAsset?.id ?? existingToAsset!.id;
    final toAssetName = newToAsset?.name ?? existingToAsset!.name;
    final toCurrency = newToAsset?.currency ?? existingToAsset!.currency;

    final item = BillItem(
      id: widget.existing?.id ?? newId(),
      type: 'exchange',
      category: 'exchange',
      amount: double.parse(_fromAmountController.text.trim()),
      currency: fromAsset.currency,
      assetId: fromAsset.id,
      assetName: fromAsset.name,
      toAssetId: toAssetId,
      toAssetName: toAssetName,
      toAmount: double.parse(_toAmountController.text.trim()),
      toCurrency: toCurrency,
      note: _noteController.text.trim(),
      occurredAt: _occurredAt,
      createdAt: widget.existing?.createdAt,
    );

    final Future<void> saveFuture = store.saveBillWithOptionalNewCashAsset(item, newCashAsset: newToAsset, updateExisting: _isEditing);
    if (mounted) Get.back<void>();
    unawaited(saveFuture.catchError((_) {}));
    unawaited(store.refreshValuation(force: true, source: 'exchangeSaved'));
  }
}

class _ExchangeScaffold extends StatelessWidget {
  const _ExchangeScaffold({required this.title, required this.onSubmit, required this.child});
  final String title;
  final VoidCallback onSubmit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: AppTheme.pageBackground(context),
      appBar: AppBar(
        centerTitle: true,
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        backgroundColor: AppTheme.pageBackground(context),
        surfaceTintColor: Colors.transparent,
        leading: IconButton(onPressed: () => Get.back<void>(), icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20)),
        actions: [IconButton(onPressed: onSubmit, icon: Icon(Icons.check_rounded, color: cs.primary, size: 24)), const SizedBox(width: 6)],
      ),
      body: SafeArea(child: child),
    );
  }
}

class _ExchangeAmountHero extends StatelessWidget {
  const _ExchangeAmountHero({required this.fromAmount, required this.fromCurrency, required this.toAmount, required this.toCurrency});
  final String fromAmount;
  final String fromCurrency;
  final String toAmount;
  final String toCurrency;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final from = fromAmount.trim().isEmpty ? '0.00' : fromAmount.trim();
    final to = toAmount.trim().isEmpty ? '0.00' : toAmount.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: cs.primaryContainer.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(24), border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.55))),
      child: Row(
        children: [
          Expanded(child: _AmountMini(label: '换出', amount: from, currency: fromCurrency, color: const Color(0xFFD64545))),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Icon(Icons.arrow_forward_rounded, color: cs.primary)),
          Expanded(child: _AmountMini(label: '换入', amount: to, currency: toCurrency, color: const Color(0xFF248B5D))),
        ],
      ),
    );
  }
}

class _AmountMini extends StatelessWidget {
  const _AmountMini({required this.label, required this.amount, required this.currency, required this.color});
  final String label;
  final String amount;
  final String currency;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.w800)),
      const SizedBox(height: 6),
      FittedBox(alignment: Alignment.centerLeft, child: Text('${_currencySymbol(currency)} $amount', style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5))),
      const SizedBox(height: 2),
      Text(currency, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12, fontWeight: FontWeight.w700)),
    ]);
  }
}

class _ReferenceFormCard extends StatelessWidget {
  const _ReferenceFormCard({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.72)),

      ),
      child: ClipRRect(borderRadius: BorderRadius.circular(24), child: Column(children: children)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value, required this.onTap, this.muted = false});
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(children: [
            SizedBox(width: 82, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
            Expanded(child: Text(value, textAlign: TextAlign.right, overflow: TextOverflow.ellipsis, style: TextStyle(color: muted ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w800))),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ]),
        ),
      ),
    );
  }
}

class _InlineInputRow extends StatelessWidget {
  const _InlineInputRow({required this.label, required this.controller, required this.hint, this.validator, this.onChanged, this.keyboardType});
  final String label;
  final TextEditingController controller;
  final String hint;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(children: [
        SizedBox(width: 82, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
        Expanded(
          child: Theme(
            data: Theme.of(context).copyWith(
              inputDecorationTheme: const InputDecorationTheme(
                filled: false,
                fillColor: Colors.transparent,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),
            child: TextFormField(
              controller: controller,
              textAlign: TextAlign.right,
              keyboardType: keyboardType ?? const TextInputType.numberWithOptions(decimal: true),
              validator: validator,
              onChanged: onChanged,
              decoration: InputDecoration(
                hintText: hint,
                filled: false,
                fillColor: Colors.transparent,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),
          ),
        ),
      ]),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();
  @override
  Widget build(BuildContext context) => Divider(height: 1, indent: 16, endIndent: 16, color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.72));
}

class _HelpBox extends StatelessWidget {
  const _HelpBox({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.34), borderRadius: BorderRadius.circular(18), border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.45))),
        child: Text(text, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5, fontWeight: FontWeight.w700)),
      );
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(top: 2, bottom: 6), child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)));
}

class _SheetTile extends StatelessWidget {
  const _SheetTile({required this.selected, required this.icon, required this.title, required this.subtitle, required this.onTap});
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? cs.primaryContainer.withValues(alpha: 0.64) : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(children: [
              Container(width: 38, height: 38, decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)), child: Icon(icon, color: cs.primary, size: 20)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(title, style: const TextStyle(fontWeight: FontWeight.w900)), if (subtitle.isNotEmpty) ...[const SizedBox(height: 2), Text(subtitle, style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant, fontWeight: FontWeight.w600))]])),
              if (selected) Icon(Icons.check_circle_rounded, color: cs.primary),
            ]),
          ),
        ),
      ),
    );
  }
}

String _formatMoney(num value, String currency) {
  final absValue = value.abs();
  final fixed = absValue.toStringAsFixed(2);
  final parts = fixed.split('.');
  final intPart = parts[0].replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => ',');
  final sign = value < 0 ? '-' : '';
  return '$sign${_currencySymbol(currency)}$intPart.${parts[1]}';
}

String _currencySymbol(String currency) {
  return switch (currency.toUpperCase()) {
    'CNY' => '¥',
    'USD' => r'$',
    'HKD' => r'HK$',
    'SGD' => r'S$',
    'EUR' => '€',
    'JPY' => '¥',
    _ => '$currency ',
  };
}

String _timeText(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(date.hour)}:${two(date.minute)}';
}
