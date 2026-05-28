import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/app_theme.dart';
import '../core/formatters.dart';
import '../core/number_utils.dart';
import '../l10n/translation_service.dart';
import '../models/asset_item.dart';
import '../models/bill_item.dart';
import '../models/debt_item.dart';
import '../services/ledger_store.dart';

class AssetTile extends StatelessWidget {
  const AssetTile({
    super.key,
    required this.item,
    required this.defaultCurrency,
    required this.valuation,
    required this.onDelete,
    required this.onEdit,
  });

  final AssetItem item;
  final String defaultCurrency;
  final Map<String, dynamic>? valuation;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final value = numFromPath(valuation, ['value']);
    final price = numFromPath(valuation, ['price']);
    final quoteCurrency = valuation?['quoteCurrency'] as String?;
    final title = _assetTitle(item);
    final subtitle = _assetSubtitle(item, price, quoteCurrency);

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => await _confirmDelete(context, item.name),
      onDismissed: (_) => onDelete(),
      background: const _DeleteBackground(),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _TypeIcon(type: item.type),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: AppTheme.textSubtle(context),
                                fontSize: 12,
                                fontWeight: FontWeight.w600)),
                      ],
                      if (item.note.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(item.note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: AppTheme.textSubtle(context),
                                fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _AmountText(
                  value: money(value, defaultCurrency),
                  secondary: _assetAmountSubtitle(context, item),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _assetTitle(AssetItem item) {
    if (item.isInvestment) {
      final symbol = item.symbol.trim();
      if (symbol.isNotEmpty) return symbol;
    }
    return item.name;
  }

  String _assetSubtitle(AssetItem item, num? price, String? quoteCurrency) {
    if (price != null) {
      return trUnitPrice(money(price, defaultCurrency), quoteCurrency);
    }
    if (item.type == 'manual') {
      return trAssetType(item.type);
    }
    return '';
  }

  String _assetAmountSubtitle(BuildContext context, AssetItem item) {
    if (item.type == 'cash') {
      return '${trimNum(item.quantity)} ${item.currency}';
    }
    if (item.type == 'manual') {
      return '${trimNum(item.quantity)} ${item.currency}';
    }
    if (item.type == 'metal') {
      return '${trimNum(item.quantity)} ${trMetalUnit(item.unit.isEmpty ? 'gram' : item.unit)}';
    }
    return trimNum(item.quantity);
  }
}

class DebtTile extends StatelessWidget {
  const DebtTile({
    super.key,
    required this.item,
    required this.defaultCurrency,
    required this.valuation,
    required this.onDelete,
    required this.onEdit,
  });

  final DebtItem item;
  final String defaultCurrency;
  final Map<String, dynamic>? valuation;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final value = numFromPath(valuation, ['value']);
    final debtMeta = _debtAmountSubtitle(item);
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => await _confirmDelete(context, item.name),
      onDismissed: (_) => onDelete(),
      background: const _DeleteBackground(),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _DebtIcon(direction: item.direction),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 16)),
                      if (item.note.trim().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(item.note,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                color: AppTheme.textSubtle(context),
                                fontSize: 12)),
                      ],
                      if (item.hasImage) ...[
                        const SizedBox(height: 8),
                        _DebtImageThumbs(images: item.imageBase64List),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _AmountText(
                  value: money(value, defaultCurrency),
                  secondary: debtMeta,
                  secondaryMaxLines: 2,
                  color: item.isPayable
                      ? const Color(0xFFD64545)
                      : const Color(0xFF248B5D),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _debtAmountSubtitle(DebtItem item) {
    final direction = trDebtDirection(item.direction);
    if (item.transactions.isEmpty) {
      return '$direction · ${trimNum(item.amount)} ${item.currency}';
    }
    return '$direction · ${'remainingAmount'.tr} ${trimNum(item.amount)} ${item.currency}\n${'settledAmount'.tr} ${trimNum(item.settledAmount)}';
  }
}

class _AmountText extends StatelessWidget {
  const _AmountText({
    required this.value,
    this.color,
    this.secondary,
    this.secondaryMaxLines = 1,
  });

  final String value;
  final Color? color;
  final String? secondary;
  final int secondaryMaxLines;

  @override
  Widget build(BuildContext context) {
    final subtitle = secondary?.trim();

    return SizedBox(
      width: 132,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 18,
                  height: 1.1,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.25,
                  color: color ?? AppTheme.textMain(context),
                ),
              ),
            ),
            if (subtitle != null && subtitle.isNotEmpty) ...[
              const SizedBox(height: 5),
              Text(
                subtitle,
                maxLines: secondaryMaxLines,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: AppTheme.textSubtle(context),
                  fontSize: 12,
                  height: 1.18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DebtIcon extends StatelessWidget {
  const _DebtIcon({required this.direction});

  final String direction;

  @override
  Widget build(BuildContext context) {
    final color = direction == 'payable'
        ? const Color(0xFFD64545)
        : const Color(0xFF248B5D);
    final icon = direction == 'payable'
        ? Icons.call_made_rounded
        : Icons.call_received_rounded;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16)),
      child: Icon(icon, color: color),
    );
  }
}

class _DebtImageThumbs extends StatelessWidget {
  const _DebtImageThumbs({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    final valid = images
        .where((e) => e.trim().isNotEmpty)
        .take(3)
        .toList(growable: false);
    if (valid.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: valid
          .map((imageBase64) => _DebtImageThumb(
                key: ValueKey(imageBase64),
                imageBase64: imageBase64,
              ))
          .toList(),
    );
  }
}

class _DebtImageThumb extends StatefulWidget {
  const _DebtImageThumb({super.key, required this.imageBase64});

  final String imageBase64;

  @override
  State<_DebtImageThumb> createState() => _DebtImageThumbState();
}

class _DebtImageThumbState extends State<_DebtImageThumb> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(covariant _DebtImageThumb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageBase64 != widget.imageBase64) {
      _decode();
    }
  }

  void _decode() {
    try {
      _bytes = base64Decode(widget.imageBase64);
    } catch (_) {
      _bytes = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    if (bytes == null) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: () => _showImagePreview(context, widget.imageBase64),
        child: Image.memory(
          bytes,
          width: 72,
          height: 54,
          fit: BoxFit.cover,
          gaplessPlayback: true,
          filterQuality: FilterQuality.low,
        ),
      ),
    );
  }
}

class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type});

  final String type;

  @override
  Widget build(BuildContext context) {
    final icon = switch (type) {
      'cash' => Icons.account_balance_wallet_rounded,
      'manual' => Icons.inventory_2_rounded,
      'crypto' => Icons.currency_bitcoin_rounded,
      'metal' => Icons.diamond_rounded,
      'stock' => Icons.show_chart_rounded,
      'etf' => Icons.pie_chart_rounded,
      'cn_stock' => Icons.trending_up_rounded,
      'cn_etf' => Icons.donut_large_rounded,
      _ => Icons.wallet_rounded,
    };
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: Theme.of(context).colorScheme.primary),
    );
  }
}

class _DeleteBackground extends StatelessWidget {
  const _DeleteBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 0),
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 22),
      decoration: BoxDecoration(
          color: const Color(0xFFD64545),
          borderRadius: BorderRadius.circular(24)),
      child: const Icon(Icons.delete_rounded, color: Colors.white),
    );
  }
}

Future<bool> _confirmDelete(BuildContext context, String title) async {
  final result = await Get.dialog<bool>(
    AlertDialog(
      title: Text('confirmDelete'.tr),
      content: Text(trDeleteCannotRecover(title)),
      actions: [
        TextButton(
            onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
        FilledButton(
            onPressed: () => Get.back(result: true), child: Text('delete'.tr)),
      ],
    ),
  );
  return result == true;
}

class BillTile extends StatelessWidget {
  const BillTile({
    super.key,
    required this.item,
    required this.onDelete,
    required this.onEdit,
  });

  final BillItem item;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    if (item.isExchangeBill) {
      return _buildExchangeBill(context);
    }
    if (item.isInvestmentBill) {
      return _buildInvestmentBill(context);
    }
    if (item.isDebtBill) {
      return _buildDebtBill(context);
    }

    final color =
        item.isIncome ? const Color(0xFF248B5D) : const Color(0xFFD64545);
    final title = _billTitle(item);
    final noteUsedAsTitle = _billUsesNoteAsTitle(item);
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async =>
          await _confirmDelete(context, _billTitle(item)),
      onDismissed: (_) => onDelete(),
      background: const _DeleteBackground(),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _BillIcon(item: item),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _billMeta(item),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: AppTheme.textSubtle(context)),
                      ),
                      if (item.note.trim().isNotEmpty && !noteUsedAsTitle) ...[
                        const SizedBox(height: 4),
                        Text(
                          item.note,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: AppTheme.textSubtle(context),
                              fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _AmountText(
                  value:
                      '${item.isIncome ? '+' : '-'}${money(item.amount, item.currency)}',
                  color: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }


  Widget _buildDebtBill(BuildContext context) {
    final debtName = item.debtName.trim().isEmpty ? 'debt'.tr : item.debtName.trim();
    final fundName = item.assetName.trim().isEmpty ? 'fundAccount'.tr : item.assetName.trim();

    if (item.category == 'debtRepayment') {
      return _FlowBillCard(
        item: item,
        deleteTitle: '${'repayment'.tr} · $debtName',
        icon: Icons.payments_rounded,
        leftLabel: fundName,
        leftValue: '-${money(item.amount, item.currency)}',
        leftColor: const Color(0xFFD64545),
        rightLabel: debtName,
        rightValue: '-${money(item.amount, item.currency)}',
        rightColor: const Color(0xFF248B5D),
        onTap: onEdit,
        onDelete: onDelete,
      );
    }

    if (item.category == 'debtCollection') {
      return _FlowBillCard(
        item: item,
        deleteTitle: '${'collection'.tr} · $debtName',
        icon: Icons.call_received_rounded,
        leftLabel: debtName,
        leftValue: '-${money(item.amount, item.currency)}',
        leftColor: const Color(0xFFD64545),
        rightLabel: fundName,
        rightValue: '+${money(item.amount, item.currency)}',
        rightColor: const Color(0xFF248B5D),
        onTap: onEdit,
        onDelete: onDelete,
      );
    }

    final isReceivable = item.category == 'debtReceivable' || item.debtDirection == 'receivable';
    final color = isReceivable ? const Color(0xFF248B5D) : const Color(0xFFD64545);
    final icon = isReceivable ? Icons.call_received_rounded : Icons.call_made_rounded;
    final title = trBillCategory(item.category);
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => await _confirmDelete(context, '$title · $debtName'),
      onDismissed: (_) => onDelete(),
      background: const _DeleteBackground(),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onEdit,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(debtName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.textSubtle(context))),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _AmountText(value: money(item.amount, item.currency), color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInvestmentBill(BuildContext context) {
    final isSell = item.isInvestmentSell;
    final investmentName = _investmentDisplayName(item);
    final fundName = item.assetName.trim().isEmpty
        ? 'linkedAsset'.tr
        : item.assetName.trim();

    final leftLabel = isSell ? investmentName : fundName;
    final leftValue = isSell
        ? '-${trimNum(item.investmentQuantity)}'
        : '-${money(item.amount, item.currency)}';
    const leftColor = Color(0xFFD64545);

    final rightLabel = isSell ? fundName : investmentName;
    final rightValue = isSell
        ? '+${money(item.amount, item.currency)}'
        : '+${trimNum(item.investmentQuantity)}';
    const rightColor = Color(0xFF248B5D);

    return _FlowBillCard(
      item: item,
      deleteTitle: investmentName,
      icon: Icons.show_chart_rounded,
      leftLabel: leftLabel,
      leftValue: leftValue,
      leftColor: leftColor,
      rightLabel: rightLabel,
      rightValue: rightValue,
      rightColor: rightColor,
      onTap: onEdit,
      onDelete: onDelete,
    );
  }

  Widget _buildExchangeBill(BuildContext context) {
    final fromName = item.assetName.trim().isEmpty
        ? 'fromFundAccount'.tr
        : item.assetName.trim();
    final toName = item.toAssetName.trim().isEmpty
        ? 'toFundAccount'.tr
        : item.toAssetName.trim();

    return _FlowBillCard(
      item: item,
      deleteTitle: '${'exchangeBill'.tr} $fromName → $toName',
      icon: Icons.swap_horiz_rounded,
      leftLabel: fromName,
      leftValue: '-${money(item.amount, item.currency)}',
      leftColor: const Color(0xFFD64545),
      rightLabel: toName,
      rightValue:
          '+${money(item.toAmount, item.toCurrency.trim().isEmpty ? item.currency : item.toCurrency)}',
      rightColor: const Color(0xFF248B5D),
      onTap: onEdit,
      onDelete: onDelete,
    );
  }
}

class _FlowBillCard extends StatelessWidget {
  const _FlowBillCard({
    required this.item,
    required this.deleteTitle,
    required this.icon,
    required this.leftLabel,
    required this.leftValue,
    required this.leftColor,
    required this.rightLabel,
    required this.rightValue,
    required this.rightColor,
    required this.onTap,
    required this.onDelete,
  });

  final BillItem item;
  final String deleteTitle;
  final IconData icon;
  final String leftLabel;
  final String leftValue;
  final Color leftColor;
  final String rightLabel;
  final String rightValue;
  final Color rightColor;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    // 理财 / 换汇是资产内部流转，账单卡片只展示“从哪出 → 到哪入”。
    // 不再额外显示日期、备注等占空间信息，避免系统字体放大后金额被截断。
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => await _confirmDelete(context, deleteTitle),
      onDismissed: (_) => onDelete(),
      background: const _DeleteBackground(),
      child: Card(
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: _FlowSide(
                    label: leftLabel,
                    value: leftValue,
                    color: leftColor,
                    alignRight: false,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .primary
                        .withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon,
                      size: 22, color: Theme.of(context).colorScheme.primary),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _FlowSide(
                    label: rightLabel,
                    value: rightValue,
                    color: rightColor,
                    alignRight: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FlowSide extends StatelessWidget {
  const _FlowSide({
    required this.label,
    required this.value,
    required this.color,
    required this.alignRight,
  });

  final String label;
  final String value;
  final Color color;
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    final align =
        alignRight ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final textAlign = alignRight ? TextAlign.right : TextAlign.left;
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            height: 1.15,
            color: AppTheme.textMain(context),
          ),
        ),
        const SizedBox(height: 7),
        SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment:
                alignRight ? Alignment.centerRight : Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              textAlign: textAlign,
              style: TextStyle(
                fontSize: 17,
                height: 1.1,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.25,
                color: color,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

String _investmentDisplayName(BillItem item) {
  try {
    final store = Get.find<LedgerStore>();
    for (final asset in store.assets) {
      if (asset.id != item.investmentAssetId) continue;
      final symbol = asset.symbol.trim();
      if (symbol.isNotEmpty) return symbol;
      final name = asset.name.trim();
      if (name.isNotEmpty) return name;
      break;
    }
  } catch (_) {
    // Tile can still render from the bill snapshot if the store is not available.
  }
  final snapshot = item.investmentAssetName.trim();
  return snapshot.isEmpty ? 'investment'.tr : snapshot;
}

String _billTitle(BillItem item) {
  final note = item.note.trim();
  if (_billUsesNoteAsTitle(item)) {
    return note;
  }
  return trBillCategory(item.category);
}

bool _billUsesNoteAsTitle(BillItem item) {
  final note = item.note.trim();
  if (note.isEmpty) return false;
  return item.category == 'otherExpense' || item.category == 'otherIncome';
}

String _billMeta(BillItem item) {
  // 普通收入/支出卡片尽量简约：标题显示分类/备注，下面优先显示资金账户。
  // 没有绑定资金账户时再显示日期，避免一行里信息过多导致大字体被截断。
  final assetName = item.assetName.trim();
  if (assetName.isNotEmpty) return assetName;
  return dateText(item.occurredAt);
}

void _showImagePreview(BuildContext context, String imageBase64) {
  try {
    final bytes = base64Decode(imageBase64);
    Get.dialog<void>(
      Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.memory(bytes,
                    fit: BoxFit.contain, gaplessPlayback: true),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton.filled(
                onPressed: () => Get.back<void>(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  } catch (_) {
    // Ignore broken local image data.
  }
}

class _BillIcon extends StatelessWidget {
  const _BillIcon({required this.item});

  final BillItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.isInvestmentBill
        ? Theme.of(context).colorScheme.primary
        : (item.isIncome ? const Color(0xFF248B5D) : const Color(0xFFD64545));
    final icon = item.isInvestmentBill
        ? Icons.swap_horiz_rounded
        : _billIconData(item.category, item.isIncome);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16)),
      child: Icon(icon, color: color),
    );
  }
}

IconData _billIconData(String category, bool income) {
  if (income) {
    return switch (category) {
      'salary' => Icons.payments_rounded,
      'bonus' => Icons.card_giftcard_rounded,
      'partTime' => Icons.work_rounded,
      'investmentIncome' => Icons.trending_up_rounded,
      'gift' => Icons.redeem_rounded,
      _ => Icons.add_card_rounded,
    };
  }
  return switch (category) {
    'food' => Icons.restaurant_rounded,
    'drink' => Icons.local_cafe_rounded,
    'transport' => Icons.directions_bus_rounded,
    'shopping' => Icons.shopping_bag_rounded,
    'rent' => Icons.home_rounded,
    'utilities' => Icons.bolt_rounded,
    'medical' => Icons.local_hospital_rounded,
    'entertainment' => Icons.movie_rounded,
    _ => Icons.receipt_long_rounded,
  };
}
