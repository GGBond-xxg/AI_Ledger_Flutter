import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../app/app_theme.dart';

void showAppToast(
  String message, {
  String? title,
  IconData icon = Icons.info_rounded,
}) {
  Get.closeAllSnackbars();

  final context = Get.context;
  final isDark = context == null ? Get.isDarkMode : AppTheme.isDark(context);
  final backgroundColor = isDark ? const Color(0xFF1F2937) : Colors.white;
  final titleColor = isDark ? AppTheme.darkTextMain : AppTheme.lightTextMain;
  final messageColor = isDark ? AppTheme.darkTextSubtle : AppTheme.lightTextSubtle;
  final primaryColor = context == null ? AppTheme.primary : Theme.of(context).colorScheme.primary;

  Get.snackbar(
    title ?? 'appTitle'.tr,
    message,
    snackPosition: SnackPosition.BOTTOM,
    duration: const Duration(seconds: 2),
    margin: const EdgeInsets.all(14),
    borderRadius: 20,
    backgroundColor: backgroundColor.withValues(alpha: 0.96),
    colorText: titleColor,
    isDismissible: true,
    dismissDirection: DismissDirection.horizontal,
    boxShadows: [
      BoxShadow(
        color: Colors.black.withValues(alpha: isDark ? 0.34 : 0.12),
        blurRadius: 24,
        offset: const Offset(0, 10),
      ),
    ],
    icon: Padding(
      padding: const EdgeInsets.only(left: 12),
      child: Icon(icon, color: primaryColor),
    ),
    titleText: Text(
      title ?? 'appTitle'.tr,
      style: TextStyle(
        color: titleColor,
        fontSize: 15,
        fontWeight: FontWeight.w900,
      ),
    ),
    messageText: Text(
      message,
      style: TextStyle(
        color: messageColor,
        fontSize: 13.5,
        height: 1.35,
        fontWeight: FontWeight.w600,
      ),
    ),
  );
}
