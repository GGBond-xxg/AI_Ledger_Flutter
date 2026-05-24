import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF4D5F91);

  static const lightBackground = Colors.white;
  static const lightCard = Color(0xFFF8FAFC);
  static const lightTextMain = Color(0xFF111827);
  static const lightTextSubtle = Color(0xFF7A8192);

  static const darkBackground = Color(0xFF11151D);
  static const darkCard = Color(0xFF1B202A);
  static const darkInput = Color(0xFF252B36);
  static const darkTextMain = Color(0xFFF7F8FC);
  static const darkTextSubtle = Color(0xFFA7B0C2);

  static ThemeData light() {
    return _base(
      brightness: Brightness.light,
      scaffoldBackground: lightBackground,
      cardColor: lightCard,
      inputFill: const Color(0xFFF3F5F8),
      textMain: lightTextMain,
      textSubtle: lightTextSubtle,
    );
  }

  static ThemeData dark() {
    return _base(
      brightness: Brightness.dark,
      scaffoldBackground: darkBackground,
      cardColor: darkCard,
      inputFill: darkInput,
      textMain: darkTextMain,
      textSubtle: darkTextSubtle,
    );
  }

  static ThemeData _base({
    required Brightness brightness,
    required Color scaffoldBackground,
    required Color cardColor,
    required Color inputFill,
    required Color textMain,
    required Color textSubtle,
  }) {
    final colorScheme = ColorScheme.fromSeed(seedColor: primary, brightness: brightness);
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: scaffoldBackground,
      colorScheme: colorScheme,
      textTheme: Typography.material2021(platform: TargetPlatform.android).black.apply(
            bodyColor: textMain,
            displayColor: textMain,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: scaffoldBackground,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: textMain),
        titleTextStyle: TextStyle(
          color: textMain,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.38), width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: textSubtle),
        hintStyle: TextStyle(color: textSubtle.withValues(alpha: 0.78)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      dividerTheme: DividerThemeData(color: textSubtle.withValues(alpha: 0.16)),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: textSubtle.withValues(alpha: 0.24)),
          foregroundColor: textMain,
        ),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: cardColor,
        textStyle: TextStyle(color: textMain),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: brightness == Brightness.dark ? const Color(0xFF1F2937) : Colors.white,
        contentTextStyle: TextStyle(color: textMain, fontWeight: FontWeight.w700),
        actionTextColor: colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  static Color cardColor(BuildContext context) => Theme.of(context).cardTheme.color ?? (isDark(context) ? darkCard : lightCard);
  static Color inputColor(BuildContext context) => isDark(context) ? darkInput : const Color(0xFFF3F5F8);
  static Color textMain(BuildContext context) => isDark(context) ? darkTextMain : lightTextMain;
  static Color textSubtle(BuildContext context) => isDark(context) ? darkTextSubtle : lightTextSubtle;
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
}
