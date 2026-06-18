import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF3F6DF6);
  static const lightPageBackground = Color(0xFFF8F6FF);
  static const lightSheetBackground = Color(0xFFFAF8FF);

  // Legacy text colors kept for older helpers that still read AppTheme directly.
  // The main UI now uses Material 3 ColorScheme through textMain/textSubtle.
  static const lightTextMain = Color(0xFF101828);
  static const lightTextSubtle = Color(0xFF667085);
  static const darkTextMain = Color(0xFFF8FAFC);
  static const darkTextSubtle = Color(0xFFCBD5E1);

  static ThemeData light({ColorScheme? dynamicScheme}) {
    return _base(dynamicScheme ?? ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.light));
  }

  static ThemeData dark({ColorScheme? dynamicScheme}) {
    return _base(dynamicScheme ?? ColorScheme.fromSeed(seedColor: primary, brightness: Brightness.dark));
  }

  static ThemeData _base(ColorScheme colorScheme) {
    final brightness = colorScheme.brightness;
    final isDarkMode = brightness == Brightness.dark;
    final pageSurface = isDarkMode ? colorScheme.surface : lightPageBackground;
    final cardSurface = colorScheme.surfaceContainerLow;
    final inputSurface = colorScheme.surfaceContainerHighest.withValues(alpha: isDarkMode ? 0.58 : 0.72);
    final subtle = colorScheme.onSurfaceVariant;

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: Colors.transparent,
      scaffoldBackgroundColor: pageSurface,
      colorScheme: colorScheme,
      textTheme: Typography.material2021(platform: TargetPlatform.android)
          .black
          .apply(bodyColor: colorScheme.onSurface, displayColor: colorScheme.onSurface),
      appBarTheme: AppBarTheme(
        backgroundColor: pageSurface,
        foregroundColor: colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputSurface,
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
          borderSide: BorderSide(color: colorScheme.primary.withValues(alpha: 0.42), width: 1.2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.error.withValues(alpha: 0.62), width: 1.1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colorScheme.error, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        labelStyle: TextStyle(color: subtle),
        hintStyle: TextStyle(color: subtle.withValues(alpha: 0.78)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardSurface,
        indicatorColor: colorScheme.secondaryContainer,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? colorScheme.onSecondaryContainer : subtle,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? colorScheme.onSecondaryContainer : subtle);
        }),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: colorScheme.primaryContainer,
        foregroundColor: colorScheme.onPrimaryContainer,
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: colorScheme.outlineVariant),
          foregroundColor: colorScheme.onSurface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? colorScheme.onPrimary : colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected)
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest;
        }),
      ),
      dividerTheme: DividerThemeData(color: colorScheme.outlineVariant.withValues(alpha: 0.65)),
      popupMenuTheme: PopupMenuThemeData(
        color: colorScheme.surfaceContainer,
        surfaceTintColor: Colors.transparent,
        textStyle: TextStyle(color: colorScheme.onSurface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colorScheme.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDarkMode ? colorScheme.surfaceContainerLow : lightSheetBackground,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: isDarkMode ? colorScheme.surfaceContainerLow : lightSheetBackground,
        modalBarrierColor: Colors.black.withValues(alpha: isDarkMode ? 0.52 : 0.38),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: colorScheme.onInverseSurface, fontWeight: FontWeight.w700),
        actionTextColor: colorScheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
    );
  }

  static Color pageBackground(BuildContext context) => Theme.of(context).scaffoldBackgroundColor;

  static Color sheetBackground(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return isDark(context) ? colorScheme.surfaceContainerLow : lightSheetBackground;
  }

  static EdgeInsets pageInsets({double bottom = 24}) => EdgeInsets.fromLTRB(16, 8, 16, bottom);

  static Color sheetColor(BuildContext context) => sheetBackground(context);
  static Color cardColor(BuildContext context) => Theme.of(context).cardTheme.color ?? Theme.of(context).colorScheme.surfaceContainerLow;
  static Color inputColor(BuildContext context) => Theme.of(context).inputDecorationTheme.fillColor ?? Theme.of(context).colorScheme.surfaceContainerHighest;
  static Color textMain(BuildContext context) => Theme.of(context).colorScheme.onSurface;
  static Color textSubtle(BuildContext context) => Theme.of(context).colorScheme.onSurfaceVariant;
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;
}
