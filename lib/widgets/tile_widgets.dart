import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/app_theme.dart';
import '../core/formatters.dart';
import '../core/number_utils.dart';
import '../l10n/translation_service.dart';
import '../models/asset_item.dart';
import '../models/bill_item.dart';
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
    if (item.type == 'cash') return '${item.currency} · ${trimNum(item.quantity)}';
    if (item.type == 'manual') return '${item.currency} · ${trimNum(item.quantity)} × ${trimNum(item.manualPrice)}';
    if (item.type == 'metal') return '${item.symbol} · ${trimNum(item.quantity)} ${trMetalUnit(item.unit.isEmpty ? 'gram' : item.unit)}';
    return '${item.symbol} · ${trimNum(item.quantity)}';
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
                        _DebtImageThumbs(images: item.imageBase64List),
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

class _DebtImageThumbs extends StatelessWidget {
  const _DebtImageThumbs({required this.images});

  final List<String> images;

  @override
  Widget build(BuildContext context) {
    final valid = images.where((e) => e.trim().isNotEmpty).take(3).toList(growable: false);
    if (valid.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: valid.map((imageBase64) {
        try {
          final bytes = base64Decode(imageBase64);
          return ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.memory(bytes, width: 72, height: 54, fit: BoxFit.cover),
          );
        } catch (_) {
          return const SizedBox.shrink();
        }
      }).toList(),
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
    final color = item.isIncome ? const Color(0xFF248B5D) : const Color(0xFFD64545);
    final title = _billTitle(item);
    final noteUsedAsTitle = _billUsesNoteAsTitle(item);
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async => await _confirmDelete(context, _billTitle(item)),
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
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
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
                          style: TextStyle(color: AppTheme.textSubtle(context), fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _AmountText(
                  value: '${item.isIncome ? '+' : '-'}${money(item.amount, item.currency)}',
                  color: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


String _billMeta(BillItem item) {
  final parts = <String>[
    trBillCategory(item.category),
  ];
  if (item.assetName.trim().isNotEmpty) {
    parts.add(item.assetName.trim());
  }
  parts.add(dateText(item.occurredAt));
  return parts.join(' · ');
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

class _BillIcon extends StatelessWidget {
  const _BillIcon({required this.item});

  final BillItem item;

  @override
  Widget build(BuildContext context) {
    final color = item.isIncome ? const Color(0xFF248B5D) : const Color(0xFFD64545);
    final icon = _billIconData(item.category, item.isIncome);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(16)),
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
