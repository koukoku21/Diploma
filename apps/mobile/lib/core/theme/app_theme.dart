import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';

// Светлые цвета
const Color kLightBgPrimary    = Color(0xFFFAF9F7);
const Color kLightBgSecondary  = Color(0xFFF2F0EC);
const Color kLightBgTertiary   = Color(0xFFEBE8E2);
const Color kLightTextPrimary  = Color(0xFF1A1714);
const Color kLightTextSecondary= Color(0xFF6B6560);
const Color kLightTextTertiary = Color(0xFFABA69F);
const Color kLightBorder       = Color(0x18000000);
const Color kLightBorder2      = Color(0x28000000);

class AppTheme {
  AppTheme._();

  static ThemeData get dark => _build(
    brightness: Brightness.dark,
    bg: kBgPrimary,
    bgSurface: kBgSecondary,
    bgInput: kBgTertiary,
    textPrimary: kTextPrimary,
    textSecondary: kTextSecondary,
    textTertiary: kTextTertiary,
    border: kBorder,
  );

  static ThemeData get light => _build(
    brightness: Brightness.light,
    bg: kLightBgPrimary,
    bgSurface: kLightBgSecondary,
    bgInput: kLightBgTertiary,
    textPrimary: kLightTextPrimary,
    textSecondary: kLightTextSecondary,
    textTertiary: kLightTextTertiary,
    border: kLightBorder,
  );

  static ThemeData _build({
    required Brightness brightness,
    required Color bg,
    required Color bgSurface,
    required Color bgInput,
    required Color textPrimary,
    required Color textSecondary,
    required Color textTertiary,
    required Color border,
  }) {
    final isDark = brightness == Brightness.dark;
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      primaryColor: kGold,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: kGold,
        onPrimary: isDark ? kBgPrimary : kLightBgPrimary,
        secondary: kRose,
        onSecondary: Colors.white,
        surface: bgSurface,
        onSurface: textPrimary,
        error: kError,
        onError: Colors.white,
      ),
      fontFamily: 'Mulish',

      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: AppTextStyles.title.copyWith(color: textPrimary),
        iconTheme: IconThemeData(color: textPrimary),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: bgSurface,
        selectedItemColor: kGold,
        unselectedItemColor: textTertiary,
        selectedLabelStyle: const TextStyle(
          fontFamily: 'Mulish', fontSize: 10, fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Mulish', fontSize: 10),
        elevation: 0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kGold,
          foregroundColor: isDark ? kBgPrimary : kLightBgPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: AppTextStyles.label.copyWith(
            fontWeight: FontWeight.w700, letterSpacing: 0.3,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: kGold,
          side: const BorderSide(color: kGold),
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: bgInput,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: kGold),
        ),
        labelStyle: AppTextStyles.caption.copyWith(
          color: textSecondary, letterSpacing: 0.5,
        ),
        hintStyle: AppTextStyles.caption.copyWith(color: textTertiary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.md,
        ),
      ),

      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 0),

      cardTheme: CardTheme(
        color: bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: border),
        ),
      ),
    );
  }
}
