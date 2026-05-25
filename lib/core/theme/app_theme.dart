import 'package:flutter/material.dart';

/// Tema visual de PROGANA Fantasy
class AppColors {
  // Brand
  static const Color verdeMexicano = Color(0xFF006847);
  static const Color verdeOscuro = Color(0xFF004D35);
  static const Color dorado = Color(0xFFFFD700);
  static const Color rojoBandera = Color(0xFFCE1126);

  // Neutrales
  static const Color blanco = Color(0xFFFFFFFF);
  static const Color grisClaro = Color(0xFFF5F5F5);
  static const Color grisMedio = Color(0xFF9E9E9E);
  static const Color grisOscuro = Color(0xFF424242);
  static const Color negro = Color(0xFF000000);

  // Estados
  static const Color exito = Color(0xFF4CAF50);
  static const Color error = Color(0xFFD32F2F);
  static const Color advertencia = Color(0xFFFFA000);
  static const Color info = Color(0xFF2196F3);
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.verdeMexicano,
        brightness: Brightness.light,
        primary: AppColors.verdeMexicano,
        secondary: AppColors.dorado,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.grisClaro,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.verdeMexicano,
        foregroundColor: AppColors.blanco,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.verdeMexicano,
          foregroundColor: AppColors.blanco,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.blanco,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.grisMedio),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.verdeMexicano, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}