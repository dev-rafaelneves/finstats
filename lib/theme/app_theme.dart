import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppColors {
  // Light Mode (Apple HIG / Slate)
  static const Color lightBackground = Color(0xFFF2F2F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCardSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A); // slate-900
  static const Color lightTextSecondary = Color(0xFF64748B); // slate-500
  static const Color lightTextMuted = Color(0xFF94A3B8); // slate-400

  // Dark Mode (Slate Deep)
  static const Color darkBackground = Color(0xFF020617); // slate-950
  static const Color darkSurface = Color(0xFF0F172A); // slate-900
  static const Color darkCardSurface = Color(0xFF131D31);
  static const Color darkBorder = Color(0xFF1E293B); // slate-800
  static const Color darkTextPrimary = Color(0xFFF8FAFC); // slate-50
  static const Color darkTextSecondary = Color(0xFF94A3B8); // slate-400
  static const Color darkTextMuted = Color(0xFF64748B);

  // Financial Accents (Emerald / Rose / Indigo)
  static const Color emerald = Color(0xFF10B981); // Receitas / Saldos positivos
  static const Color emeraldDark = Color(0xFF059669);
  static const Color emeraldSoft = Color(0xFFECFDF5);
  static const Color emeraldSoftDark = Color(0xFF064E3B);

  static const Color rose = Color(0xFFF43F5E); // Despesas / Saídas
  static const Color roseDark = Color(0xFFE11D48);
  static const Color roseSoft = Color(0xFFFFF1F2);
  static const Color roseSoftDark = Color(0xFF4C0519);

  static const Color indigo = Color(0xFF6366F1); // Transferências / Planejamento
  static const Color amber = Color(0xFFF59E0B); // Alertas / Orçamento próximo do limite
  static const Color sky = Color(0xFF0EA5E9); // Contas bancárias
  static const Color purple = Color(0xFF8B5CF6); // Cartões de crédito
}

class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.lightBackground,
      primaryColor: AppColors.emeraldDark,
      colorScheme: const ColorScheme.light(
        primary: AppColors.emeraldDark,
        secondary: AppColors.emerald,
        surface: AppColors.lightSurface,
        onSurface: AppColors.lightTextPrimary,
        error: AppColors.rose,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBackground,
        foregroundColor: AppColors.lightTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.lightTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder, width: 0.8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFF1F5F9),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.emeraldDark, width: 1.5),
        ),
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: AppColors.emeraldDark,
        brightness: Brightness.light,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      primaryColor: AppColors.emerald,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.emerald,
        secondary: AppColors.emeraldDark,
        surface: AppColors.darkSurface,
        onSurface: AppColors.darkTextPrimary,
        error: AppColors.rose,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBackground,
        foregroundColor: AppColors.darkTextPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: AppColors.darkTextPrimary,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.3,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 0.8),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF1E293B),
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF0F172A),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.darkBorder, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.emerald, width: 1.5),
        ),
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: AppColors.emerald,
        brightness: Brightness.dark,
      ),
    );
  }
}
