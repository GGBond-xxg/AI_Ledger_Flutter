import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../core/formatters.dart';
import '../services/ledger_store.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.store});

  final LedgerStore store;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final currency = store.settings.defaultCurrency;
      final scheme = Theme.of(context).colorScheme;
      final background = scheme.primaryContainer;
      final foreground = scheme.onPrimaryContainer;
      final subtle = foreground.withValues(alpha: 0.72);

      return Card(
        color: background,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            color: background,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'netWorth'.tr,
                      style: TextStyle(color: subtle),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 180),
                    child: store.showRefreshSpinner
                        ? SizedBox(
                            key: const ValueKey('summary-loading'),
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: foreground,
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
                  style: TextStyle(
                    color: foreground,
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
                      value: money(store.assetTotal, currency,
                          showCurrency: false),
                      foreground: foreground,
                      subtle: subtle,
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      title: 'receivable'.tr,
                      value: money(store.receivableTotal, currency,
                          showCurrency: false),
                      foreground: foreground,
                      subtle: subtle,
                    ),
                  ),
                  Expanded(
                    child: _Metric(
                      title: 'payable'.tr,
                      value: money(store.payableTotal, currency,
                          showCurrency: false),
                      foreground: foreground,
                      subtle: subtle,
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
                      style: TextStyle(color: subtle, fontSize: 12),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _SummaryActionChip(
                    icon: store.settings.showZeroItems
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    label: store.settings.showZeroItems
                        ? 'hideZeroItems'.tr
                        : 'showZeroItems'.tr,
                    foreground: foreground,
                    onTap: () => store.toggleShowZeroItems(),
                  ),
                  const SizedBox(width: 6),
                  _SummaryActionChip(
                    icon: store.settings.assetSortAscending
                        ? Icons.arrow_upward_rounded
                        : Icons.arrow_downward_rounded,
                    label: store.settings.assetSortAscending
                        ? 'sortSmallToLarge'.tr
                        : 'sortLargeToSmall'.tr,
                    foreground: foreground,
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
  const _Metric({
    required this.title,
    required this.value,
    required this.foreground,
    required this.subtle,
  });

  final String title;
  final String value;
  final Color foreground;
  final Color subtle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(color: subtle, fontSize: 12),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.visible,
            style: TextStyle(
              color: foreground,
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
    required this.foreground,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color foreground;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: foreground.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: foreground.withValues(alpha: 0.08)),
          ),
          child: Icon(icon, color: foreground, size: 15),
        ),
      ),
    );
  }
}
