import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme(Color? accent) {
    final primary = accent ?? AppColors.lightAccent;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: primary,
      scaffoldBackgroundColor: AppColors.lightBackground,
      colorScheme: ColorScheme.light(
        primary: primary,
        background: AppColors.lightBackground,
        surface: AppColors.lightSurface,
        onPrimary: AppColors.white,
        onBackground: AppColors.black,
        onSurface: AppColors.black,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.workSansTextTheme(ThemeData.light().textTheme).copyWith(
        titleLarge: GoogleFonts.workSans(fontWeight: FontWeight.bold, fontSize: 24),
        titleMedium: GoogleFonts.workSans(fontWeight: FontWeight.bold, fontSize: 18),
        bodyLarge: GoogleFonts.workSans(fontSize: 16),
        bodyMedium: GoogleFonts.workSans(fontSize: 14, color: AppColors.lightGrey),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.black),
        titleTextStyle: GoogleFonts.workSans(
          color: AppColors.black,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData darkTheme(Color? accent) {
    final primary = accent ?? AppColors.darkAccent;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: primary,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: primary,
        background: AppColors.darkBackground,
        surface: AppColors.darkSurface,
        onPrimary: AppColors.white,
        onBackground: AppColors.white,
        onSurface: AppColors.white,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.workSansTextTheme(ThemeData.dark().textTheme).copyWith(
        titleLarge: GoogleFonts.workSans(fontWeight: FontWeight.bold, fontSize: 24, color: AppColors.white),
        titleMedium: GoogleFonts.workSans(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.white),
        bodyLarge: GoogleFonts.workSans(fontSize: 16, color: AppColors.white),
        bodyMedium: GoogleFonts.workSans(fontSize: 14, color: AppColors.darkGrey),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.white),
        titleTextStyle: GoogleFonts.workSans(
          color: AppColors.white,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
