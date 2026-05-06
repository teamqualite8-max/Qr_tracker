// lib/theme.dart

import 'package:flutter/material.dart';

class AppTheme {
  // Status colors
  static const Color notProcessed = Color(0xFFE53E3E);   // Red
  static const Color post1Done = Color(0xFFD69E2E);      // Amber
  static const Color post2Done = Color(0xFF38A169);      // Green

  // Brand colors
  static const Color primary = Color(0xFF2B6CB0);
  static const Color primaryDark = Color(0xFF1A4E8A);
  static const Color surface = Color(0xFFF7FAFC);
  static const Color cardBg = Colors.white;

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: const Color(0xFFF0F4F8),
      appBarTheme: const AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
      cardTheme: CardTheme(
        color: cardBg,
        elevation: 2,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primary,
        unselectedItemColor: Color(0xFF718096),
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        unselectedLabelStyle: TextStyle(fontSize: 11),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(10)),
        ),
      ),
    );
  }

  static Color statusColor(dynamic status) {
    final s = status?.toString() ?? '';
    if (s.contains('POST2') || s.contains('post2Done')) return post2Done;
    if (s.contains('POST1') || s.contains('post1Done')) return post1Done;
    return notProcessed;
  }

  static Color statusColorFromEnum(dynamic statusEnum) {
    switch (statusEnum.toString()) {
      case 'PartStatus.post2Done':
        return post2Done;
      case 'PartStatus.post1Done':
        return post1Done;
      default:
        return notProcessed;
    }
  }
}
