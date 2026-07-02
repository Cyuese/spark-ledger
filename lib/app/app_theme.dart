import 'package:flutter/material.dart';

const Color veriMint = Color(0xFF34DBCB);
const Color veriCyan = Color(0xFF34C2DB);
const Color veriBlue = Color(0xFF3498DB);
const Color veriRoyal = Color(0xFF346EDB);
const Color veriIndigo = Color(0xFF3445DB);
const Color veriInk = Color(0xFF151922);
const Color veriLine = Color(0xFFE4EAF0);
const double veriRadiusSm = 6;
const double veriRadiusMd = 10;
const double veriRadiusLg = 14;
const double veriPageMaxWidth = 440;

ThemeData buildVeriFinTheme(Brightness brightness) {
  final isDark = brightness == Brightness.dark;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: veriBlue,
    brightness: brightness,
    primary: veriBlue,
    secondary: veriRoyal,
    tertiary: veriIndigo,
  );

  final baseTheme = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: isDark
        ? const Color(0xFF101216)
        : const Color(0xFFF4F8FA),
    fontFamily: 'Roboto',
    visualDensity: VisualDensity.compact,
    dividerTheme: DividerThemeData(
      color: isDark ? Colors.white10 : veriLine,
      thickness: 0.8,
      space: 1,
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(36, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: veriBlue,
        foregroundColor: Colors.white,
        minimumSize: const Size(44, 44),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(veriRadiusMd),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        minimumSize: const Size(36, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: veriBlue,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(veriRadiusLg)),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: veriBlue,
      unselectedItemColor: isDark ? Colors.white54 : Colors.black45,
      backgroundColor: isDark ? const Color(0xFF0D0F12) : Colors.white,
      elevation: 0,
      selectedIconTheme: const IconThemeData(size: 25),
      unselectedIconTheme: const IconThemeData(size: 24),
      showUnselectedLabels: false,
      showSelectedLabels: false,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: isDark ? const Color(0xFF171A20) : Colors.white,
      selectedColor: veriBlue.withValues(alpha: 0.14),
      secondarySelectedColor: veriBlue.withValues(alpha: 0.14),
      labelStyle: TextStyle(
        color: isDark ? Colors.white.withValues(alpha: 0.86) : veriInk,
        fontSize: 12,
      ),
      secondaryLabelStyle: TextStyle(
        color: isDark ? Colors.white.withValues(alpha: 0.88) : veriInk,
        fontSize: 12,
      ),
      side: BorderSide(color: isDark ? Colors.white10 : veriLine),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(veriRadiusSm),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: isDark ? const Color(0xFF171A20) : Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(veriRadiusMd),
        borderSide: BorderSide.none,
      ),
    ),
  );

  return baseTheme.copyWith(
    textTheme: baseTheme.textTheme.copyWith(
      displayLarge: baseTheme.textTheme.displayLarge?.copyWith(
        fontSize: 38,
        height: 1.05,
        letterSpacing: 0,
      ),
      displayMedium: baseTheme.textTheme.displayMedium?.copyWith(
        fontSize: 32,
        height: 1.08,
        letterSpacing: 0,
      ),
      displaySmall: baseTheme.textTheme.displaySmall?.copyWith(
        fontSize: 26,
        height: 1.12,
        letterSpacing: 0,
      ),
      headlineMedium: baseTheme.textTheme.headlineMedium?.copyWith(
        fontSize: 21,
        height: 1.18,
        letterSpacing: 0,
      ),
      headlineSmall: baseTheme.textTheme.headlineSmall?.copyWith(
        fontSize: 19,
        height: 1.2,
        letterSpacing: 0,
      ),
      titleLarge: baseTheme.textTheme.titleLarge?.copyWith(
        fontSize: 17,
        height: 1.25,
        letterSpacing: 0,
      ),
      titleMedium: baseTheme.textTheme.titleMedium?.copyWith(
        fontSize: 14,
        height: 1.25,
        letterSpacing: 0,
      ),
      titleSmall: baseTheme.textTheme.titleSmall?.copyWith(
        fontSize: 13,
        height: 1.25,
        letterSpacing: 0,
      ),
      bodyLarge: baseTheme.textTheme.bodyLarge?.copyWith(
        fontSize: 14,
        height: 1.35,
        letterSpacing: 0,
      ),
      bodyMedium: baseTheme.textTheme.bodyMedium?.copyWith(
        fontSize: 13,
        height: 1.35,
        letterSpacing: 0,
      ),
      bodySmall: baseTheme.textTheme.bodySmall?.copyWith(
        fontSize: 12,
        height: 1.35,
        letterSpacing: 0,
      ),
      labelLarge: baseTheme.textTheme.labelLarge?.copyWith(
        fontSize: 12,
        height: 1.25,
        letterSpacing: 0,
      ),
      labelMedium: baseTheme.textTheme.labelMedium?.copyWith(
        fontSize: 11,
        height: 1.25,
        letterSpacing: 0,
      ),
      labelSmall: baseTheme.textTheme.labelSmall?.copyWith(
        fontSize: 10,
        height: 1.2,
        letterSpacing: 0,
      ),
    ),
  );
}
