import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Bộ màu nhận diện thương hiệu T&T POS (Vàng Gold & Đen Slate)
  static const Color brandGold = Color(0xFFD97706); // Amber-600: Vàng sang trọng, tương phản cao, dễ nhìn
  static const Color brandGoldLight = Color(0xFFF59E0B); // Amber-500: Vàng tươi sáng như logo
  static const Color brandGoldSoft = Color(0xFFFFFBEB); // Amber-50: Vàng kem nhạt êm mắt
  static const Color brandGoldBorder = Color(0xFFFDE68A); // Amber-200: Viền vàng nhẹ
  
  static const Color brandDark = Color(0xFF0F172A); // Slate-900: Đen sang trọng như nền logo
  static const Color brandDarkSurface = Color(0xFF1E293B); // Slate-800
  
  // Ánh xạ tương thích với toàn bộ mã nguồn
  static const Color primaryBlue = brandGold;
  static const Color primaryBlueDark = Color(0xFFB45309); // Amber-700
  
  static const Color background = Color(0xFFF8FAFC); // Nền xám sáng sạch sẽ, tinh tế
  static const Color surface = Colors.white;
  static const Color textDark = Color(0xFF0F172A); // Chữ đen đậm dễ đọc
  static const Color textPrimary = textDark;
  static const Color textMuted = Color(0xFF64748B); // Chữ phụ ghi xám
  
  static const Color successGreen = Color(0xFF10B981); // Xanh lá thành công
  static const Color warningOrange = Color(0xFFF59E0B); // Cam cảnh báo
  static const Color dangerRed = Color(0xFFEF4444); // Đỏ cảnh báo/nợ
  static const Color borderSubtle = Color(0xFFE2E8F0); // Viền xám nhẹ

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandGold,
        primary: brandGold,
        secondary: brandDark,
        surface: surface,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme(),
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: brandDark),
        titleTextStyle: TextStyle(
          color: brandDark,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderSubtle, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandGold,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: brandGold,
          side: const BorderSide(color: brandGold, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          textStyle: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
