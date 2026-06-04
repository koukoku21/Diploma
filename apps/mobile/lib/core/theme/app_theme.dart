import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_spacing.dart';

// ─── Светлые константы ────────────────────────────────────────────
const Color kLightBgPrimary     = Color(0xFFFAF9F7);
const Color kLightBgSecondary   = Color(0xFFF2F0EC);
const Color kLightBgTertiary    = Color(0xFFEBE8E2);
const Color kLightTextPrimary   = Color(0xFF1A1714);
const Color kLightTextSecondary = Color(0xFF6B6560);
const Color kLightTextTertiary  = Color(0xFFABA69F);
const Color kLightBorder        = Color(0x18000000);
const Color kLightBorder2       = Color(0x28000000);

// ─── AppColorScheme — ThemeExtension ─────────────────────────────

@immutable
class AppColorScheme extends ThemeExtension<AppColorScheme> {
  const AppColorScheme({
    required this.bgPrimary,
    required this.bgSecondary,
    required this.bgTertiary,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.border,
    required this.border2,
  });

  final Color bgPrimary;
  final Color bgSecondary;
  final Color bgTertiary;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color border;
  final Color border2;

  static const _dark = AppColorScheme(
    bgPrimary:     kBgPrimary,
    bgSecondary:   kBgSecondary,
    bgTertiary:    kBgTertiary,
    textPrimary:   kTextPrimary,
    textSecondary: kTextSecondary,
    textTertiary:  kTextTertiary,
    border:        kBorder,
    border2:       kBorder2,
  );

  static const _light = AppColorScheme(
    bgPrimary:     kLightBgPrimary,
    bgSecondary:   kLightBgSecondary,
    bgTertiary:    kLightBgTertiary,
    textPrimary:   kLightTextPrimary,
    textSecondary: kLightTextSecondary,
    textTertiary:  kLightTextTertiary,
    border:        kLightBorder,
    border2:       kLightBorder2,
  );

  static AppColorScheme of(BuildContext context) =>
      Theme.of(context).extension<AppColorScheme>()!;

  @override
  AppColorScheme copyWith({
    Color? bgPrimary, Color? bgSecondary, Color? bgTertiary,
    Color? textPrimary, Color? textSecondary, Color? textTertiary,
    Color? border, Color? border2,
  }) => AppColorScheme(
    bgPrimary:     bgPrimary     ?? this.bgPrimary,
    bgSecondary:   bgSecondary   ?? this.bgSecondary,
    bgTertiary:    bgTertiary    ?? this.bgTertiary,
    textPrimary:   textPrimary   ?? this.textPrimary,
    textSecondary: textSecondary ?? this.textSecondary,
    textTertiary:  textTertiary  ?? this.textTertiary,
    border:        border        ?? this.border,
    border2:       border2       ?? this.border2,
  );

  @override
  AppColorScheme lerp(AppColorScheme? other, double t) {
    if (other == null) return this;
    return AppColorScheme(
      bgPrimary:     Color.lerp(bgPrimary,     other.bgPrimary,     t)!,
      bgSecondary:   Color.lerp(bgSecondary,   other.bgSecondary,   t)!,
      bgTertiary:    Color.lerp(bgTertiary,    other.bgTertiary,    t)!,
      textPrimary:   Color.lerp(textPrimary,   other.textPrimary,   t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary:  Color.lerp(textTertiary,  other.textTertiary,  t)!,
      border:        Color.lerp(border,        other.border,        t)!,
      border2:       Color.lerp(border2,       other.border2,       t)!,
    );
  }
}

// ─── AppTheme ─────────────────────────────────────────────────────

class AppTheme {
  AppTheme._();

  static ThemeData get dark  => _build(isDark: true);
  static ThemeData get light => _build(isDark: false);

  static ThemeData _build({required bool isDark}) {
    final cs = isDark ? AppColorScheme._dark : AppColorScheme._light;

    return ThemeData(
      brightness: isDark ? Brightness.dark : Brightness.light,
      scaffoldBackgroundColor: cs.bgPrimary,
      primaryColor: kGold,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: kGold,
        onPrimary: cs.bgPrimary,
        secondary: kRose,
        onSecondary: Colors.white,
        surface: cs.bgSecondary,
        onSurface: cs.textPrimary,
        error: kError,
        onError: Colors.white,
      ),
      fontFamily: 'Mulish',
      extensions: [cs],

      textTheme: TextTheme(
        displayLarge:  TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 28, fontWeight: FontWeight.w700, height: 1.15, color: cs.textPrimary),
        headlineLarge: TextStyle(fontFamily: 'PlayfairDisplay', fontSize: 22, fontWeight: FontWeight.w700, color: cs.textPrimary),
        titleLarge:    TextStyle(fontFamily: 'Mulish', fontSize: 20, fontWeight: FontWeight.w600, color: cs.textPrimary),
        titleMedium:   TextStyle(fontFamily: 'Mulish', fontSize: 17, fontWeight: FontWeight.w500, color: cs.textPrimary),
        bodyLarge:     TextStyle(fontFamily: 'Mulish', fontSize: 16, fontWeight: FontWeight.w400, height: 1.5, color: cs.textPrimary),
        bodyMedium:    TextStyle(fontFamily: 'Mulish', fontSize: 14, fontWeight: FontWeight.w500, color: cs.textPrimary),
        bodySmall:     TextStyle(fontFamily: 'Mulish', fontSize: 12, fontWeight: FontWeight.w400, color: cs.textSecondary),
        labelSmall:    TextStyle(fontFamily: 'Mulish', fontSize: 10, fontWeight: FontWeight.w700, color: kGold, letterSpacing: 1.2),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: cs.bgPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(fontFamily: 'Mulish', fontSize: 20, fontWeight: FontWeight.w600, color: cs.textPrimary),
        iconTheme: IconThemeData(color: cs.textPrimary),
      ),

      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: cs.bgSecondary,
        selectedItemColor: kGold,
        unselectedItemColor: cs.textTertiary,
        selectedLabelStyle: const TextStyle(fontFamily: 'Mulish', fontSize: 10, fontWeight: FontWeight.w700),
        unselectedLabelStyle: const TextStyle(fontFamily: 'Mulish', fontSize: 10),
        elevation: 0,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: kGold,
          foregroundColor: cs.bgPrimary,
          minimumSize: const Size.fromHeight(52),
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontFamily: 'Mulish', fontWeight: FontWeight.w700, letterSpacing: 0.3),
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
        fillColor: cs.bgTertiary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: cs.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: BorderSide(color: cs.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: kGold),
        ),
        labelStyle: TextStyle(fontFamily: 'Mulish', fontSize: 12, color: cs.textSecondary, letterSpacing: 0.5),
        hintStyle: TextStyle(fontFamily: 'Mulish', fontSize: 12, color: cs.textTertiary),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      ),

      dividerTheme: DividerThemeData(color: cs.border, thickness: 1, space: 0),

      cardTheme: CardTheme(
        color: cs.bgSecondary,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: cs.border),
        ),
      ),
    );
  }
}
