import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/app_theme.dart';
import '../core/formatters.dart';
import '../services/ledger_store.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.store});

  final LedgerStore store;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currency = store.settings.defaultCurrency;

      return Card(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: AppTheme.isDark(context) ? const Color(0xFF26334A) : const Color(0xFF2F4668),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'netWorth'.tr,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: store.showRefreshSpinner
                        ? const SizedBox(
                            key: ValueKey('summary-loading'),
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const SizedBox(
                            key: ValueKey('summary-idle'),
                            width: 16,
                            height: 16,
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  money(store.netWorth, currency),
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1.2,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _Metric(
                      title: 'assets'.tr,
                      value: money(store.assetTotal, currency, showCurrency: false),
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      title: 'receivable'.tr,
                      value: money(store.receivableTotal, currency, showCurrency: false),
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      title: 'payable'.tr,
                      value: money(store.payableTotal, currency, showCurrency: false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${'updatedAt'.tr}：${shortTime(store.updatedAt, fallback: 'notRefreshed'.tr)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SummaryActionChip(
                    icon: store.settings.showZeroItems
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    label: store.settings.showZeroItems ? 'hideZeroItems'.tr : 'showZeroItems'.tr,
                    onTap: () => store.toggleShowZeroItems(),
                  ),
                  const SizedBox(width: 6),
                  _SummaryActionChip(
                    icon: store.settings.assetSortAscending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    label: store.settings.assetSortAscending ? 'sortSmallToLarge'.tr : 'sortLargeToSmall'.tr,
                    onTap: () => store.toggleAssetSortOrder(),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}


class _SummaryActionChip extends StatelessWidget {
  const _SummaryActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          height: 30,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 15),
              const SizedBox(width: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 42),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
