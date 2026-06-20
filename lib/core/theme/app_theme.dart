import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color gradientGoldLight = Color(0xFFCFBD82); // طلایی روشن
  static const Color gradientGoldDark = Color(0xFFB17540); // طلایی تیره

  // 🔥 رنگ‌های جدید سرمه‌ای برای تم تاریک
  static const Color navyBackgroundLight = Color(0xFF1C3761);
  static const Color navyBackgroundDark = Color(0xFF091A35);
  static const Color navyCardSurface = Color(
    0xFF284B82,
  ); // سرمه‌ای روشن‌تر برای کارت وسط

  static const String fontName = 'Peyda';

  // --- تم تاریک ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      // رنگ بک‌گراند پایه رو رو تیره‌ترین سرمه‌ای میذاریم
      scaffoldBackgroundColor: navyBackgroundDark,
      fontFamily: fontName,
      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        secondary: primaryGold,
        // رنگ المان‌های روی صفحه (مثل کارت وسط) رو این رنگ میذاریم
        surface: navyCardSurface,
        onSurface: Colors.white,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontFamily: fontName,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryGold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          textStyle: const TextStyle(
            fontFamily: fontName,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryGold),
      ),
    );
  }

  // --- تم روشن ---
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      fontFamily: fontName,

      colorScheme: const ColorScheme.light(
        primary: primaryGold,
        secondary: primaryGold,
        surface: Colors.white,
        onSurface: Colors.black87,
      ),

      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          fontFamily: fontName,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: primaryGold,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryGold,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          textStyle: const TextStyle(
            fontFamily: fontName,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: primaryGold),
      ),
    );
  }
}
