import 'package:flutter/material.dart';

class TxColors {
  static const bg = Color(0xFF07101F);
  static const surface = Color(0xFF101A2B);
  static const card = surface;
  static const surface2 = Color(0xFF162238);
  static const red = Color(0xFFFF3131);
  static const green = Color(0xFF19D37E);
  static const blue = Color(0xFF1769FF);
  static const purple = Color(0xFF7B2CFF);
  static const gold = Color(0xFFFFC62A);
  static const muted = Color(0xFF93A3BC);
}

ThemeData buildTeoriXTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: TxColors.red,
    brightness: Brightness.dark,
    surface: TxColors.surface,
  );
  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme.copyWith(
      primary: TxColors.red,
      secondary: TxColors.blue,
      surface: TxColors.surface,
    ),
    scaffoldBackgroundColor: TxColors.bg,
    appBarTheme: const AppBarTheme(
      backgroundColor: TxColors.bg,
      foregroundColor: Colors.white,
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardThemeData(
      color: TxColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: const Color(0xFF0A1424),
      indicatorColor: TxColors.red.withValues(alpha: .16),
      labelTextStyle: WidgetStateProperty.resolveWith((states) => TextStyle(
        color: states.contains(WidgetState.selected) ? Colors.white : TxColors.muted,
        fontSize: 11,
        fontWeight: states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
      )),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: TxColors.red,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    textTheme: const TextTheme(
      headlineMedium: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -.6),
      titleLarge: TextStyle(fontWeight: FontWeight.w800),
      titleMedium: TextStyle(fontWeight: FontWeight.w800),
      bodyMedium: TextStyle(height: 1.35),
    ),
  );
}
