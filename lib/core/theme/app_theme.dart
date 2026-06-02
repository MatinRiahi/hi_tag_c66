import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryGold = Color(0xFFD4AF37);
  static const Color gradientGoldLight = Color(
    0xFFCFBD82,
  ); // طلایی روشن برای گرادینت
  static const Color gradientGoldDark = Color(
    0xFFB17540,
  ); // طلایی تیره برای گرادینت
  static const String fontName = 'Peyda';

  // --- تم تاریک ---
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF121212),
      fontFamily: fontName,
      colorScheme: const ColorScheme.dark(
        primary: primaryGold,
        secondary: primaryGold,
        surface: Color(0xFF1E1E1E),
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
          backgroundColor: primaryGold, // رنگ پس‌زمینه دکمه‌ها طلایی
          foregroundColor:
              Colors.black, // رنگ متن روی دکمه‌ها مشکی (برای خوانایی روی طلایی)
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
        style: TextButton.styleFrom(
          foregroundColor: primaryGold, // رنگ متن دکمه‌های متنی
        ),
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
