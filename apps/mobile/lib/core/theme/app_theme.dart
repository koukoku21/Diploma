import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_spacing.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBgPrimary,
        primaryColor: kGold,
        colorScheme: const ColorScheme.dark(
          primary: kGold,
          secondary: kRose,
          surface: kBgSecondary,
          error: kError,
        ),
        fontFamily: 'Mulish',

        // AppBar
        appBarTheme: const AppBarTheme(
          backgroundColor: kBgPrimary,
          elevation: 0,
          centerTitle: true,
          titleTextStyle: AppTextStyles.title,
          iconTheme: IconThemeData(color: kTextPrimary),
        ),

        // Bottom Navigation
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: kBgSecondary,
          selectedItemColor: kGold,
          unselectedItemColor: kTextTertiary,
          selectedLabelStyle: TextStyle(
            fontFamily: 'Mulish',
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: TextStyle(
            fontFamily: 'Mulish',
            fontSize: 10,
          ),
          elevation: 0,
        ),

        // Elevated Button (Primary / CTA)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: kGold,
            foregroundColor: kBgPrimary,
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
            textStyle: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),

        // Outlined Button (Secondary)
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: kGold,
            side: const BorderSide(color: kGold),
            minimumSize: const Size.fromHeight(52),
            shape: const StadiumBorder(),
          ),
        ),

        // Input
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kBgTertiary,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: kBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: kBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppRadius.sm),
            borderSide: const BorderSide(color: kGold),
          ),
          labelStyle: AppTextStyles.caption.copyWith(
            color: kTextSecondary,
            letterSpacing: 0.5,
          ),
          hintStyle: AppTextStyles.caption.copyWith(color: kTextTertiary),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: kBorder,
          thickness: 1,
          space: 0,
        ),
      );
}
