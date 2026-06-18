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
import 'exchange_form_page.dart';

class BillFormPage extends StatefulWidget {
  const BillFormPage({super.key, this.existing});

  final BillItem? existing;

  @override
  State<BillFormPage> createState() => _BillFormPageState();
}

class _BillFormPageState extends State<BillFormPage> {
  final LedgerStore store = Get.find<LedgerStore>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _investmentQuantityController = TextEditingController();

  String _type = 'expense';
  String _category = 'shopping';
  String _currency = 'CNY';
  String _assetId = '';
  String _investmentAssetId = '';
  DateTime _occurredAt = DateTime.now();
  bool _includeInDailyStats = true;

  bool get _isEditing => widget.existing != null;

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
      // Explicit reactive reads for GetX. The builder uses derived lists below,
      // but GetX requires at least one Rx value to be read directly here.
      store.assets.length;
      store.billsVersion.value;
      store.settings;
      final categories = _categoriesForType(_type);
      if (!categories.contains(_category)) {
        _category = categories.first;
      }

      final fundAssets = store.billLinkedAssets;
      final investmentAssets = store.billLinkedInvestments;
      if (!_isEditing && _assetId.isEmpty && fundAssets.isNotEmpty) {
        _assetId = fundAssets.first.id;
        _currency = fundAssets.first.currency;
      }

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

      return _ReferenceBillScaffold(
        title: _isEditing ? '编辑账单' : '记一笔',
        onSubmit: _submit,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
                child: Column(
                  children: [
                    _BillTypeSelector(
                      selectedType: _type,
                      onChanged: _changeType,
                      onTransferTap: () {
                        Get.to<void>(() => const ExchangeFormPage());
                      },
                    ),
                    const SizedBox(height: 30),
                    _AmountReadout(
                      currency: _currency,
                      amountText: _displayAmountText,
                    ),
                    const SizedBox(height: 18),
                    _CategoryPill(
                      type: _type,
                      label: trBillCategory(_category),
                      icon: _categoryIcon(_category),
                      onTap: () => _showCategorySheet(categories),
                    ),
                    const SizedBox(height: 20),
                    _ReferenceFormCard(
                      children: [
                        _InfoRow(
                          label: '账户',
                          value: selectedAsset == null
                              ? '不选择账户'
                              : '${selectedAsset.name}（${_formatMoney(selectedAsset.quantity, selectedAsset.currency)}）',
                          onTap: () => _showAccountSheet(fundAssets),
                        ),
                        const _SoftDivider(),
                        if (selectedAsset == null) ...[
                          _InfoRow(
                            label: '货币',
                            value: _currency,
                            onTap: _showCurrencySheet,
                          ),
                          const _SoftDivider(),
                        ],
                        if (_type == 'investment') ...[
                          _InfoRow(
                            label: '投资标的',
                            value: selectedInvestment == null ? '请选择投资资产' : selectedInvestment.name,
                            onTap: () => _showInvestmentSheet(investmentAssets),
                          ),
                          const _SoftDivider(),
                          _InlineInputRow(
                            label: '数量',
                            controller: _investmentQuantityController,
                            hint: '0',
                          ),
                          const _SoftDivider(),
                        ],
                        _InfoRow(
                          label: '日期',
                          value: '${_dateLabel(_occurredAt)}  ${_timeText(_occurredAt)}',
                          onTap: _pickDate,
                        ),
                        const _SoftDivider(),
                        _InfoRow(
                          label: '备注',
                          value: _noteController.text.trim().isEmpty ? '可填写备注...' : _noteController.text.trim(),
                          muted: _noteController.text.trim().isEmpty,
                          onTap: _showNoteSheet,
                        ),
                        const _SoftDivider(),
                        _SwitchInfoRow(
                          label: '计入预算',
                          value: _includeInDailyStats,
                          onChanged: (value) {
                            setState(() => _includeInDailyStats = value);
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            _NumberPad(
              onKeyTap: _handleKeyTap,
              onDone: _submit,
            ),
          ],
        ),
      );
    });
  }

  List<String> _categoriesForType(String type) {
    return switch (type) {
      'income' => _incomeCategories,
      'investment' => _investmentCategories,
      _ => _expenseCategories,
    };
  }

  String get _displayAmountText {
    final raw = _amountController.text.trim();
    if (raw.isEmpty) return '0.00';
    final value = double.tryParse(raw);
    if (value == null) return raw;
    return value.toStringAsFixed(2);
  }

  void _changeType(String value) {
    if (value == 'exchange') {
      Get.to<void>(() => const ExchangeFormPage());
      return;
    }
    setState(() {
      _type = value;
      _category = switch (_type) {
        'income' => _incomeCategories.first,
        'investment' => _investmentCategories.first,
        _ => 'shopping',
      };
    });
  }

  void _handleKeyTap(String key) {
    var text = _amountController.text.trim();
    if (key == 'back') {
      if (text.isNotEmpty) {
        text = text.substring(0, text.length - 1);
      }
      _amountController.text = text;
      setState(() {});
      return;
    }

    if (key == '.') {
      if (text.contains('.')) return;
      text = text.isEmpty ? '0.' : '$text.';
    } else {
      if (text == '0') {
        text = key;
      } else {
        text = '$text$key';
      }
    }

    final dotIndex = text.indexOf('.');
    if (dotIndex >= 0 && text.length - dotIndex > 3) return;
    if (text.length > 12) return;
    _amountController.text = text;
    setState(() {});
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
    if (!mounted) return;
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_occurredAt),
    );
    final time = pickedTime ?? TimeOfDay.fromDateTime(_occurredAt);
    setState(() {
      _occurredAt = DateTime(picked.year, picked.month, picked.day, time.hour, time.minute);
    });
  }

  void _showCategorySheet(List<String> categories) {
    _showSelectionSheet<String>(
      title: '选择分类',
      items: categories,
      selected: _category,
      labelBuilder: trBillCategory,
      iconBuilder: _categoryIcon,
      onSelected: (value) {
        setState(() => _category = value);
      },
    );
  }

  void _showAccountSheet(List<AssetItem> assets) {
    final items = [
      const _AccountOption(
        id: '',
        name: '不选择账户',
        subtitle: '只记录账单，不影响资金账户余额',
        currency: '',
        amount: 0,
      ),
      ...assets.map((asset) => _AccountOption(
            id: asset.id,
            name: asset.name,
            subtitle: '${asset.currency} · ${asset.note.trim().isEmpty ? '资金账户' : asset.note.trim()}',
            currency: asset.currency,
            amount: asset.quantity,
          )),
    ];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.sheetBackground(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return SafeBottomSheet(
          children: [
            const _SheetTitle(title: '选择资金账户'),
            const SizedBox(height: 8),
            ...items.map((item) {
              final selected = item.id == _assetId;
              return _SheetTile(
                selected: selected,
                icon: item.id.isEmpty ? Icons.block_rounded : Icons.account_balance_wallet_rounded,
                title: item.name,
                subtitle: item.id.isEmpty ? item.subtitle : '${item.subtitle} · ${_formatMoney(item.amount, item.currency)}',
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _assetId = item.id;
                    if (item.id.isNotEmpty) _currency = item.currency;
                  });
                },
              );
            }),
          ],
        );
      },
    );
  }

  void _showCurrencySheet() {
    _showSelectionSheet<String>(
      title: '选择货币',
      items: kCurrencies,
      selected: _currency,
      labelBuilder: (value) => value,
      iconBuilder: (_) => Icons.payments_outlined,
      onSelected: (value) {
        setState(() => _currency = value);
      },
    );
  }

  void _showInvestmentSheet(List<AssetItem> assets) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      backgroundColor: AppTheme.sheetBackground(context),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (context) {
        return SafeBottomSheet(
          children: [
            const _SheetTitle(title: '选择投资资产'),
            const SizedBox(height: 8),
            if (assets.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text('暂无投资资产', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                ),
              )
            else
              ...assets.map((asset) {
                final selected = asset.id == _investmentAssetId;
                final symbol = asset.symbol.trim().isEmpty ? asset.name : asset.symbol.trim().toUpperCase();
                return _SheetTile(
                  selected: selected,
                  icon: Icons.show_chart_rounded,
                  title: asset.name,
                  subtitle: '$symbol · ${trimNum(asset.quantity)}',
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _investmentAssetId = asset.id);
                  },
                );
              }),
          ],
        );
      },
    );
  }

  void _showSelectionSheet<T>({
    required String title,
    required List<T> items,
    required T selected,
    required String Function(T value) labelBuilder,
    required IconData Function(T value) iconBuilder,
    required ValueChanged<T> onSelected,
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
            ...items.map((item) {
              final isSelected = item == selected;
              return _SheetTile(
                selected: isSelected,
                icon: iconBuilder(item),
                title: labelBuilder(item),
                subtitle: '',
                onTap: () {
                  Navigator.pop(context);
                  onSelected(item);
                },
              );
            }),
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
              decoration: const InputDecoration(hintText: '例如：和朋友吃午餐'),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() {});
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
    final amount = double.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) {
      Get.snackbar('记一笔', '请输入有效金额');
      return;
    }

    final existing = widget.existing;
    final linkedAsset = _findAssetById(store.billLinkedAssets, _assetId);
    final linkedInvestment = _type == 'investment' ? _findAssetById(store.billLinkedInvestments, _investmentAssetId) : null;
    if (_type == 'investment' && (linkedAsset == null || linkedInvestment == null)) {
      Get.snackbar('投资账单', '请选择资金账户和投资资产');
      return;
    }

    final investmentQuantity = linkedInvestment == null ? 0.0 : double.tryParse(_investmentQuantityController.text.trim()) ?? 0.0;
    if (_type == 'investment' && investmentQuantity <= 0) {
      Get.snackbar('投资账单', '请输入有效投资数量');
      return;
    }

    final item = BillItem(
      id: existing?.id ?? newId(),
      type: _type,
      category: _category,
      amount: amount,
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

    final Future<void> saveFuture = _isEditing ? store.updateBill(item) : store.addBill(item);
    if (mounted) Get.back<void>();
    unawaited(saveFuture.catchError((_) {}));
  }
}

class _ReferenceBillScaffold extends StatelessWidget {
  const _ReferenceBillScaffold({required this.title, required this.onSubmit, required this.child});

  final String title;
  final VoidCallback onSubmit;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final pageBackground = AppTheme.pageBackground(context);
    return Scaffold(
      backgroundColor: pageBackground,
      appBar: AppBar(
        centerTitle: true,
        title: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
        backgroundColor: pageBackground,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          onPressed: () => Get.back<void>(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
        ),
        actions: [
          IconButton(
            onPressed: onSubmit,
            icon: Icon(Icons.check_rounded, color: cs.primary, size: 24),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(child: child),
    );
  }
}

class _BillTypeSelector extends StatelessWidget {
  const _BillTypeSelector({required this.selectedType, required this.onChanged, required this.onTransferTap});

  final String selectedType;
  final ValueChanged<String> onChanged;
  final VoidCallback onTransferTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _TypeChip(
            label: '支出',
            selected: selectedType == 'expense',
            tone: _BillTone.expense,
            onTap: () => onChanged('expense'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TypeChip(
            label: '收入',
            selected: selectedType == 'income',
            tone: _BillTone.income,
            onTap: () => onChanged('income'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _TypeChip(
            label: '转账',
            selected: false,
            tone: _BillTone.transfer,
            onTap: onTransferTap,
          ),
        ),
      ],
    );
  }
}

enum _BillTone { expense, income, transfer }

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label, required this.selected, required this.tone, required this.onTap});

  final String label;
  final bool selected;
  final _BillTone tone;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = switch (tone) {
      _BillTone.expense => const Color(0xFFE95D5D),
      _BillTone.income => const Color(0xFF309B63),
      _BillTone.transfer => Theme.of(context).colorScheme.onSurfaceVariant,
    };
    return Material(
      color: selected ? color.withValues(alpha: 0.13) : Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? color.withValues(alpha: 0.42) : Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Text(
            label,
            style: TextStyle(color: selected ? color : Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w900),
          ),
        ),
      ),
    );
  }
}

class _AmountReadout extends StatelessWidget {
  const _AmountReadout({required this.currency, required this.amountText});

  final String currency;
  final String amountText;

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        '${_currencySymbol(currency)} $amountText',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w900, letterSpacing: -0.8, height: 1.05),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.type, required this.label, required this.icon, required this.onTap});

  final String type;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = type == 'income' ? const Color(0xFF309B63) : const Color(0xFFE95D5D);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: color.withValues(alpha: 0.13), shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 8),
              Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right_rounded, size: 20),
            ],
          ),
        ),
      ),
    );
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.16 : 0.035),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(children: children),
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
          child: Row(
            children: [
              SizedBox(
                width: 76,
                child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
              ),
              Expanded(
                child: Text(
                  value,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: muted ? Theme.of(context).colorScheme.onSurfaceVariant : Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _InlineInputRow extends StatelessWidget {
  const _InlineInputRow({required this.label, required this.controller, required this.hint});

  final String label;
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        children: [
          SizedBox(width: 76, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
          Expanded(
            child: TextField(
              controller: controller,
              textAlign: TextAlign.right,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(hintText: hint, border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchInfoRow extends StatelessWidget {
  const _SwitchInfoRow({required this.label, required this.value, required this.onChanged});

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w800))),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _SoftDivider extends StatelessWidget {
  const _SoftDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, indent: 16, endIndent: 16, color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.72));
  }
}

class _NumberPad extends StatelessWidget {
  const _NumberPad({required this.onKeyTap, required this.onDone});

  final ValueChanged<String> onKeyTap;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['.', '0', 'back'],
    ];
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant.withValues(alpha: 0.64))),
      ),
      child: SizedBox(
        height: 232,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Column(
                children: [
                  for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) ...[
                    Expanded(
                      child: Row(
                        children: [
                          for (var colIndex = 0; colIndex < rows[rowIndex].length; colIndex++) ...[
                            Expanded(
                              child: _PadKey(
                                label: rows[rowIndex][colIndex],
                                onTap: () => onKeyTap(rows[rowIndex][colIndex]),
                              ),
                            ),
                            if (colIndex != rows[rowIndex].length - 1) const SizedBox(width: 8),
                          ],
                        ],
                      ),
                    ),
                    if (rowIndex != rows.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 76,
              height: double.infinity,
              child: Material(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  onTap: onDone,
                  borderRadius: BorderRadius.circular(14),
                  child: Center(
                    child: Text(
                      '完成',
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PadKey extends StatelessWidget {
  const _PadKey({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isBack = label == 'back';
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerLowest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.68)),
          ),
          child: isBack
              ? const Icon(Icons.backspace_outlined, size: 20)
              : Text(label, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
        ),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 6),
      child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)),
    );
  }
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
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(14)),
                  child: Icon(icon, color: cs.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                      if (subtitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(subtitle, style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                if (selected) Icon(Icons.check_circle_rounded, color: cs.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccountOption {
  const _AccountOption({required this.id, required this.name, required this.subtitle, required this.currency, required this.amount});

  final String id;
  final String name;
  final String subtitle;
  final String currency;
  final double amount;
}

const List<String> _expenseCategories = [
  'shopping',
  'food',
  'drink',
  'transport',
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

const List<String> _investmentCategories = [
  'investmentBuy',
  'investmentSell',
];

String trBillCategory(String key) {
  const map = {
    'shopping': '日常购物',
    'food': '餐饮',
    'drink': '饮品',
    'transport': '交通出行',
    'rent': '住房',
    'utilities': '生活缴费',
    'medical': '医疗健康',
    'entertainment': '娱乐',
    'otherExpense': '其他支出',
    'salary': '工资收入',
    'bonus': '奖金',
    'partTime': '兼职收入',
    'investmentIncome': '投资收益',
    'gift': '红包礼金',
    'otherIncome': '其他收入',
    'investmentBuy': '投资买入',
    'investmentSell': '投资卖出',
  };
  return map[key] ?? 'billCategory_$key'.tr;
}


IconData _categoryIcon(String key) {
  return switch (key) {
    'shopping' => Icons.shopping_cart_rounded,
    'food' => Icons.restaurant_rounded,
    'drink' => Icons.local_cafe_rounded,
    'transport' => Icons.directions_subway_rounded,
    'rent' => Icons.home_work_rounded,
    'utilities' => Icons.bolt_rounded,
    'medical' => Icons.local_hospital_rounded,
    'entertainment' => Icons.sports_esports_rounded,
    'salary' => Icons.work_rounded,
    'bonus' => Icons.redeem_rounded,
    'partTime' => Icons.badge_rounded,
    'investmentIncome' => Icons.trending_up_rounded,
    'gift' => Icons.card_giftcard_rounded,
    'investmentBuy' => Icons.add_chart_rounded,
    'investmentSell' => Icons.sell_rounded,
    _ => Icons.more_horiz_rounded,
  };
}

String _currencySymbol(String currency) {
  return switch (currency.toUpperCase()) {
    'CNY' => '¥',
    'USD' => r'$',
    'HKD' => r'HK$',
    'EUR' => '€',
    'JPY' => '¥',
    'GBP' => '£',
    _ => currency.toUpperCase(),
  };
}

String _formatMoney(num value, String currency) {
  final negative = value < 0;
  final absValue = value.abs().toStringAsFixed(2);
  final parts = absValue.split('.');
  final intPart = parts.first;
  final buffer = StringBuffer();
  for (var i = 0; i < intPart.length; i++) {
    final fromEnd = intPart.length - i;
    buffer.write(intPart[i]);
    if (fromEnd > 1 && fromEnd % 3 == 1) buffer.write(',');
  }
  return '${negative ? '-' : ''}${_currencySymbol(currency)}${buffer.toString()}.${parts.last}';
}

String _dateLabel(DateTime value) {
  final now = DateTime.now();
  final today = value.year == now.year && value.month == now.month && value.day == now.day;
  return '${value.year}年${value.month}月${value.day}日${today ? ' 今天' : ''}';
}

String _timeText(DateTime value) {
  String two(int v) => v.toString().padLeft(2, '0');
  return '${two(value.hour)}:${two(value.minute)}';
}
