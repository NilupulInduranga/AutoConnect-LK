import 'package:flutter/material.dart';
import 'responsive_utils.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF8D153A); // Sri Lankan Maroon
  static const Color accentColor = Color(0xFFF7941E); // Sri Lankan Orange
  static const Color secondaryColor = Color(0xFF006F41); // Sri Lankan Green
  static const Color scaffoldBackgroundColor = Color(0xFFF8F9FA); // Slightly warmer white
  static double get borderRadius => 16.0.r;

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: accentColor,
        surface: Colors.white,
        error: accentColor,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        iconTheme: IconThemeData(size: 24.r),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, 50.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          elevation: 2,
          textStyle: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          minimumSize: Size(double.infinity, 50.h),
          side: const BorderSide(color: primaryColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
          textStyle: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        elevation: 2,
        color: Colors.white,
        margin: EdgeInsets.only(bottom: 16.h),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: Colors.grey.shade200),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: primaryColor, width: 2.w),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        labelStyle: TextStyle(fontSize: 14.sp, color: Colors.grey[700]),
        hintStyle: TextStyle(fontSize: 14.sp, color: Colors.grey[400]),
        prefixIconColor: primaryColor,
        suffixIconColor: primaryColor,
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontSize: 32.sp, fontWeight: FontWeight.bold, color: Colors.black),
        headlineMedium: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold, color: Colors.black),
        headlineSmall: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.black),
        titleLarge: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold, color: Colors.black),
        titleMedium: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600, color: Colors.black),
        bodyLarge: TextStyle(fontSize: 16.sp, color: Colors.black87),
        bodyMedium: TextStyle(fontSize: 14.sp, color: Colors.black87),
        bodySmall: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
        labelLarge: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
      ),
    );
  }
}
