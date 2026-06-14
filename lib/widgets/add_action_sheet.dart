import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/app_theme.dart';
import 'safe_bottom_sheet.dart';


class AddActionSheet extends StatelessWidget {
  const AddActionSheet({
    super.key,
    required this.onAddAsset,
    required this.onAddInvestment,
    required this.onAddDebt,
    required this.onRefresh,
  });

  final VoidCallback onAddAsset;
  final VoidCallback onAddInvestment;
  final VoidCallback onAddDebt;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return SafeBottomSheet(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
      maxHeightFactor: 0.82,
      children: [
        Center(
          child: Container(
            width: 44,
            height: 5,
            decoration: BoxDecoration(
              color: AppTheme.textSubtle(context).withValues(alpha: 0.30),
              borderRadius: BorderRadius.circular(99),
            ),
          ),
        ),
        const SizedBox(height: 16),
        _SheetAction(icon: Icons.account_balance_wallet_rounded, title: 'addAsset'.tr, subtitle: 'addCashSubtitle'.tr, onTap: onAddAsset),
        _SheetAction(icon: Icons.trending_up_rounded, title: 'addInvestment'.tr, subtitle: 'addInvestmentSubtitle'.tr, onTap: onAddInvestment),
        _SheetAction(icon: Icons.receipt_long_rounded, title: 'addDebt'.tr, subtitle: 'addDebtSubtitle'.tr, onTap: onAddDebt),
        _SheetAction(icon: Icons.sync_rounded, title: 'refreshQuotes'.tr, subtitle: 'refreshQuotesSubtitle'.tr, onTap: onRefresh),
      ],
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({required this.icon, required this.title, required this.subtitle, required this.onTap});

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.09), borderRadius: BorderRadius.circular(16)),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                  const SizedBox(height: 3),
                  Text(subtitle, style: TextStyle(color: AppTheme.textSubtle(context))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppTheme.textSubtle(context)),
          ],
        ),
      ),
    );
  }
}
