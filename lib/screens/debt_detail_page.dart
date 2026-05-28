import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/app_theme.dart';
import '../core/app_toast.dart';
import '../core/id.dart';
import '../core/formatters.dart';
import '../l10n/translation_service.dart';
import '../models/asset_item.dart';
import '../models/debt_item.dart';
import '../services/ledger_store.dart';
import '../widgets/common_cards.dart';
import '../widgets/form_fields.dart';
import 'debt_form_page.dart';

class DebtDetailPage extends StatefulWidget {
  const DebtDetailPage({super.key, required this.debtId});

  final String debtId;

  @override
  State<DebtDetailPage> createState() => _DebtDetailPageState();
}

class _DebtDetailPageState extends State<DebtDetailPage> {
  final LedgerStore store = Get.find<LedgerStore>();
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  final _newAssetNameController = TextEditingController();

  static const _newAssetValue = '__new_debt_fund_asset__';

  String _assetId = '';
  bool _submitting = false;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _newAssetNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final debt = _currentDebt();
      if (debt == null) {
        return Scaffold(
          appBar: AppBar(title: Text('debtDetail'.tr)),
          body: Center(child: Text('debtNotFound'.tr)),
        );
      }

      final fundAssets = store.debtFundAssets(debt.currency);
      final currentAssetId = _validAssetId(fundAssets);
      final actionLabel = debt.isPayable ? 'recordRepayment'.tr : 'recordCollection'.tr;

      return Scaffold(
        appBar: AppBar(
          title: Text('debtDetail'.tr),
          actions: [
            IconButton(
              tooltip: 'editDebt'.tr,
              onPressed: () => Get.to<void>(() => DebtFormPage(existing: debt)),
              icon: const Icon(Icons.edit_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DebtDetailHeader(debt: debt),
                const SizedBox(height: 14),
                if (debt.isSettled)
                  const _SettledNotice()
                else
                  Form(
                    key: _formKey,
                    child: FormCard(
                      children: [
                        _SettlementTitle(debt: debt),
                        const SizedBox(height: 14),
                        LedgerDropdownField<String>(
                          label: 'fundAccount'.tr,
                          value: currentAssetId,
                          items: [
                            ...fundAssets.map((asset) => DropdownMenuItem<String>(
                                  value: asset.id,
                                  child: Text(_fundAssetLabel(asset)),
                                )),
                            DropdownMenuItem<String>(value: _newAssetValue, child: Text('createNewFundAccount'.tr)),
                          ],
                          onChanged: (value) {
                            setState(() {
                              _assetId = value ?? _assetId;
                              if (_assetId == _newAssetValue && _newAssetNameController.text.trim().isEmpty) {
                                _newAssetNameController.text = 'fundAccount'.tr;
                              }
                            });
                          },
                        ),
                        if (currentAssetId == _newAssetValue)
                          LedgerTextField(
                            controller: _newAssetNameController,
                            label: 'newFundAccountName'.tr,
                            hint: 'newFundAccountNameHint'.tr,
                            validator: (value) => value == null || value.trim().isEmpty ? 'enterName'.tr : null,
                          ),
                        LedgerTextField(
                          controller: _amountController,
                          label: debt.isPayable ? 'repayAmount'.tr : 'collectAmount'.tr,
                          hint: '${'maxAmount'.tr} ${money(debt.amount, debt.currency)}',
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          validator: (value) {
                            final number = double.tryParse(value?.trim() ?? '');
                            if (number == null || number <= 0) return 'enterPositiveAmount'.tr;
                            if (number > debt.amount + 0.000000001) {
                              return '${'amountCannotExceed'.tr} ${money(debt.amount, debt.currency)}';
                            }
                            return null;
                          },
                        ),
                        LedgerTextField(
                          controller: _noteController,
                          label: 'noteOptional'.tr,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton.icon(
                            onPressed: _submitting ? null : () => _submit(debt, currentAssetId),
                            icon: _submitting
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(debt.isPayable ? Icons.call_made_rounded : Icons.call_received_rounded),
                            label: Text(actionLabel),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                SectionHeader(
                  title: 'debtHistory'.tr,
                  description: 'debtHistoryDesc'.tr,
                ),
                if (debt.transactions.isEmpty)
                  _EmptyHistoryCard(debt: debt)
                else
                  ...debt.transactions.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _DebtTransactionTile(
                        transaction: item,
                        onDelete: () => _deleteTransaction(debt, item),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
    });
  }

  DebtItem? _currentDebt() {
    for (final item in store.debts) {
      if (item.id == widget.debtId) return item;
    }
    return null;
  }

  String _validAssetId(List<AssetItem> assets) {
    if (_assetId == _newAssetValue || assets.isEmpty) return _newAssetValue;
    if (_assetId.trim().isNotEmpty && assets.any((item) => item.id == _assetId)) {
      return _assetId;
    }
    return assets.first.id;
  }

  String _fundAssetLabel(AssetItem asset) {
    return '${asset.name} · ${asset.currency} ${trimNum(asset.quantity)}';
  }

  Future<void> _submit(DebtItem debt, String assetId) async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text.trim());

    final creatingAsset = assetId == _newAssetValue;
    final AssetItem? newAsset = creatingAsset
        ? AssetItem(
            id: newId(),
            name: _newAssetNameController.text.trim(),
            type: 'cash',
            quantity: 0,
            currency: debt.currency,
          )
        : null;

    setState(() => _submitting = true);
    await store.settleDebtWithOptionalNewCashAsset(
      debtId: debt.id,
      assetId: newAsset?.id ?? assetId,
      amount: amount,
      newCashAsset: newAsset,
      note: _noteController.text.trim(),
    );
    await store.refreshValuation(force: true, source: 'debtSettlement');
    if (!mounted) return;
    _amountController.clear();
    _noteController.clear();
    setState(() => _submitting = false);
    showAppToast(
      debt.isPayable ? 'repaymentSaved'.tr : 'collectionSaved'.tr,
      title: 'debtDetail'.tr,
      icon: Icons.check_circle_rounded,
    );
  }

  Future<void> _deleteTransaction(DebtItem debt, DebtTransaction transaction) async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('confirmDelete'.tr),
        content: Text('deleteDebtTransactionTip'.tr),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
          FilledButton(onPressed: () => Get.back(result: true), child: Text('delete'.tr)),
        ],
      ),
    );
    if (confirmed != true) return;
    await store.removeDebtTransaction(debtId: debt.id, transactionId: transaction.id);
    await store.refreshValuation(force: true, source: 'debtTransactionDeleted');
  }
}

class _DebtDetailHeader extends StatelessWidget {
  const _DebtDetailHeader({required this.debt});

  final DebtItem debt;

  @override
  Widget build(BuildContext context) {
    final color = debt.isPayable ? const Color(0xFFD64545) : const Color(0xFF248B5D);
    final icon = debt.isPayable ? Icons.call_made_rounded : Icons.call_received_rounded;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        trDebtDirection(debt.direction),
                        style: TextStyle(color: AppTheme.textSubtle(context), fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('remainingAmount'.tr, style: TextStyle(color: AppTheme.textSubtle(context), fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                money(debt.amount, debt.currency),
                style: TextStyle(fontSize: 30, height: 1.08, fontWeight: FontWeight.w900, color: color),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MiniDebtStat(label: 'originalDebtAmount'.tr, value: money(debt.originalAmount, debt.currency)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniDebtStat(label: 'settledAmount'.tr, value: money(debt.settledAmount, debt.currency)),
                ),
              ],
            ),
            if (debt.note.trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(debt.note, style: TextStyle(color: AppTheme.textSubtle(context), height: 1.45)),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniDebtStat extends StatelessWidget {
  const _MiniDebtStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.inputColor(context),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.textSubtle(context), fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 5),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          ),
        ],
      ),
    );
  }
}

class _SettlementTitle extends StatelessWidget {
  const _SettlementTitle({required this.debt});

  final DebtItem debt;

  @override
  Widget build(BuildContext context) {
    final label = debt.isPayable ? 'recordRepayment'.tr : 'recordCollection'.tr;
    final desc = debt.isPayable ? 'repaymentFormDesc'.tr : 'collectionFormDesc'.tr;
    final color = debt.isPayable ? const Color(0xFFD64545) : const Color(0xFF248B5D);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(debt.isPayable ? Icons.payments_rounded : Icons.add_card_rounded, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              const SizedBox(height: 4),
              Text(desc, style: TextStyle(color: AppTheme.textSubtle(context), height: 1.45)),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettledNotice extends StatelessWidget {
  const _SettledNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF248B5D).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_rounded, color: Color(0xFF248B5D)),
          const SizedBox(width: 10),
          Expanded(child: Text('debtSettledTip'.tr, style: const TextStyle(color: Color(0xFF248B5D), fontWeight: FontWeight.w800))),
        ],
      ),
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard({required this.debt});

  final DebtItem debt;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor(context),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Text(
        debt.isPayable ? 'emptyRepaymentHistory'.tr : 'emptyCollectionHistory'.tr,
        style: TextStyle(color: AppTheme.textSubtle(context), height: 1.45),
      ),
    );
  }
}

class _DebtTransactionTile extends StatelessWidget {
  const _DebtTransactionTile({
    required this.transaction,
    required this.onDelete,
  });

  final DebtTransaction transaction;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isRepayment = transaction.isRepayment;
    final color = isRepayment ? const Color(0xFFD64545) : const Color(0xFF248B5D);
    final title = isRepayment ? 'repayment'.tr : 'collection'.tr;
    final assetName = transaction.assetName.trim().isEmpty ? 'fundAccount'.tr : transaction.assetName.trim();
    final sign = isRepayment ? '-' : '+';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(isRepayment ? Icons.call_made_rounded : Icons.call_received_rounded, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$title · $assetName', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900)),
                  const SizedBox(height: 5),
                  Text(dateText(transaction.occurredAt), style: TextStyle(color: AppTheme.textSubtle(context), fontSize: 12)),
                  if (transaction.note.trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(transaction.note, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.textSubtle(context), fontSize: 12)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$sign${money(transaction.amount, transaction.currency)}',
                    style: TextStyle(fontWeight: FontWeight.w900, color: color, fontSize: 16),
                  ),
                ),
                const SizedBox(height: 2),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                    child: Text('delete'.tr, style: TextStyle(color: AppTheme.textSubtle(context), fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
