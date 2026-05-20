import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/app_theme.dart';
import '../core/formatters.dart';
import '../core/number_utils.dart';
import '../l10n/translation_service.dart';
import '../models/asset_item.dart';
import '../models/debt_item.dart';

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
                      Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text(_assetMeta(context, item), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.textSubtle(context))),
                      if (price != null) ...[
                        const SizedBox(height: 4),
                        Text(trUnitPrice(money(price, defaultCurrency), quoteCurrency), maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.textSubtle(context), fontSize: 12)),
                      ],
                      if (item.note.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(item.note, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.textSubtle(context), fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _AmountText(value: money(value, defaultCurrency)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _assetMeta(BuildContext context, AssetItem item) {
    if (item.type == 'cash') return '${trAssetType(item.type)} · ${trimNum(item.quantity)} ${item.currency}';
    if (item.type == 'manual') return '${trAssetType(item.type)} · ${trimNum(item.quantity)} × ${trimNum(item.manualPrice)} ${item.currency}';
    if (item.type == 'metal') return '${trAssetType(item.type)} · ${item.symbol} · ${trimNum(item.quantity)} ${item.unit.isEmpty ? 'gram' : item.unit}';
    return '${trAssetType(item.type)} · ${item.symbol} · ${trimNum(item.quantity)}';
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
                      Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      const SizedBox(height: 6),
                      Text('${trDebtDirection(item.direction)} · ${trimNum(item.amount)} ${item.currency}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.textSubtle(context))),
                      if (item.note.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(item.note, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppTheme.textSubtle(context), fontSize: 12)),
                      ],
                      if (item.hasImage) ...[
                        const SizedBox(height: 8),
                        _DebtImageThumb(imageBase64: item.imageBase64),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _AmountText(value: money(value, defaultCurrency), color: item.isPayable ? const Color(0xFFD64545) : const Color(0xFF248B5D)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AmountText extends StatelessWidget {
  const _AmountText({required this.value, this.color});

  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 118,
      child: Center(
        child: Align(
          alignment: Alignment.centerRight,
          child: FittedBox(
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
    final color = direction == 'payable' ? const Color(0xFFD64545) : const Color(0xFF248B5D);
    final icon = direction == 'payable' ? Icons.call_made_rounded : Icons.call_received_rounded;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(16)),
      child: Icon(icon, color: color),
    );
  }
}

class _DebtImageThumb extends StatelessWidget {
  const _DebtImageThumb({required this.imageBase64});

  final String imageBase64;

  @override
  Widget build(BuildContext context) {
    try {
      final bytes = base64Decode(imageBase64);
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.memory(bytes, width: 110, height: 74, fit: BoxFit.cover),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
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
      decoration: BoxDecoration(color: const Color(0xFFD64545), borderRadius: BorderRadius.circular(24)),
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
        TextButton(onPressed: () => Get.back(result: false), child: Text('cancel'.tr)),
        FilledButton(onPressed: () => Get.back(result: true), child: Text('delete'.tr)),
      ],
    ),
  );
  return result == true;
}
